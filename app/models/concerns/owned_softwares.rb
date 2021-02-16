module OwnedSoftwares
  extend ActiveSupport::Concern

  included do
    has_one :ibiza, as: :owner, dependent: :destroy, class_name: 'Software::Ibiza'
    has_one :coala, as: :owner, dependent: :destroy, class_name: 'Software::Coala'
    has_one :exact_online, as: :owner, dependent: :destroy, class_name: 'Software::ExactOnline'
    has_one :quadratus, as: :owner, dependent: :destroy, class_name: 'Software::Quadratus'
    has_one :fec_agiris, as: :owner, dependent: :destroy, class_name: 'Software::FecAgiris'
    has_one :cegid, as: :owner, dependent: :destroy, class_name: 'Software::Cegid'
    has_one :csv_descriptor, as: :owner, autosave: true, dependent: :destroy, class_name: 'Software::CsvDescriptor'
    has_one :my_unisoft, as: :owner, dependent: :destroy, class_name: 'Software::MyUnisoft'
  end
end