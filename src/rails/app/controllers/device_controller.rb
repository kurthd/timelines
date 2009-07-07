class DeviceController < ApplicationController
  @@encryption_secret_file = File.join(RAILS_ROOT, 'config', 'garbage')

  protect_from_forgery :except => [ :register ]

  def register
    logger.debug "Registration request received."

    if request.post?
      logger.debug "Received post request: #{request}."
      logger.debug "device-token: '#{params[:devicetoken]}.'"

      token = params[:devicetoken]
      results = self.construct_params(params)

      usernames = results[0]
      keys = results[1]
      secrets = results[2]

      iphone = Iphone.find_or_create(token)
      self.register_accounts(iphone, usernames, keys, secrets)
    else
      @devices = Iphone.find(:all)
    end
  end

  @private

  def construct_params(params)
    usernames = Array.new
    keys = Array.new
    secrets = Array.new

    params.each do |name, value|
      if name =~ /^username(\d+)$/
        usernames[$1.to_i] = value
      elsif name =~ /^key(\d+)$/
        keys[$1.to_i] = value
      elsif name =~ /^secret(\d+)$/
        secrets[$1.to_i] = value
      end
    end

    if (usernames.length != keys.length || usernames.length != secrets.length)
      raise Exception.new("Received #{usernames.length} usernames, " +
        "#{keys.length} keys, and #{secrets.length} for device token: " +
        "#{token}. Usernames, keys, and secrets must match. Aborting " +
        "registration.")
    end

    [ usernames, keys, secrets ]
  end

  def delete_subscription(subscription)
    user = TwitterUser.find_by_id(subscription.twitter_user_id)
    if user != nil
      user.delete
    else
      logger.warn "Failed to find user with ID: #{subscription.twitter_user_id}"
        "for subscription: #{subscription} but one should exist."
      users = TwitterUser.find(:all)
      users.each { |user| logger.warn "user: #{user}" }
    end
    subscription.delete
  end

  def remove_stale_subscriptions(iphone, accounts)
    deleted_subscriptions = Array.new

    # remove any subscription not contained within the array
    old_subscriptions = DeviceSubscription.find(:all,
      :conditions => [ 'iphone_id = ?', iphone.id ])
    new_users = accounts.keys

    old_subscriptions.each do |subscription|
      user = TwitterUser.find(subscription.twitter_user_id)

      if (user != nil)
        if !new_users.include?(user.username)
          subscription.delete
          deleted_subscriptions << subscription
        end
      end
    end
  end

  def remove_stale_iphone(iphone)
    subscription =
      DeviceSubscription.find(:all,
        :conditions => [ 'iphone_id = ?', iphone.id ])

    if subscription == nil || subscription.length == 0
      # this iphone is no longer subscribed for any notifications
      iphone.delete
    end
  end

  def remove_stale_twitter_users(deleted_subscriptions)
    deleted_subscriptions.each do |subscription|
      user = TwitterUser.find(subscription.twitter_user_id)
      if (user != nil)
        subscriptions = DeviceSubscription.find_all_by_twitter_user_id(user.id)
        if (subscriptions != nil && subscriptions.length == 0)
          user.delete
        end
      end
    end
  end

  def register_account(iphone, username, key, secret)
    logger.info "Creating new account for user #{username} => #{iphone}."
    twitter_user =
      self.create_twitter_user(username, key, secret)
    subscription = self.create_subscription(twitter_user.id, iphone.id)

    begin
      # connects to twitter; save the user's last dm and mention
      suscriber_status =
        SubscriberStatus.initialize_from_twitter(twitter_user, subscription)
    rescue
      logger.warn "Failed to check current status for user: #{twitter_user}: " +
        "#{$!}"
      # just save zeros; it'll get filled in the next time the polling job runs
      SubscriberStatus.create(
        :last_direct_message => '0',
        :last_mention => '0',
        :device_subscription_id => subscription.id)
    end

    subscription
  end

  def create_twitter_user(username, key, secret)
    twitter_user = TwitterUser.new(:username => username,
                                   :key => key,
                                   :secret => secret)
    twitter_user.save!
    twitter_user
  end

  def create_subscription(twitter_user_id, iphone_id)
    subscription = DeviceSubscription.new(:twitter_user_id => twitter_user_id,
                                          :iphone_id => iphone_id)
    subscription.save!
    subscription
  end
end
