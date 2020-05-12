class PonctualScripts::MigrateCmsImages < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    cms = CmsImage.all
    file_sending_kits = FileSendingKit.all

    cms.each do |image|
      next if image.cloud_content.attached?

      url      = image.content.url
      img_path = image.content.path

      file_sending_kits.each do |fsk|
        has_changed = false

        if fsk.logo_path == url && url.present?
          fsk.logo_path = "cms_image:#{image.id}"
          has_changed = true
        end

        if fsk.left_logo_path == url && url.present?
          fsk.left_logo_path  = "cms_image:#{image.id}"
          has_changed = true
        end

        if fsk.right_logo_path == url && url.present?
          fsk.right_logo_path = "cms_image:#{image.id}"
          has_changed = true
        end

        fsk.save if has_changed
      end

      if File.exist?(img_path)
        image.cloud_content_object.attach(File.open(img_path), image.content_file_name)
        image.generate_thumbs
      end
    end
  end

  def backup; end
end
