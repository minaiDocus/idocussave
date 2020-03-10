# -*- encoding : UTF-8 -*-
class CheckWriteDiskService
  def self.execute
    new().execute
  end

  def execute
    state     = "OK"
    motif     = "aucune"
    file_path = ""
    log_info  = "Test d'écriture disk #{Time.now.strftime("%Y-%m-%d %H:M:S")} - state: #{state} - motif: #{motif} - Start"

    LogService.info('check_io_disk', log_info)

    file_path =  "#{Rails.root}/tmp/check_write_io_disk_#{Time.now.strftime('%Y%m%d_%H%I%S')}.txt"
    File.open(file_path, 'w') do |f|
      f.write("data check !!!")
    end

    if !File.exist? file_path
      state = "NOK"
      motif = "N'existe pas"
    else      
      pdf_file_path = file_path.gsub('.txt','.pdf')      
      system "convert xc:none -page A4 #{pdf_file_path}"

      if !DocumentTools.completed?(pdf_file_path)
        state = "NOK"
        motif = "Not completed"
      end
    end

    log_info = "Test d'écriture disk #{Time.now.strftime("%Y-%m-%d %H:M:S")} - state: #{state} - motif: #{motif} - End"

    LogService.info('check_io_disk', log_info)

    if state == "NOK"
      log_document = {
        name: "CheckWriteDiskService",
        erreur_type: "Ecriture disk #{state}",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          file_path: file_path,
          motif: motif
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver
    else
      FileUtils.rm file_path
      FileUtils.rm pdf_file_path if File.exist? pdf_file_path
    end
  end
end