module CurrentUser
  def with_current_user(current_user, &block)
    @controller.instance_variable_set('@current_user', current_user)
    yield
    @controller.instance_variable_set('@current_user', nil)
  end
end
