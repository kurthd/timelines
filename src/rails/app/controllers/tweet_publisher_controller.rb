require 'grackle'

class TweetPublisherController < ApplicationController
  def check
    notifications = Array.new
    statuses = Array.new

    subscriptions = DeviceSubscription.find(:all)

    subscriptions.each do |subscription|
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
      logger.debug "Checking for new tweets for #{twitter_user.username}."

      @client =
        Grackle::Client.new(:auth => { :type =>:basic,
                                       :username => twitter_user.username,
                                       :password => twitter_user.password })
      @client.ssl = true

      status =
        SubscriberStatus.find(
          :first, :conditions =>
                  [ 'device_subscription_id = ?', subscription.id ])

      # TODO: Move this code into the device registration controller
      if (status == nil)  # this is the first time we've notified this person
                          # don't send anything; just make note
        direct_messages = self.all_direct_messages.reverse
        mentions = self.all_mentions.reverse

        if (direct_messages.length == 0)
          last_direct_message = '0'
        else
          last_direct_message = direct_messages[-1].id
        end

        if (mentions.length == 0)
          last_mention = '0'
        else
          last_mention = mentions[-1].id
        end

        status = SubscriberStatus.new(
          :last_direct_message => last_direct_message,
          :last_mention => last_mention,
          :device_subscription_id => subscription.id)
        status.save!

        next
      end

      logger.debug "Successfully created client."

      # fetch direct messages
      direct_messages =
        self.direct_messages_since(status.last_direct_message).reverse
      mentions = self.mentions_since(status.last_mention).reverse

      if (direct_messages.length + mentions.length > 0)
        logger.debug "Notifying phone #{iphone.device_token} of " +
          "#{direct_messages.length} direct messages and "
          "#{mentions.length} mentions."

        message = "You have received "
        if (direct_messages.length > 0)
          message += "#{direct_messages.length} direct " +
            "message#{direct_messages.length == 1 ? '' : 's'}"

          status.last_direct_message = direct_messages[-1].id
        end

        if (mentions.length > 0)
          if (direct_messages.length > 0)
            message += " and "
          end

          message += "#{mentions.length} " +
            "mention#{mentions.length == 1 ? '' : 's'}"

          status.last_mention = mentions[-1].id
        else
          message += "."
        end

        notification = ApplePushNotification.new
        notification.device_token = iphone.device_token
        notification.badge = direct_messages.length + mentions.length
        notification.sound = true
        notification.alert = message

        notifications << notification

        # save all the statuses, and write them to the db after we've
        # successfully sent the notifications
        statuses << status
      else
        logger.info "No new tweets for: #{twitter_user.username}."
      end
    end

    logger.info "Sending #{notifications.length} push notifications."

    ApplePushNotification.send_notifications(notifications)

    statuses.each { |status| status.save }
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
end
