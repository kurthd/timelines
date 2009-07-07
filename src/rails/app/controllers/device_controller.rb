class DeviceController < ApplicationController
  protect_from_forgery :except => [ :register ]

  def register
    if request.post?
      logger.info "Received post request."
      logger.debug "device-token: '#{params[:devicetoken]}.'"

      token = params[:devicetoken]
      results = self.construct_params(params)

      usernames = results[0]
      keys = results[1]
      secrets = results[2]

      if usernames.length != keys.length || usernames.length != secrets.length
        # raising an exception seems to break tests (??), so just
        # checking manually for now
        logger.error "Received #{usernames.length} usernames, " +
          "#{keys.length} keys, and #{secrets.length} secrets. Usernames, " +
          "keys, and secrets must match."
      else
        iphone = Iphone.find_or_create(token)
        @subscriptions = DeviceSubscription.set_subscriptions_for_device(
          iphone, usernames, keys, secrets)

        logger.info "iPhone #{iphone} has #{@subscriptions.length} " +
          "subscription(s) after registration:"
        @subscriptions.each do |s|
          logger.info "\t#{s.twitter_user}"
        end
      end
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

    [ usernames, keys, secrets ]
  end
end
