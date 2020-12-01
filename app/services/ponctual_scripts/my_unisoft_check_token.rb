class MyUnisoftCheckToken
  def self.execute
    new().execute
  end

  def execute
    client = MyUnisoftLib::Api::Client.new

    member_group    = client.get_member_group_id
    member_group_id = member_group[:body][0]["member_group_id"]

    p "Member Group ID : #{member_group_id}"

    user_token = client.get_user_token
    token      = user_token[:body]['access_token']

    p "User Token: #{token}"

    client2 = MyUnisoftLib::Api::Client.new(token)

    granted    = client2.get_granted_for
    grantedFor = granted[:body]['grantedFor']

    p "GrantedFor: #{grantedFor}"

    get_token  = client2.generate_api_token
    api_token  = get_token[:body]['value']

    p "Api Token: #{api_token}"
  end
end