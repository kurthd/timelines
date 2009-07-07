class Iphone < ActiveRecord::Base
  validates_presence_of :device_token
  validates_uniqueness_of :device_token
  has_many :device_subscriptions, :dependent => :destroy
  has_many :twitter_users, :through => :device_subscriptions

  def to_s
    "#{self.id}: #{self.device_token}"
  end

  def self.find_or_create(token)
    iphone = Iphone.find(:first, :conditions => [ 'device_token = ?', token ])
    if iphone == nil
      iphone = Iphone.new(:device_token => token)
      result = iphone.save!
    end

    iphone
  end
end
