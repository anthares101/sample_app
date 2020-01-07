require 'test_helper'

class FollowingTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.new(name: "Example User", email: "user@example.com",
                     password: "foobar", password_confirmation: "foobar",
                     activated: true, activated_at: Time.zone.now)
    @user.save
    @other_user = User.new(name: "Example User 2", email: "user2@example.com",
                     password: "foobar", password_confirmation: "foobar",
                     activated: true, activated_at: Time.zone.now)
    @other_user.save

    @user.follow(@other_user)
    @other_user.follow(@user)

    log_in_as(@user, password: "foobar")
  end

  test "following page" do
    get following_user_path(@user)
    assert_not @user.following.empty?
    assert_match @user.following.count.to_s, response.body
    @user.following.each do |user|
      assert_select "a[href=?]", user_path(user)
    end
  end

  test "followers page" do
    get followers_user_path(@user)
    assert_not @user.followers.empty?
    assert_match @user.followers.count.to_s, response.body
    @user.followers.each do |user|
      assert_select "a[href=?]", user_path(user)
    end
  end

  test "should follow a user the standard way" do
    assert_difference '@user.following_count', 1 do
      post relationships_path, params: { followed_id: @other_user.id }
    end
  end

  test "should follow a user with Ajax" do
    assert_difference '@user.following_count', 1 do
      post relationships_path, xhr: true, params: { followed_id: @other_user.id }
    end
  end

  test "should unfollow a user the standard way" do
    @user.follow(@other_user)
    relationship = @user.active_relationships.find_by(followed_id: @other_user.id)
    assert_difference '@user.following_count', -1 do
      delete relationship_path(relationship)
    end
  end

  test "should unfollow a user with Ajax" do
    @user.follow(@other_user)
    relationship = @user.active_relationships.find_by(followed_id: @other_user.id)
    assert_difference '@user.following_count', -1 do
      delete relationship_path(relationship), xhr: true
    end
  end

  def teardown
    @user.destroy
    @other_user.destroy
  end
end
