require 'app_sender'

class RegisterDeviceController < ApplicationController
  protect_from_forgery :except => [:index]

  def index
    logger.debug "Request received."

    if request.post?
      logger.debug "Received post request: #{request}."
      logger.debug "device-token: '#{params[:devicetoken]}.'"

      ## notification.alert = 'Hello World!'
      ## notification.badge = 10
      ## notification.sound = 'purr.caf'
      ## notification.send_notification
      ##
      ## If you want to send multiple notifications in the same session use:
      ## Notification.send_notifications([notification1, notification2, notification3])
      ##
      ## Protected under Apple iPhone Developer NDA
      ##

      token = [params[:devicetoken]]
      notification = Notification.new(token)
      notification.alert = 'Sent from Rails, baby!'
      notification.send_notification

      logger.debug "Notification sent: #{notification}."

    elsif request.get?
      logger.debug "Received get request."
    else
      logger.debug "I don't know what I received."
    end
  end

end
