class PonctualScripts::FixOperationReport < PonctualScripts::PonctualScript
  def self.execute(options)
    new(options).run
  end

  def self.rollback(options)
    new(options).rollback
  end

  private

  def execute
    @file_name  = @options[:file_name] || 'preseizures'
    @period     = @options[:period] || '20210215'

    if File.exist?(save_file_path)
      logger_infos "[BrokenReport] - This script has been already launched"
      return false
    end

    logger_infos "[BrokenReport] - file name: #{@file_name} - period : #{@period}"

    file = File.open(save_file_path, 'w+')

    preseizures  = Pack::Report::Preseizure.where("DATE_FORMAT(created_at, '%Y%m%d') > '#{@period}' AND operation_id > 0")
    changed_pres_count = 0
    new_report_count   = 0

    last_date   = 0

    preseizures.each do |preseizure|
      report = preseizure.report

      if report.pack_id.to_i > 0
        file.write(preseizure.to_json + "\n")

        changed_pres_count += 1

        report_name = report.name
        user        = preseizure.user

        new_report  = Pack::Report.where(name: report_name).where(pack_id: [nil, '']).first

        if not new_report
          new_report_count += 1

          new_report              = Pack::Report.new
          new_report.organization = user.organization
          new_report.user         = user
          new_report.type         = 'FLUX'
          new_report.name         = report_name
          new_report.save

          logger_infos "[BrokenReport] - New report: #{report_name} - id: #{new_report.reload.id}"
        end

        preseizure.report = new_report
        preseizure.save

        if last_date != preseizure.created_at.strftime('%d-%m-%Y')
          last_date = preseizure.created_at.strftime('%d-%m-%Y')
          logger_infos "[BrokenReport] - Date pres: #{last_date}"
        end
      end
    end

    logger_infos "[BrokenReport] - Changed_pres: #{changed_pres_count} - New reports : #{new_report_count} - done"
  end

  def backup
    @file_name  = @options[:file_name] || 'preseizures'

    if File.exist?(save_file_path)
      File.foreach(save_file_path) do |line|
        preseizure = JSON.parse(line).with_indifferent_access
        back_preseizure = Pack::Report::Preseizure.find preseizure[:id]

        back_preseizure.report_id = preseizure[:report_id]
        back_preseizure.save
      end
    else
      logger_infos "[BrokenReport] - No saved file found"
    end
  end


  def save_file_path
    File.join(ponctual_dir, "#{@file_name}.txt")
  end
end

