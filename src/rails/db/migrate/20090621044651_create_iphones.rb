class CreateIphones < ActiveRecord::Migration
  def self.up
    create_table :iphones do |t|
      t.string :device_token
      t.timestamps
    end
  end

  def self.down
    drop_table :iphones
  end
end
