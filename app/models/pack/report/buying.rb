# -*- encoding : UTF-8 -*-
class Pack::Report::Buying
  include Mongoid::Document
  include Mongoid::Timestamps

  references_one :report, class_name: "Pack::Report", as: :item, dependent: :destroy
end
