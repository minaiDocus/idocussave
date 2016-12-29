# Handles old storage paths with mongo db ids
module FileStoragePathUtils
  def self.path_for_object(object)
    id = object.mongo_id ? object.mongo_id : object.id

    if object.class.in?([Invoice, Document])
      "#{Rails.root}/files/#{Rails.env}/#{object.class.table_name}/contents/#{id}/original/#{object.content_file_name}"
    elsif object.is_a?(Pack::Piece)
      "#{Rails.root}/files/#{Rails.env}/pack/pieces/contents/#{id}/original/#{object.content_file_name}"
    elsif object.is_a?(TempDocument)
      "#{Rails.root}/files/#{Rails.env}/#{object.class.table_name}/#{id}/#{object.content_file_name}"
    end
  end
end
