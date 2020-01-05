require 'test_helper'

class MicropostTest < ActiveSupport::TestCase

  def setup
    @user = User.create(name: "Example User", email: "user@example.com",
                     password: "foobar", password_confirmation: "foobar",
                     activated: true, activated_at: Time.zone.now)
    # This code is not idiomatically correct.
    @micropost = @user.microposts.create(content: "Lorem ipsum")
    @micropost1 = @user.microposts.create(content: "Lorem ipsum 1", created_at: 10.minutes.ago)
    @micropost2 = @user.microposts.create(content: "Lorem ipsum 2", created_at: 2.years.ago)
    @micropost3 = @user.microposts.create(content: "Lorem ipsum 3", created_at: 5.years.ago)
  end

  test "should be valid" do
    assert @micropost.valid?
  end

  test "user id should be present" do
    @micropost.user_id = nil
    assert_not @micropost.valid?
  end

  test "content should be present" do
    @micropost.content = "   "
    assert_not @micropost.valid?
  end

  test "content should be at most 140 characters" do
    @micropost.content = "a" * 141
    assert_not @micropost.valid?
  end

  test "order should be most recent first" do
    assert_equal @micropost, Micropost.first
  end

  def teardown
    @user.destroy
  end
end
