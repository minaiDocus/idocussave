# -*- encoding : UTF-8 -*-
module MyUnisoftLib
  class DataSender
    def initialize(user)
      @user = user
    end

    def execute(data)
      client = MyUnisoftLib::Api::Client.new(@user.my_unisoft.api_token)

      response = client.send_pre_assignment(data)

      if response["type"] == "O"
        { success: true, response: response }
      else
        { error: response['message'] }
      end
    end
  end
end