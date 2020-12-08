# -*- encoding : UTF-8 -*-
module IbizaLib
  class Journals
    attr_accessor :journals

    def initialize(user)
      @user = user
      @journals = []
    end


    def execute
      if valid?
        client.request.clear
        client.company(@user.ibiza.ibiza_id).journal?

        if success? && client.response.data.present?
          @journals = client.response.data.map do |j|
            {
              closed:      j['closed'],
              name:        j['ref'],
              description: j['description'],
              iban_code:   j['ibanCode'],
              number:      j['number'],
              type:        j['type']
            }
          end
        end
      end
    end


    def valid?
      @user.try(:ibiza).try(:ibiza_id?) && client
    end


    def success?
      valid? ? client.response.success? : nil
    end


    private

    def client
      @client ||= @user.organization.try(:ibiza).try(:client)
    end
  end
end
