class GoogleDrive::Collection #Must be part of GoggleDrive module not Gdr
  def upload_from_file(path, title, params = {})
    find_and_remove_files(title)

    file = @session.upload_from_file(path, title, params)

    unless root?
      add file

      @session.root_collection.remove file
    end

    file
  end


  def find_or_create_subcollections(path)
    dirs = path.split('/').select(&:present?)

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


  def find_and_remove_files(title)
    files.each do |file|
      file.delete if file.title == title
    end
  end
end
