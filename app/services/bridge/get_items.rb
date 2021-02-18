class Bridge::GetItems
  def initialize(user)
    @user = user
  end

  def execute
    if @user.bridge_account
      access_token = Bridge::Authenticate.new(@user).execute

      items = BridgeBankin::Item.list(access_token: access_token)

      items.each do |item|
        retriever = Retriever.find_or_initialize_by(bridge_id: item.id, user: @user)

        state = item.status <= 0 ? 'ready' : 'error'

        bank_name = Bridge::GetBank.execute(item.bank.id).name

        retriever.update(name: bank_name,
                         state: state,
                         service_name: bank_name,
                         capabilities: ['bank'],
                         error_message: item.status_code_description,
                         bridge_status: item.status,
                         bridge_status_code_info: item.status_code_info,
                         bridge_status_code_description: item.status_code_description)
      end
    end
  end
end