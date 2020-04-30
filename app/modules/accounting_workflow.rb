module AccountingWorkflow
  def self.dir
    case Rails.env
    when 'production'
      Rails.root.join('files', Rails.env, 'prepa_compta')
    when 'staging'
      Pathname.new('/ftp/prepa_compta')
    when 'development'
      Pathname.new('/Users/toto/ftp/prepa_compta')
    end
  end

  def self.grouping_dir
    dir.join('grouping')
  end

  def self.ocr_processing_dir
    case Rails.env
    when 'production'
      Rails.root.join('files', Rails.env, 'ocr_processing')
    when 'staging'
      Pathname.new('/ftp/ocr_processing')
    when 'development'
      Pathname.new('/Users/toto/ftp/ocr_processing')
    end
  end

  def self.pre_assignments_dir
    dir.join('pre_assignments')
  end
end
