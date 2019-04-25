module LoginMacros
  def login_admin(user=nil, type=:each)
    login(:admin, user, type)
  end

  def login_user(user=nil, type=:each)
    login(:user, user, type)
  end

  def login(user_type, user, type)
    before(type) do
      @user = user || FactoryBot.create(user_type)
      page.driver.post user_session_path,
        user: { email: @user.email, password: @user.password }
    end
  end
end
