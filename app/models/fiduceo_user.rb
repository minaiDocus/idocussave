# -*- encoding : UTF-8 -*-
class FiduceoUser
  attr_accessor :auto_update, :attributes, :response

  def initialize(user, auto_update=true)
    @user = user
    @auto_update = auto_update
    @attributes = {}
  end

  def create
    @response = client.create_user
    if client.response.code == 200
      @attributes = @response
      @client = nil
      @user.fiduceo_id = @attributes['id']
      @user.save if @auto_update
      client.user_preferences is_bank_pro_available: true, max_data_bancaire_retrievers: 10000
      @user.fiduceo_id
    else
      nil
    end
  end

  def destroy
    raise "no fiduceo user attached to user #{@user.code}" unless @user.fiduceo_id
    if client.user(:delete) == 200
      @attributes = {}
      @client = nil
      @user.fiduceo_id = nil
      @user.save if @auto_update
      true
    else
      false
    end
  end

private

  def client
    @client ||= Fiduceo::Client.new(@user.fiduceo_id)
  end
end
