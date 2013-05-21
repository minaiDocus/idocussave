stage = Rails.env
prefix = "#{Rails.application.class.parent_name.downcase}_#{stage}"
Tire::Model::Search.index_prefix(prefix)