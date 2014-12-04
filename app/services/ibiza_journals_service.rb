# -*- encoding : UTF-8 -*-
class IbizaJournalsService
  attr_accessor :journals

  def initialize(user)
    @user = user
  end

  def execute
    if valid?
      client.request.clear
      client.company(@user.ibiza_id).journal?
      if success?
        @journals = client.response.data.map do |j|
          { name: j['ref'], description: j['description'] }
        end
      end
    end
  end

  def valid?
    @user.ibiza_id.present? && client
  end

  def success?
    valid? ? client.response.success? : nil
  end

private

  def client
    @client ||= @user.organization.try(:ibiza).try(:client)
  end
end
