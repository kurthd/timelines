class DeviceController < ApplicationController
  protect_from_forgery :except => [ :register ]

  def register
    logger.debug "Registration request received."

    if request.post?
      logger.debug "Received post request: #{request}."
      logger.debug "device-token: '#{params[:devicetoken]}.'"

      token = params[:devicetoken]
      username = params[:username]
      password = params[:password]

      logger.info "Registering username: '#{username}' with device: '#{token}'."

      iphone = Iphone.find(:first, :conditions => [ 'device_token = ?', token ])
      if iphone == nil
        iphone = Iphone.new(:device_token => token)
        logger.debug "Created a new device: #{iphone.id}."
      else
        iphone.updated_at = Time.now
        logger.debug "Pairing with an existing device: #{iphone.id}."
      end
      iphone.save!

      twitter_user =
        TwitterUser.new(:username => username, :password => password)
      twitter_user.save!

      subscription =
        DeviceSubscription.new(:twitter_user_id => twitter_user.id,
                               :iphone_id => iphone.id)
      subscription.save!

      logger.info "Subscribed twitter user #{twitter_user.id}: " +
        "#{twitter_user.username} to device notifications on device: " +
        "#{iphone.device_token}."
    else
      @devices = Iphone.find(:all)
    end
  end

end
