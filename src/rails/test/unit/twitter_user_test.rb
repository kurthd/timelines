require 'test_helper'

class TwitterUserTest < ActiveSupport::TestCase
  @@encryption_secret_file = File.join(RAILS_ROOT, 'config', 'garbage')

  test "encrypt" do
    key = '11922782-udWaHkhuuRFM6rYirUdxuWjYoD3WByXGAfmxSbCNp'
    secret = '49Q8RqH0POwSUSp4KuFwhSM6LuBuaRQEzIuZvGunQos'
    user = TwitterUser.new(:username => 'debay',
                           :key => key,
                           :secret => secret)
    user.save

    assert_not_nil user.encrypted_key
    assert_not_equal key, user.encrypted_key
    assert_not_nil user.encrypted_secret
    assert_not_equal secret, user.encrypted_secret
    assert_not_equal user.encrypted_key, user.encrypted_secret
  end

  test "decrypt" do
    key = '11922782-udWaHkhuuRFM6rYirUdxuWjYoD3WByXGAfmxSbCNp'
    secret = '49Q8RqH0POwSUSp4KuFwhSM6LuBuaRQEzIuZvGunQos'
    user = TwitterUser.new(:username => 'debay',
                           :key => key,
                           :secret => secret)
    user.save  # save forces encryption
    user.key = nil
    user.secret = nil

    user.decrypt_sensitive(self.private_key_passwd)  # decrypt the data

    assert_equal key, user.key
    assert_equal secret, user.secret
  end

  # should be moved into a helper method
  def private_key_passwd
    f = File.new(@@encryption_secret_file)
    pass = f.read.chomp
    f.close
    pass
  end
end
