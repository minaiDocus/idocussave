module Jefacture
  class Document
    include ActiveModel::Model

    def self.get(id)
      verb = :get
      path = "/v1/preseizures/#{id}"

      json = Jefacture::Base.connection.perform(path, verb)

      JSON.parse(json.body)
    end
  end
end