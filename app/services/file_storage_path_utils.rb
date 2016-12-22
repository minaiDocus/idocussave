# Handles old storage paths with mongo db ids
module FileStoragePathUtils
  def self.path_for_object(object)
    id = object.mongo_id ? object.mongo_id : object.id

    if object.class.in?([Invoice, Pack::Piece, Document])
      "#{Rails.root}/files/production/#{object.class.table_name}/contents/#{id}/original/#{object.content_file_name}"
    elsif object.is_a?(TempDocument)
      "#{Rails.root}/files/production/#{@document.class.table_name}/#{@document.mongo_id}/#{@document.content_file_name}"
    end
  end
end
