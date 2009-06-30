class Iphone < ActiveRecord::Base
  def to_s
    "#{self.id}: #{self.device_token}"
  end
end
