require 'test_helper'

class DeviceControllerTest < ActionController::TestCase
  def setup
    @iphone = iphones(:johns_iphone)
    @usernames = Array.new
    @keys = Array.new
    @secrets = Array.new

    @usernames << twitter_users(:debay).username
    @usernames << twitter_users(:highorderbit).username
    @usernames << twitter_users(:kurthd).username

    @keys << twitter_users(:debay).key
    @keys << twitter_users(:highorderbit).key
    @keys << twitter_users(:kurthd).key

    @secrets << twitter_users(:debay).secret
    @secrets << twitter_users(:highorderbit).secret
    @secrets << twitter_users(:kurthd).secret
  end

  def teardown
  end

  # one iphone maps to a single account
  test "single account registration" do
    params = self.build_params(
      @iphone, @usernames[0, 1], @secrets[0, 1], @keys[0, 1])

    post(:register, params)
    assert_response :success
    assert_not_nil assigns(:subscriptions)
    assert_equal 1, assigns(:subscriptions).length
  end

  test "multiple account registration" do
    params = self.build_params(@iphone, @usernames, @secrets, @keys)

    post(:register, params)
    assert_response :success
    assert_not_nil assigns(:subscriptions)
    assert_equal @usernames.length, assigns(:subscriptions).length
  end

  test "no account registration" do
    params = self.build_params(@iphone, [], [], [])

    post(:register, params)
    assert_response :success
    assert_not_nil assigns(:subscriptions)
    assert_equal 0, assigns(:subscriptions).length
  end

  test "invalid registration" do
    params = self.build_params(@iphone, @usernames[0, 1], @keys[0, 1], [])

    post(:register, params)
    assert_response :success
    assert_nil assigns(:subscriptions)
  end

  test "get request" do
    get :register, self.build_params(@iphone, @usernames, @keys, @secrets)
    assert_nil assigns(:subscriptions)
    assert_response :success
  end

  @private

  def build_params(iphone, usernames, keys, secrets)
    params = Hash.new
    params['devicetoken'] = iphone.device_token

    usernames.each_index do |i|
      if i < usernames.length
        params["username#{i}"] = "#{usernames[i]}"
      end

      if i < keys.length
        params["key#{i}"] = "#{keys[i]}"
      end

      if i < secrets.length
        params["secret#{i}"] = "#{secrets[i]}"
      end
    end

    params
  end
end
