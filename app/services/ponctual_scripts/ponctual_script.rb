# -*- encoding : UTF-8 -*-
class PonctualScripts::PonctualScript
  def initialize(options={})
    @options = options.with_indifferent_access
    @class_name = self.class.name
  end

  def run
    start_time = Time.now
    logger_infos "[START] - #{start_time}"
    execute
    logger_infos "[END] - #{Time.now} - within #{Time.now - start_time} seconds"
  end

  def rollback
    start_time = Time.now
    logger_infos "[ROLLBACK-START] - #{start_time}"
    backup
    logger_infos "[ROLLBACK-END] - #{Time.now} - within #{Time.now - start_time} seconds"
  end

  def logger_infos(message)
    infos = "[#{@class_name}] - #{message}"
    p infos #print infos to console and log
    System::Log.info('ponctual_scripts', infos)
  end

  private

  def ponctual_dir
    dir = "#{Rails.root}/spec/support/files/ponctual_scripts"

    FileUtils.makedirs(dir)
    FileUtils.chmod(0777, dir)
    dir
  end

  # Define execute method on the child class (without params, use initializer options if you need params)
  def execute; end

  # Define backup method on the child class (without params, use initializer options if you need params)
  def backup; end
end