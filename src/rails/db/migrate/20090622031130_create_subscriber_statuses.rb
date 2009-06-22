class CreateSubscriberStatuses < ActiveRecord::Migration
  def self.up
    create_table :subscriber_statuses do |t|
      t.text    :last_direct_message
      t.text    :last_mention
      t.integer :device_subscription_id
      t.timestamps
    end
  end

  def self.down
    drop_table :subscriber_statuses
  end
end
