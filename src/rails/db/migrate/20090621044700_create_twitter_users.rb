class CreateTwitterUsers < ActiveRecord::Migration
  def self.up
    create_table :twitter_users do |t|
      t.string :username
      t.text :encrypted_password
      t.text :encrypted_key
      t.text :encrypted_iv
      t.timestamps
    end
  end

  def self.down
    drop_table :twitter_users
  end
end
