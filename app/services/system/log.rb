class System::Log
  def self.info(log_file_name=nil, message='')
    new().log log_file_name, message
  end

  def log(log_file_name, message)
    log_file_name = "_#{log_file_name}" if log_file_name.present?

    logger = Logger.new("#{Rails.root}/log/#{Rails.env}#{log_file_name.to_s}.log")
    logger.info message
  end
end