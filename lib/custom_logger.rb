class CustomLogger < Rails::Rack::Logger
  def initialize(app, opts = {})
    @opts = opts
    @opts[:silenced] ||= []
    @opts[:alternative] ||= []
    @logger = Rails.logger
    super(app, Rails.application.config.log_tags)
  end

  def call(env)
    if @opts[:silenced].include?(env['PATH_INFO'])
      Rails.logger.silence do
        @app.call(env)
      end
    else
      choose_logger(env['PATH_INFO'])
      super(env)
    end
  end

  private

  def choose_logger(path_info)
    chosen_logger = @opts[:alternative].include?(path_info) ? alt_logger : @logger
    Rails.logger                  = chosen_logger
    ActionController::Base.logger = chosen_logger
    ActiveRecord::Base.logger     = chosen_logger
    ActionView::Base.logger       = chosen_logger
    chosen_logger
  end

  def alt_logger
    return @alt_logger if @alt_logger
    @alt_logger = ActiveSupport::Logger.new("#{Rails.root}/log/#{Rails.env}_alt.log")
    @alt_logger.formatter = Rails.application.config.log_formatter
    @alt_logger = ActiveSupport::TaggedLogging.new(@alt_logger)
    @alt_logger
  end
end
