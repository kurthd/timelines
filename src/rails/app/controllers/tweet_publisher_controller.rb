require 'grackle'

class TweetPublisherController < ApplicationController
  def check
    unauth_client = Grackle::Client.new

    @quota_before_check =
      unauth_client.account.rate_limit_status.json?.remaining_hits

    logger.info "Remaining unauthenticated requests before check: " +
     "#{@quota_before_check}."

    notifications = Array.new
    @usernames = Hash.new
    @user_before_quotas = Hash.new
    @user_after_quotas = Hash.new

    subscriptions = DeviceSubscription.find(:all)

    subscriptions.each do |subscription|
      begin
        iphone =
          Iphone.find(:first,
                      :conditions => [ 'id = ?', subscription.iphone_id ])
        if iphone == nil
          logger.warn "No iPhone maps to subscription: #{subscription.id}."
          next
        end

        twitter_user =
          TwitterUser.find(:first,
                           :conditions =>
        [ 'id = ?', subscription.twitter_user_id ])

        if twitter_user == nil
          logger.warn "No Twitter user maps to subscription: #{subscription.id}"
          next
        end
        logger.debug "Checking for new tweets for #{twitter_user}."

        @client =
          Grackle::Client.new(:auth => { :type =>:basic,
                              :username => twitter_user.username,
                              :password => twitter_user.password })
        @client.ssl = true

        @user_before_quotas[twitter_user.username] =
          @client.account.rate_limit_status.json?.remaining_hits
        logger.info "#{twitter_user} has " +
          "#{@user_before_quotas[twitter_user.username]} " +
          "remaining API calls before checking."

        status =
          SubscriberStatus.find(
            :first, :conditions =>
        [ 'device_subscription_id = ?', subscription.id ])

        # TODO: Move this code into the device registration controller
        if (status == nil)  # this is the first time we've notified this person
          # don't send anything; just make note
          direct_messages = self.all_direct_messages
          mentions = self.all_mentions

          if (direct_messages.length == 0)
            last_direct_message = '0'
          else
            last_direct_message = direct_messages[0].id
          end

          if (mentions.length == 0)
            last_mention = '0'
          else
            last_mention = mentions[0].id
          end

          status = SubscriberStatus.new(
            :last_direct_message => last_direct_message,
            :last_mention => last_mention,
            :device_subscription_id => subscription.id)
          status.save!

          next
        end

        # fetch direct messages and mentions since last time
        direct_messages =
          self.direct_messages_since(status.last_direct_message)
        mentions = self.mentions_since(status.last_mention)

        logger.info "#{twitter_user}: #{direct_messages.length} direct " +
          "messages since #{status.last_direct_message}."
        logger.info "#{twitter_user}: #{mentions.length} mentions since " +
          "#{status.last_mention}."

        @user_after_quotas[twitter_user.username] =
          @client.account.rate_limit_status.json?.remaining_hits
        logger.info "#{twitter_user} has " +
          "#{@user_after_quotas[twitter_user.username]} " +
          "remaining API calls after checking."

        if (direct_messages.length + mentions.length > 0)
          logger.info "Notifying phone #{iphone.device_token} of " +
            "#{direct_messages.length} direct messages and " +
            "#{mentions.length} mentions."

          # update status and save to the database
          if (direct_messages.length > 0)
            status.last_direct_message = direct_messages[0].id
          end

          if (mentions.length > 0)
            status.last_mention = mentions[0].id
          end

          notification = self.push_notification_for(
            iphone.device_token, direct_messages, mentions)

            logger.info "Adding one notification for user: #{twitter_user}: " +
            "\"#{notification.alert}\"."

            notifications << notification
            @usernames[twitter_user.username] = notification

            # don't save new status until everything's done
            status.save
        else
          logger.info "#{twitter_user}: no new tweets."
        end
      rescue
        logger.error "Failed to process subscription: #{subscription}. #{$!}."
      end
    end

    @quota_after_check =
      unauth_client.account.rate_limit_status.json?.remaining_hits

    logger.info "Remaining unauthenticated requests after check: " +
      "#{@quota_before_check}."

    logger.info "Sending #{notifications.length} push notifications."
    if (notifications.length > 0)
      begin
        ApplePushNotification.send_notifications(notifications)
      rescue
        logger.error "Failed to send #{notifications.length} notifications: " +
          "#{$!}."
      end
    end
  end

  @private

  def direct_messages_since(id)
    @client.direct_messages.json? :since_id => id
  end

  def mentions_since(id)
    @client.statuses.mentions.json? :since_id => id
  end

  def all_direct_messages
    @client.direct_messages.json?
  end

  def all_mentions
    @client.statuses.mentions.json?
  end

  def push_notification_for(device_token, dms, mentions)
    if (dms.length + mentions.length == 1)
      if (dms.length == 1)
        message = self.single_direct_message_message(dms[0])
      else
        message = self.single_mention_message(mentions[0])
      end
    else
      message = self.many_messages_message(dms, mentions)
    end

    notification = ApplePushNotification.new
    notification.device_token = device_token
    notification.badge = dms.length + mentions.length
    notification.sound = true
    notification.alert = message

    notification
  end

  def single_direct_message_message(dm)
    "#{dm.sender_screen_name}: #{dm.text}"
  end

  def single_mention_message(mention)
    "@#{mention.user.screen_name}: #{mention.text}"
  end

  def many_messages_message(dms, mentions)
    message = "You have "
    if (dms.length > 0)
      message += "#{dms.length} new direct " +
        "message#{dms.length == 1 ? '' : 's'}"
    end

    if (mentions.length > 0)
      if (dms.length > 0)
        message += " and "
      end

      message += "#{mentions.length} " +
        "new mention#{mentions.length == 1 ? '' : 's'}."
    else
      message += "."
    end
  end

end
