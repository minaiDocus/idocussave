# -*- encoding : UTF-8 -*-
class PonctualScripts::PonctualScript
  def initialize(options={})
    @options = options
    @class_name = self.class.name
  end

  def run
    start_time = Time.now
    logger_infos "[START] - #{start_time}"
    execute
    logger_infos "[END] - #{Time.now} - within #{Time.now - start_time} seconds"
  end

  def logger_infos(message)
    infos = "[#{@class_name}] - #{message}"
    p infos #print infos to console and log
    LogService.info('ponctual_scripts', infos)
  end

  private

  # Define execute method on the child class (without params, use initializer options if you need params)
  def execute; end
end