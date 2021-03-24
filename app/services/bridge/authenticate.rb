class Bridge::Authenticate
  def initialize(user)
    @user = user
  end

  def execute
    begin
      BridgeBankin::Authorization.generate_token(email: @user.bridge_account.username, password: @user.bridge_account.password).access_token if @user.bridge_account
    rescue => e
      return nil
    end
  end
end