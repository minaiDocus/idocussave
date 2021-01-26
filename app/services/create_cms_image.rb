class CreateCmsImage
  # Dynamicly creates a CMS Image from an uploaded file
  def self.execute(original_filename, original_path)
    cms_image = CmsImage.new

    cms_image.original_file_name = original_filename

    CustomUtils.mktmpdir('cms_image') do |dir|
      file_path = File.join(dir, original_filename)

      FileUtils.cp original_path, file_path

      # cms_image.content = open(file_path)
      cms_image.cloud_content_object.attach(File.open(file_path), File.basename(file_path)) if cms_image.save
    end

    cms_image
  end
end
