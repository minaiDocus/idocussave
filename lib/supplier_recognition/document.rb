module SupplierRecognition
  class Document
    include ActiveModel::Model

    attr_accessor :id, :name, :content, :created_at, :updated_at, :state, :third_party_id, :external_id, :training

    def self.get(id)
      verb = :get
      path = "/v1/documents/#{id}"

      json = SupplierRecognition::Base.connection.perform(path, verb)

      parse_and_instantiate_result(json)
    end

    def create
      verb = :post
      path = '/v1/documents'

      payload = { name: name, content: content, external_id: external_id, training: training }.to_json

      json = SupplierRecognition::Base.connection.perform(path, verb, nil, payload)

      parse_and_instantiate_result(json)
    end

    def parse_and_instantiate_result(json)
      data = JSON.parse(json.body)

      if data['data'].is_a?(Array)
        result = []

        data['data'].each do |d|
          result << SupplierRecognition::Document.new(d)
        end
      elsif data['data'].is_a?(Hash)
        result = SupplierRecognition::Document.new(data['data']['attributes'])
      else
        raise 'Unparsable result'
      end

      result
    end
  end
end