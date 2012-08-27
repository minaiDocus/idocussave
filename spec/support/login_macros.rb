module LoginMacros
  def login_admin(user=nil, type=:each)
    before(type) do
      @user = user || FactoryGirl.create(:admin)
      page.driver.post user_session_path,
                       :user => {:email => @user.email, :password => @user.password}
    end
  end

  def login_user(user=nil, type=:each)
    before(type) do
      @user = user || FactoryGirl.create(:user)
      page.driver.post user_session_path,
                       :user => {:email => @user.email, :password => @user.password}
    end
  end
end
