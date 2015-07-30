module ActionMailer
  class Base
    cattr_accessor :smtp_config

    self.smtp_config = YAML::load(File.open(Rails.root.join('config/smtp.yml')))

    def self.smtp_settings
      return super if Rails.env.test?
      if Rails.env.development?
        name = 'localhost'
      elsif mailer_name.in?(%w(welcome_mailer invoice_mailer))
        name = 'secondary'
      else
        name = 'primary'
      end
      smtp_config[name].symbolize_keys
    end
  end
end
