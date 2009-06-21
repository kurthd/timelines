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

    elsif request.get?
      logger.debug "Received get request."
    else
      logger.debug "I don't know what I received."
    end
  end

end
