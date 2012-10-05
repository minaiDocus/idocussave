module GoogleDrive
  class Collection
    def upload_from_file(path, title,params = {})
      file = @session.upload_from_file(path, title, params)
      add file
      @session.root_collection.remove file
      file
    end

    def find_or_create_subcollections(path)
      dirs = path.split('/').select { |e| e.present? }
      current_collection = self
      dirs.each do |dir|
        collection = current_collection.subcollection_by_title(dir)
        if collection
          current_collection = collection
        else
          current_collection = current_collection.create_subcollection(dir)
        end
      end
      current_collection
    end
  end
end
