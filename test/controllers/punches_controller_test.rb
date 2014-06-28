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

  test "should create new punch if last punch was created more than 5 minutes ago" do
    Timecop.freeze(@punch.created_at + 10.minutes)
    with_current_user(@joe) do
      assert_difference('Punch.count', 1) do
        post :create, punch: { comment: 'Wow' }
      end

      assert_redirected_to root_path
      assert_equal 'Cartão batido com sucesso!', flash[:notice]
    end
    Timecop.return
  end

  test "should delete last punch if trying to create another one in less than 5 minutes from the last one" do
    Timecop.freeze(@punch.created_at + 2.minutes)
    with_current_user(@joe) do
      assert_difference('Punch.count', -1) do
        post :create, punch: { comment: 'Wow' }
      end

      assert_redirected_to root_path
      assert_equal 'Sua última batida foi removida!', flash[:notice]
    end
    Timecop.return
  end

  test "should update punches when admin" do
    with_current_user(@admin) do
      patch :update, id: @punch, punch: { comment: 'Wow' }
      assert_redirected_to root_path
      assert_equal 'Batida de ponto alterada.', flash[:notice]
    end
  end

  test "should not update punches when non-admin" do
    with_current_user(@joe) do
      patch :update, id: @punch, punch: { comment: 'Wow' }
      assert_redirected_to root_path
      assert_equal 'Não autorizado.', flash[:notice]
    end
  end

  test "should destroy punch when admin" do
    with_current_user(@admin) do
      assert_difference('Punch.count', -1) do
        delete :destroy, id: @punch
      end

      assert_redirected_to punches_path
      assert_equal 'Batida de ponto removida.', flash[:notice]
    end
  end

  test "should not destroy punch when non-admin" do
    with_current_user(@joe) do
      assert_difference('Punch.count', 0) do
        delete :destroy, id: @punch
      end

      assert_redirected_to root_path
      assert_equal 'Não autorizado.', flash[:notice]
    end
  end
end
