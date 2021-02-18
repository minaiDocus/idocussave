class Bridge::CreateUser
  def initialize(user)
    @user = user
  end

  def execute
    unless @user.bridge_account
      password = SecureRandom.hex

      if bridge_user = BridgeBankin::User.create(email: @user.email, password: password)
        BridgeAccount.create(user: @user, username: @user.email, password: password, identifier: bridge_user.uuid)
      else
        raise "unable to create user"
      end
    end
  end
end