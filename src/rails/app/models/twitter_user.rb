class TwitterUser < ActiveRecord::Base
  def to_s
    self.username
  end
end
