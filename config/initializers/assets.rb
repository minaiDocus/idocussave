# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

Rails.application.config.assets.precompile += %w( admin.css admin/events.css admin/groups.css admin/invoices.css admin/journals.css admin/mobile_reponring.css
                                                  admin/notification_settings.css admin/pre_assignment_blocked_duplicates.css admin/pre_assignment_delivery.css
                                                  admin/process_reporting.css admin/retrievers.css admin/retriever_services.css admin/reporting.css admin/scanning_providers.css admin/subscriptions.css admin/budgea_retriever.css)

Rails.application.config.assets.precompile += %w( paper_process.css account/reporting.css account/profiles.css account/mcf_settings.css account/addresses.css account/organizations.css account/group_organizations.css account/ibiza.css account/paper_processes.css
                                                  account/subscriptions.css account/groups.css account/collaborators.css account/journals.css account/account_number_rules.css account/paper_set_orders.css
                                                  account/invoices.css account/customers.css account/file_naming_policies.css account/organization_addresses.css account/organization_period_options.css
                                                  account/csv_descriptors.css account/orders.css account/bank_accounts.css account/rights.css account/retrievers.css account/pre_assignment_ignored.css
                                                  account/pre_assignment_blocked_duplicates.css account/pre_assignment_delivery_errors.css account/suspended.css )

Rails.application.config.assets.precompile += %w( admin.js admin/admin.js admin/events.js admin/invoices.js admin/mobile_reporting.js admin/news.js admin/pre_assignment_blocked_duplicates.js
                                                  admin/reporting.js admin/scanning_providers.js admin/subscriptions.js admin/user.js admin/retriever_services.js admin/job_processing.js admin/budgea_retriever.js admin/counter_error_script_mailer.js admin/process_reporting.js admin/archives.js )


Rails.application.config.assets.precompile += %w( paper_process.js account/accounting_plans.js inner.js welcome.js account/ftps.js account/sftps.js account/reporting.js account/profile.js account/addresses.js account/organizations.js account/group_organizations.js account/software_users.js
                                                  account/subscriptions.js account/organization_subscriptions.js account/groups.js account/journals.js account/account_number_rules.js account/paper_set_orders.js
                                                  account/account_sharings.js account/invoices.js account/customers.js account/file_naming_policies.js account/organization_period_options.js account/csv_descriptors.js
                                                  account/orders.js account/organization_retrievers.js account/ibizabox_documents.js account/compta_analytics.js account/retrievers.js account/documents.js account/pre_assignment_ignored.js
                                                  account/pre_assignment_blocked_duplicates.js )

Rails.application.config.assets.precompile += %w( ckeditor/* )

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
