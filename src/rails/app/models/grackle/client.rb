module Grackle
  class Client
    def authorize_twitter_user(user)
      self.auth =
        {
          :type => :oauth,
          :consumer_key => user.consumer_token,
          :consumer_secret => user.consumer_secret,
          :username => user.username,
          :token => user.key,
          :token_secret => user.secret
        }
    end

    def last_dm
      dms = self.direct_messages.json?
      dms == nil || dms.length == 0 ? nil : dms[0]
    end

    def direct_messages_since(id)
      self.direct_messages.json? :since_id => id
    end

    def last_mention
      mentions = self.mentions.json?
      mentions == nil || mentions.length == 0 ? nil : mentions[0]
    end

    def mentions_since(id)
      self.mentions.json? :since_id => id
    end
  end
end
