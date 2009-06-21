class CreateDeviceSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :device_subscriptions do |t|
      t.integer :iphone_id
      t.integer :twitter_user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :device_subscriptions
  end
end
