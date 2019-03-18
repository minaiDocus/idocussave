# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

Rails.application.config.assets.precompile += %w( admin.css admin/events.css admin/groups.css admin/invoices.css admin/journals.css admin/mobile_reponring.css 
                                                  admin/notification_settings.css admin/pre_assignment_blocked_duplicates.css admin/pre_assignment_delivery.css
                                                  admin/process_reporting.css admin/retrievers.css admin/reporting.css admin/scanning_providers.css admin/subscriptions.css)

Rails.application.config.assets.precompile += %w( admin.js admin/admin.js admin/events.js admin/invoices.js admin/mobile_reporting.js admin/news.js admin/pre_assignment_blocked_duplicates.js
                                                  admin/reporting.js admin/scanning_providers.js admin/subscriptions.js admin/user.js )

Rails.application.config.assets.precompile += %w( inner.js welcome.js account/reporting.js )

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
