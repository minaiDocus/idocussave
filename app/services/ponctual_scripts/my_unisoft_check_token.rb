class MyUnisoftCheckToken
  def self.execute
    new().execute
  end

  def execute
    client = MyUnisoft::Client.new

    member_group    = client.get_member_group_id
    member_group_id = member_group.first['member_group_id']

    p "Member Group ID : #{member_group_id}"

    user_token = client.get_user_token
    token      = user_token['access_token']

    p "User Token: #{token}"

    client2 = MyUnisoft::Client.new token

    granted    = client2.get_granted_for
    grantedFor = granted['grantedFor']

    p "GrantedFor: #{grantedFor}"

    get_token  = client2.generate_api_token
    api_token  = get_token['value']

    p "Api Token: #{api_token}"
  end
end