require 'test_helper'

class PunchesControllerTest < ActionController::TestCase
  include CurrentUser

  setup do
    @admin = users(:admin)
    @joe   = users(:joe)
    @sarah = users(:sarah)
    @punch = punches(:punch_one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:punches)
  end

  # This test should use timecop or something
  # test "should create punch" do
  #   with_current_user(@joe) do
  #     assert_difference('Punch.count') do
  #       post :create, punch: { comment: 'Wow' }
  #     end

  #     assert_redirected_to punch_path(assigns(:punch))
  #   end
  # end

  test "should update punches when admin" do
    with_current_user(@admin) do
      patch :update, id: @punch, punch: { comment: 'Wow' }
      assert_redirected_to punch_path(@punch)
    end
  end

  test "should not update punches when non-admin" do
    with_current_user(@joe) do
      patch :update, id: @punch, punch: { comment: 'Wow' }
      assert_redirected_to root_path
    end
  end

  test "should destroy punch when admin" do
    with_current_user(@admin) do
      assert_difference('Punch.count', -1) do
        delete :destroy, id: @punch
      end

      assert_redirected_to punches_path
    end
  end

  test "should not destroy punch when non-admin" do
    with_current_user(@joe) do
      assert_difference('Punch.count', 0) do
        delete :destroy, id: @punch
      end

      assert_redirected_to root_path
    end
  end
end
