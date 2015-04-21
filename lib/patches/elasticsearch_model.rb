raise 'This patch is for elasticsearch-model v0.1.7, update it.' unless Elasticsearch::Model::VERSION == '0.1.7'

module Elasticsearch
  module Model
    module Adapter
      module Mongoid
        module Records
          def records
            # On the original file, "id" is used instead of "_id"
            criteria = klass.where(:_id.in => ids)

            criteria.instance_exec(response.response['hits']['hits']) do |hits|
              define_singleton_method :to_a do
                self.entries.sort_by { |e| hits.index { |hit| hit['_id'].to_s == e.id.to_s } }
              end
            end

            criteria
          end
        end
      end
    end
  end
end
