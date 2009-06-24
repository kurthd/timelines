class DeviceController < ApplicationController
  protect_from_forgery :except => [ :register ]

  def register
    logger.debug "Registration request received."

    if request.post?
      logger.debug "Received post request: #{request}."
      logger.debug "device-token: '#{params[:devicetoken]}.'"

      token = params[:devicetoken]

      usernames = Array.new
      passwords = Array.new

      params.each do |name, value|
        if name =~ /^username(\d+)$/
          usernames[$1.to_i] = value
        elsif name =~ /^password(\d+)$/
          passwords[$1.to_i] = value
        end
      end

      if (usernames.length != passwords.length)
        logger.error "Received #{usernames.length} usernames and "
          "#{passwords.length} passwords for device token: #{token}. " +
          "Usernames and passwords must match. Aborting registration."
      else
        iphone = self.find_or_create_iphone(token)

        accounts = Hash.new
        for n in (0..usernames.length - 1)
          accounts[usernames[n]] = passwords[n]
        end

        self.register_accounts(iphone, accounts)

        # clean up
        deleted_subscriptions =
          self.remove_stale_subscriptions(iphone, accounts)
        self.remove_stale_iphone(iphone)
        self.remove_stale_twitter_users(deleted_subscriptions)
      end
    else
      @devices = Iphone.find(:all)
    end
  end

  def register_accounts(iphone, accounts)
    accounts.each do |username, password|
      self.register_account(iphone, username, password)
    end
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

  def register_account(iphone, username, password)
    twitter_user = self.find_or_create_twitter_user(username, password)
    subscription = self.find_or_create_subscription(twitter_user.id, iphone.id)
  end

  def find_or_create_subscription(twitter_user_id, iphone_id)
    subscription =
      DeviceSubscription.find(:first,
        :conditions => [ 'twitter_user_id = ? AND iphone_id = ?',
        twitter_user_id, iphone_id ])
    if subscription == nil
      subscription =
        DeviceSubscription.new(:twitter_user_id => twitter_user_id,
                               :iphone_id => iphone_id)
      subscription.save
    end

    subscription
  end

  def find_or_create_iphone(token)
    iphone = Iphone.find(:first, :conditions => [ 'device_token = ?', token ])
    if iphone == nil
      iphone = Iphone.new(:device_token => token)
      iphone.save
    end

    iphone
  end

  def find_or_create_twitter_user(username, password)
    twitter_user = TwitterUser.find_by_username(username)
    if (twitter_user == nil)
      twitter_user =
        TwitterUser.new(:username => username, :password => password)
      twitter_user.save
    end

    twitter_user
  end
end
