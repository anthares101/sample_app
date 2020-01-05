require 'test_helper'

class MicropostsInterfaceTest < ActionDispatch::IntegrationTest

  def setup
    @user = User.create(name: "Example User", email: "user@example.com",
                     password: "foobar", password_confirmation: "foobar",
                     activated: true, activated_at: Time.zone.now)
    30.times do
      @user.microposts.create(content: "Lorem ipsum", created_at: 10.minutes.ago)
    end

    @other_user = User.create(name: "Example User 2", email: "user2@example.com",
                     password: "foobar", password_confirmation: "foobar",
                     activated: true, activated_at: Time.zone.now)
  end

  test "micropost interface" do
    log_in_as(@user, password: "foobar")
    get root_path
    assert_select 'div.pagination'
    assert_select 'input[type="file"]'
    # Invalid submission
    assert_no_difference 'Micropost.count' do
      post microposts_path, params: { micropost: { content: "" } }
    end
    assert_select 'div#error_explanation'
    # Valid submission
    content = "This micropost really ties the room together"
    assert_difference 'Micropost.count', 1 do
      post microposts_path, params: { micropost: { content: content } }
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_match content, response.body
    # Delete post
    assert_select 'a', text: 'delete'
    first_micropost = @user.microposts.page(1).first
    assert_difference 'Micropost.count', -1 do
      delete micropost_path(first_micropost)
    end
    # Visit different user (no delete links)
    get user_path(@other_user)
    assert_select 'a', text: 'delete', count: 0
  end

  test "micropost sidebar count" do
    log_in_as(@user)
    get root_path
    assert_match "#{@user.microposts.count} microposts", response.body
    # User with zero microposts
    log_in_as(@other_user)
    get root_path
    assert_match "0 microposts", response.body
    @other_user.microposts.create!(content: "A micropost")
    get root_path
    assert_match "1 micropost", response.body
  end

  def teardown
    @user.destroy
    @other_user.destroy
  end
end
