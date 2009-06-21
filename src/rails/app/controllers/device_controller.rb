require 'app_sender'

class DeviceController < ApplicationController
  protect_from_forgery :except => [:index]

  def register
    logger.debug "Registration equest received."

    if request.post?
      logger.debug "Received post request: #{request}."
      logger.debug "device-token: '#{params[:devicetoken]}.'"

      token = [params[:devicetoken]]
      username = [params[:username]]
      password = [params[:password]]

      logger.info "Registering username: '#{username}' with device: '#{token}'."

      iphone = Iphone.find(:conditions => [ 'device_token = ?', token])
      if iphone == nil
        iphone = iPhone.new(:device_token => token)
        iphone.save
      end

      twitter_user =
        TwitterUser.new(:username => username, :password => password)
      twitter_user.save!

      subscription =
        DeviceSubscription.new(:twitter_user_id => twitter_user.id,
                               :iphone_id => iphone.id)
      subscription.save!
  end

end
