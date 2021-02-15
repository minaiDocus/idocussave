class PonctualScripts::CorrectReportOfOperations < PonctualScripts::PonctualScript
  def self.execute    
    new().run
  end

  def self.rollback
    new().rollback
  end

  private 

  def execute
    updated_list = []

    logger_infos "[CorrectOperationReport] - Script start"
    if(!File.exist?(file_path))
      preseizures = Pack::Report::Preseizure.where('DATE_FORMAT(created_at, "%Y%m") >= "202102" AND operation_id > 0')

      preseizures.each do |preseizure|
        report = preseizure.report

        if report && report.pack_id.to_i > 0
          simil_report = Pack::Report.where(name: report.name).where(pack_id: [nil, '']).first

          if not simil_report
            simil_report              = Pack::Report.new
            simil_report.organization = preseizure.user.organization
            simil_report.user         = preseizure.user
            simil_report.type         = 'FLUX'
            simil_report.name         = report.name
            simil_report.save
          end

          preseizure.report = simil_report
          preseizure.save

          updated_list << { id: preseizure.id, last_report: report.id, new_report: simil_report.id }
        elsif !report
          logger_infos "[CorrectOperationReport] - Presizure: #{preseizure.id} - No report found"
        end
      end

      File.write(file_path, updated_list.to_json)
    else
      logger_infos "[CorrectOperationReport] - Ponctual already launched"
    end

    logger_infos "[CorrectOperationReport] - Script end"
  end

  def backup
    logger_infos "[CorrectOperationReport] - Backup start"
    if File.exist? file_path
      updated_list = JSON.parse File.read(file_path)

      updated_list.each do |list|
        preseizure = Pack::Report::Preseizure.find list['id'].strip.to_i
        preseizure.report_id = list['last_report'].strip.to_i
        preseizure.save
      end
    else
      logger_infos "[CorrectOperationReport] - No backup found"
    end
    logger_infos "[CorrectOperationReport] - Backup end"
  end

  def file_path
    File.join(ponctual_dir, "operations.json")
  end

  def ponctual_dir
    dir = "#{Rails.root}/spec/support/files/ponctual_scripts/correct_operation_report"
    FileUtils.makedirs(dir)
    FileUtils.chmod(0777, dir)
    dir
  end
end