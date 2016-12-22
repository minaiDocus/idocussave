class CreateCmsImage
  # Dynamicly creates a CMS Image from an uploaded file
  def self.execute(original_filename, original_path)
    cms_image = CmsImage.new

    cms_image.original_file_name = original_filename

    Dir.mktmpdir do |dir|
      file_path = File.join(dir, original_filename)

      FileUtils.cp original_path, file_path

      cms_image.content = open(file_path)
    end

    cms_image.save

    cms_image
  end
end
