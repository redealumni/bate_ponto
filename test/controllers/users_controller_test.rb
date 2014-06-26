require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup do
    @joe   = users(:joe)
    @sarah = users(:sarah)
    @admin = users(:admin)
  end

  def with_current_user(current_user, &block)
    @controller.instance_variable_set('@current_user', current_user)
    yield
    @controller.instance_variable_set('@current_user', nil)
  end

  test "should get index when admin" do
    with_current_user(@admin) do
      get :index
      assert_response :success
      assert_not_nil assigns(:user_list)
    end
  end

  test "should not get index when non-admin" do
    with_current_user(@joe) do
      get :index
      assert_redirected_to root_path
    end
  end

  test "should get new when admin" do
    with_current_user(@admin) do
      get :new
      assert_response :success
    end
  end

  test "should not get new when non-admin" do
    with_current_user(@joe) do
      get :new
      assert_redirected_to root_path
    end
  end

  test "should create any user when admin" do
    with_current_user(@admin) do
      assert_difference('User.count') do
        post :create, user: { password: 'secret' }
      end

      assert_redirected_to user_path(assigns(:user))
    end
  end

  test "should not create any user when non-admin" do
    with_current_user(@joe) do
      assert_difference('User.count', 0) do
        post :create, user: { password: 'secret' }
      end
    end
  end

  test "should show any user when admin" do
    with_current_user(@joe) do
      get :show, id: @joe
      assert_redirected_to root_path
    end
  end

  test "should not show any user when non-admin" do
    with_current_user(@admin) do
      get :show, id: @sarah
      assert_response :success
    end
  end

  # this is weird behavior ...
  # any user can edit the anyone else's password ?
  test "should get edit" do
    with_current_user(@joe) do
      get :edit, id: @sarah
      assert_response :success
    end
  end

  test "should update user" do
    with_current_user(@admin) do
      patch :update, id: @sarah, user: { punches: @sarah.punches }
      assert_redirected_to user_path(assigns(:user))
    end
  end

  test "should destroy any user when admin" do
    with_current_user(@admin) do
      assert_difference('User.count', -1) do
        delete :destroy, id: @sarah
      end

      assert_redirected_to users_path
    end
  end

  test "should not destroy any user when non-admin" do
    with_current_user(@joe) do
      assert_difference('User.count', 0) do
        delete :destroy, id: @sarah
      end

      assert_redirected_to root_path
    end
  end
end
