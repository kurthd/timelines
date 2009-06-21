require 'grackle'

class TweetPublisherController < ApplicationController
  def check
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
        end

        logger.debug "Checking for new tweets for #{twitter_user.username}."

        @client =
          Grackle::Client.new(:auth => { :type =>:basic,
                                         :username => twitter_user.username,
                                         :password => twitter_user.password })

        logger.debug "Successfully created client."

        messages = @client.direct_messages.json?

        logger.debug "Notifying phone #{iphone.device_token} of #{messages.count} direct messages."

        notification = ApplePushNotification.new
        notification.device_token = iphone.device_token
        notification.badge = messages.count
        notification.sound = true
        notification.alert = "You have received #{messages.count} direct messages."
        notification.send_notification

        puts "Result: #{@result}"
      end
  end
end
