class DeviceSubscription < ActiveRecord::Base
  validates_presence_of :iphone_id, :twitter_user_id
  belongs_to :iphone
  belongs_to :twitter_user

  def self.set_subscriptions_for_device(iphone, usernames, keys, secrets)
    existing_subscriptions = DeviceSubscription.find(
         :all,
         :conditions => [ 'iphone_id = ?', iphone.id ],
         :include => :twitter_user
      )
    logger.info "#{iphone}: Found #{existing_subscriptions.length} existing " +
      "subscriptions."

    # make copies of the input so we can mutate it
    usernames = Array.new(usernames)
    keys = Array.new(keys)
    secrets = Array.new(secrets)

    subscriptions_to_delete = Array.new
    existing_subscriptions.each do |subscription|
      logger.debug "Looking for Twitter user: #{subscription.twitter_user_id}"

      user = subscription.twitter_user
      index = user ? usernames.index(user.username) : nil
      if index != nil
        # update this user with potentially new keys and secrets
        user.key = keys[index]
        user.secret = secrets[index]
        user.save

        # done processing this account
        usernames.delete_at(index)
        keys.delete_at(index)
        secrets.delete_at(index)
      else
        # the user is deleting this subscription
        subscriptions_to_delete << subscription
      end
    end

    # need to delete the unused subscriptions
    logger.info "#{iphone}: Deleting #{subscriptions_to_delete.length} stale " +
      "subscriptions"
    subscriptions_to_delete.each { |s| s.delete }

    # need to create new subscriptions for the remaining users
    logger.info "Adding #{usernames.length} new subscriptions"
    for i in (0..usernames.length - 1)
      self.register_account(iphone, usernames[i], keys[i], secrets[i])
    end

    new_subscriptions = DeviceSubscription.find_all_by_iphone_id(iphone.id)
    if (new_subscriptions.length == 0)
      iphone.delete  # the user does not have any accounts
    end

    new_subscriptions
  end

  def self.register_account(iphone, username, key, secret)
    logger.info "Creating new account for user #{username} => #{iphone}."
    twitter_user = TwitterUser.create(:username => username,
                                      :key => key,
                                      :secret => secret)
    subscription = DeviceSubscription.create(:twitter_user => twitter_user,
                                             :iphone => iphone)

    if (RAILS_ENV == 'test')
      SubscriberStatus.create(
        :last_direct_message => '0',
        :last_mention => '0',
        :device_subscription_id => subscription.id)
    else
      begin
        # connects to twitter; save the user's last dm and mention
        suscriber_status =
          SubscriberStatus.initialize_from_twitter(twitter_user, subscription)
      rescue
        logger.warn "Failed to check current status for user: " +
          "#{twitter_user}: #{$!}"
        # just save zeros; it'll get filled in the next time by the polling job
        SubscriberStatus.create(
          :last_direct_message => '0',
          :last_mention => '0',
          :device_subscription_id => subscription.id)
      end
    end

    subscription
  end


  def self.subscribe_for_updates(iphone, twitter_user)
    DeviceSubscription.create(
        :iphone => iphone,
        :twitter_user => twitter_user
      )
  end
end
