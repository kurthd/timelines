require 'test_helper'

class DeviceSubscriptionTest < ActiveSupport::TestCase
  fixtures :iphones, :device_subscriptions, :twitter_users

  def setup
    @usernames = [ 'foobar' ]
    @keys = [ '53266307-0S1nwHp2JsIF063KI2VFsTKEfdfZ3WAEgEdpa6LLe' ]
    @secrets = [ '7I1GNRP0dPZ1E2VvwaOnWYkUAjWQa6rxfFlop7F4Iy' ]
  end

  def teardown
  end

  test "new device" do
    iphone = iphones(:anns_iphone)

    subscriptions = DeviceSubscription.set_subscriptions_for_device(
      iphone, @usernames, @keys, @secrets)

    assert_equal @usernames.length, subscriptions.length

    subscription = subscriptions[0]
    assert_equal 'foobar', subscription.twitter_user.username
    assert_equal iphone.device_token, subscription.iphone.device_token
  end

  test "add account to existing device" do
    iphone = iphones(:johns_iphone)
    existing_subscriptions = DeviceSubscription.find_all_by_iphone_id(iphone.id)
    existing_subscriptions.each do |s|
      @usernames << s.twitter_user.username
      @keys << s.twitter_user.key
      @secrets << s.twitter_user.secret
    end

    subscriptions = DeviceSubscription.set_subscriptions_for_device(
      iphone, @usernames, @keys, @secrets)

    assert_equal @usernames.length, subscriptions.length
    @usernames.each do |username|
      user = TwitterUser.find_by_username(username)
      assert_not_nil user

      subscription = DeviceSubscription.find_by_twitter_user_id(user.id)
      assert_not_nil subscription
      assert_equal user.id, subscription.twitter_user.id
      assert_equal iphone.id, subscription.iphone.id
    end

    by_iphone = DeviceSubscription.find_all_by_iphone_id(iphone.id)
    assert_equal @usernames.length, by_iphone.length
  end

  test "replace all accounts for existing device" do
    iphone = iphones(:johns_iphone)

    subscriptions = DeviceSubscription.set_subscriptions_for_device(
      iphone, @usernames, @keys, @secrets)

    # 2 subscriptions are already defined in the test fixture
    assert_equal @usernames.length, subscriptions.length

    @usernames.each do |username|
      user = TwitterUser.find_by_username(username)
      assert_not_nil user

      subscription = DeviceSubscription.find_by_twitter_user_id(user.id)
      assert_not_nil subscription
      assert_equal user.id, subscription.twitter_user_id
      assert_equal iphone.id, subscription.iphone_id
    end

    by_iphone = DeviceSubscription.find_all_by_iphone_id(iphone.id)
    assert_equal @usernames.length, by_iphone.length
  end

  test "updating existing subscriptions" do
    iphone = iphones(:johns_iphone)
    debay = twitter_users(:debay)

    users = Array.new
    existing_subscriptions = DeviceSubscription.find_all_by_iphone_id(iphone.id)
    existing_subscriptions.each do |s|
      users << s.twitter_user
    end

    usernames = users.collect { |u| u.username }
    keys = users.collect { |u| u.key + "foobar" }
    secrets = users.collect { |u| u.secret + "baz" }

    DeviceSubscription.set_subscriptions_for_device(
      iphone, usernames, keys, secrets)
    new_subscriptions = DeviceSubscription.find_all_by_iphone_id(iphone.id)

    assert_equal existing_subscriptions.length, new_subscriptions.length

    new_subscriptions = DeviceSubscription.find_all_by_iphone_id(iphone.id)
    new_subscriptions.each do |ns|
      old_s = nil

      # I'm sure there's a better way to do this
      existing_subscriptions.each do |es|
        if es.id == ns.id
          old_s = es
          break
        end
      end

      assert_equal ns.twitter_user.username, old_s.twitter_user.username
      assert_equal ns.twitter_user.key, old_s.twitter_user.key + "foobar"
      assert_equal ns.twitter_user.secret, old_s.twitter_user.secret + "baz"
    end
  end

  test "deleting all subscriptions" do
    iphone = iphones(:johns_iphone)
    @usernames = Array.new
    @keys = Array.new
    @secrets = Array.new

    subscriptions = DeviceSubscription.set_subscriptions_for_device(
      iphone, @usernames, @keys, @secrets)

    assert_equal 0, subscriptions.length
    assert_equal 0, Iphone.find_all_by_id(iphone.id).length
  end
end
