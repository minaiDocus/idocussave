class CounterErrorScriptMailer < ApplicationRecord
  validates_presence_of :error_type
  validates_uniqueness_of :error_type


  def enabled?
    is_enable
  end

  def self.find_or_create_by_error_type(error_type)
    self.find_or_initialize_by(error_type: error_type) do |error_script_mailer|
      error_script_mailer.error_type = error_type
      
      error_script_mailer.save

      error_script_mailer
    end
  end
end
