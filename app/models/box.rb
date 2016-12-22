# -*- encoding : UTF-8 -*-
class Box < ActiveRecord::Base
  belongs_to :external_file_storage
end
