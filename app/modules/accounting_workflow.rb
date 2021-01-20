module AccountingWorkflow
  def self.dir
    case Rails.env
    when 'production'
      CustomUtils.add_chmod_access_into("/nfs/staffing/")
      Pathname.new('/nfs/staffing')
    when 'staging'
      Pathname.new('/ftp/prepa_compta')
    when 'development'
      Pathname.new('/Users/toto/ftp/prepa_compta')
    when 'test'
      Pathname.new("#{Rails.root}/files/test/prepa_compta")
    end
  end

  def self.grouping_dir
    dir.join('grouping')
  end

  def self.ocr_processing_dir
    case Rails.env
    when 'production'
      CustomUtils.add_chmod_access_into("/nfs/ocr/")
      Pathname.new('/nfs/ocr')
    when 'staging'
      Pathname.new('/ftp/ocr_processing')
    when 'development'
      Pathname.new('/Users/toto/ftp/ocr_processing')
    when 'test'
      Pathname.new("#{Rails.root}/files/test/ocr_processing")
    end
  end

  def self.pre_assignments_dir
    dir.join('pre_assignments')
  end
end