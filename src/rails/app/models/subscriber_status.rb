class SubscriberStatus < ActiveRecord::Base
  def self.initialize_from_twitter(user, subscription)
    client = Grackle::Client.new
    client.ssl = true
    client.authorize_user(user)

    last_dm = client.last_dm
    if (last_dm == nil)
      last_dm = '0'
    else
      last_dm = last_dm.id
    end

    last_mention = user.last_mention
    if (last_mention == nil)
      last_mention = '0'
    else
      last_mention = last_mention.id
    end

    SubscriberStatus.create(
      :last_direct_message => last_direct_message,
      :last_mention => last_mention,
      :device_subscription_id => subscription.id)
  end
end
