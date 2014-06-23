require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  # setup do
  #   @user = users(:joe)
  # end

  def with_current_user(current_user:, &block)
    @controller.instance_variable_set('@current_user', current_user)
    yield
    @controller.instance_variable_set('@current_user', nil)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user when admin" do
    with_current_user(current_user: users(:admin)) do
      assert_difference('User.count') do
        post :create, user: { password: 'secret' }
      end

      assert_redirected_to user_path(assigns(:user))
    end
  end

  test "should not create user when not admin" do
    with_current_user(current_user: users(:joe)) do
      assert_difference('User.count', 0) do
        post :create, user: { password: 'secret' }
      end
    end
  end

  test "should show user" do
    get :show, id: @user
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @user
    assert_response :success
  end

  test "should update user" do
    patch :update, id: @user, user: { punches: @user.punches }
    assert_redirected_to user_path(assigns(:user))
  end

  test "should destroy user" do
    assert_difference('User.count', -1) do
      delete :destroy, id: @user
    end

    assert_redirected_to users_path
  end
end
