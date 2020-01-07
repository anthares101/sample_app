require 'test_helper'

class UsersProfileTest < ActionDispatch::IntegrationTest
  include ApplicationHelper

  def setup
    @user = User.new(name: "Example User", email: "user@example.com",
                     password: "foobar", password_confirmation: "foobar",
                     activated: true, activated_at: Time.zone.now)
    @user.save

    30.times do |n|
      @user.microposts.create(content: Faker::Lorem.sentence(5), created_at: 42.days.ago)
    end
  end

  test "profile display" do
    get user_path(@user)
    assert_template 'users/show'
    assert_select 'title', full_title(@user.name)
    assert_select 'h1', text: @user.name
    assert_select 'h1>img.gravatar'
    assert_match @user.microposts.count.to_s, response.body
    assert_select 'div.pagination', count: 1
    assert_select 'div.stats'
    @user.microposts.page(1).each do |micropost|
      assert_match micropost.content, response.body
    end
  end

  def teardown
    @user.destroy
  end
end
