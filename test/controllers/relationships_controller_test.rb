require 'test_helper'

class RelationshipsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create(name: "Example User", email: "user@example.com",
                     password: "foobar", password_confirmation: "foobar",
                     activated: true, activated_at: Time.zone.now)

    @other_user = User.create(name: "Example User 2", email: "user2@example.com",
                     password: "foobar", password_confirmation: "foobar",
                     activated: true, activated_at: Time.zone.now)

    @relationship = Relationship.create(follower_id: @user.id, followed_id: @other_user.id)
  end

  test "create should require logged-in user" do
    assert_no_difference 'Relationship.count' do
      post relationships_path
    end
    assert_redirected_to login_url
  end

  test "destroy should require logged-in user" do
    assert_no_difference 'Relationship.count' do
      delete relationship_path(@relationship)
    end
    assert_redirected_to login_url
  end

  def teardown
		@user.destroy
		@other_user.destroy
  end
end
