class TwitterUser < ActiveRecord::Base
  validates_presence_of :username, :secret, :key
  has_many :device_subscriptions, :dependent => :destroy
  has_many :iphones, :through => :device_subscriptions

  def to_s
    self.username
  end

  def update_key_and_secret(key, secret)
    self.key = key
    self.secret = secret
    self.save!
  end

  #def authorize_client(twitter)
    #twitter.auth =
      #{
        #:type => :oauth,
        #:consumer_key => consumer_token,
        #:consumer_secret => consumer_secret,
        #:username => twitter_user.username,
        #:token => twitter_user.key,
        #:token_secret => twitter_user.secret
      #}
  #end
#
  #def last_dm(twitter)
    #dms = twitter.direct_messages.json?
    #dms == nil || dms.length == 0 ? nil : dms[0]
  #end
#
  #def direct_messages_since(twitter, id)
    #twitter.direct_messages.json? :since_id => id
  #end
#
  #def last_mention(twitter)
    #mentions = twitter.mentions.json?
    #mentions == nil || mentions.length == 0 ? nil : mentions[0]
  #end
#
  #def mentions_since(twitter, id)
    #twitter.mentions.json? :since_id => id
  #end
end
