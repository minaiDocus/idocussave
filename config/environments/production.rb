Idocus::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  config.eager_load = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = 'X-Sendfile'

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  config.log_level = :info

  # Prepend all log lines with the following tags.
  config.log_tags = [:uuid]

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  config.cache_store = :redis_store, { 
                                      db: 1,
                                      host: 'mymaster',
                                      role: :master,
                                      sentinels: [
                                        { host: '172.16.0.171', port: 26379 },
                                        { host: '172.16.0.172', port: 26379 },
                                        { host: '172.16.0.161', port: 26379 },
                                        { host: '172.16.0.161', port: 26379 },
                                        { host: '172.16.0.191', port: 26379 },
                                        { host: '172.16.0.192', port: 26379 }
                                      ],
                                      failover_reconnect_timeout: 20
                                    }

  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  # config.serve_static_files = false
  config.public_file_server.enabled = true
  
  # Enable serving of images, stylesheets, and javascripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { host: 'my.idocus.com', protocol: 'https' }

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_options = { from: 'notification@idocus.com' }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Compress JavaScript and CSS
  config.assets.js_compress = :uglifier

  # Don't fallback to assets pipeline
  # config.assets.compile = false
  config.assets.compile = true

  # Generate digests for assets URLs
  # config.assets.digest = true
  config.assets.digest = true

  config.active_storage.service = :openstack_prod

  # Adding js files
  config.assets.precompile += Dir.glob(Rails.root.join('app/assets/javascripts/**/*')).grep(/\.(js|coffee)\z/)

  # Adding css files
  config.assets.precompile += Dir.glob(Rails.root.join('app/assets/stylesheets/**/*')).grep(/\.(css|sass|scss)\z/)
end
