class DeviceController < ApplicationController
  @@encryption_secret_file = File.join(RAILS_ROOT, 'config', 'garbage')

  protect_from_forgery :except => [ :register ]

  def register
    logger.debug "Registration request received."

    if request.post?
      logger.debug "Received post request: #{request}."
      logger.debug "device-token: '#{params[:devicetoken]}.'"

      token = params[:devicetoken]

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
        logger.error "Received #{usernames.length} usernames, " +
          "#{keys.length} keys, and #{secrets.length} for device token: " +
          "#{token}. Usernames, keys, and secrets must match. Aborting " +
          "registration."
      else
        iphone = self.find_or_create_iphone(token)

        self.register_accounts(iphone, usernames, keys, secrets)

        # clean up
        #deleted_subscriptions =
          #self.remove_stale_subscriptions(iphone, accounts)
        #self.remove_stale_iphone(iphone)
        #self.remove_stale_twitter_users(deleted_subscriptions)
      end
    else
      @devices = Iphone.find(:all)
    end
  end

  @private

  def register_accounts(iphone, usernames, keys, secrets)
    subscriptions = DeviceSubscription.find(:all,
      :conditions => [ 'iphone_id = ?', iphone.id ])
    logger.info "#{iphone}: Found #{subscriptions.length} existing " +
      "subscriptions."

    subscriptions_to_delete = Array.new

    subscriptions.each do |subscription|
      logger.debug "Looking for twitter user: #{subscription.twitter_user_id}"

      user = TwitterUser.find(:first,
        :conditions => [ 'id = ?', subscription.twitter_user_id ])
      index = user ? usernames.index(user.username) : nil
      if index != nil
        # update this user with potentially new keys and secrets
        user.key = keys[index]
        user.secret = secrets[index]
        user.save!

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
    logger.info "Deleting #{subscriptions_to_delete.length} stale subscriptions"
    subscriptions_to_delete.each { |s| self.delete_subscription(s) }

    # need to create new subscriptions for the remaining users
    logger.info "Adding #{usernames.length} new subscriptions"
    for i in (0..usernames.length - 1)
      self.register_account(iphone, usernames[i], keys[i], secrets[i])
    end

    subscriptions = DeviceSubscription.find_all_by_iphone_id(iphone.id)
    if (subscriptions.length == 0)
      iphone.delete  # the user does not have any accounts
    end
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
  end

  def find_or_create_iphone(token)
    iphone = Iphone.find(:first, :conditions => [ 'device_token = ?', token ])
    if iphone == nil
      iphone = Iphone.new(:device_token => token)
      result = iphone.save!
    end

    iphone
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

  #def private_key_passwd
    #f = File.new(@@encryption_secret_file)
    #pass = f.read.chomp
    #f.close
    #pass
  #end
end
