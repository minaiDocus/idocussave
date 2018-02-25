module CodeFormatValidation
  extend ActiveSupport::Concern

  included do
    validate :format_of_code, if: :code_changed?
  end

  private

  def format_of_code
    if organization && !code.match(/\A#{organization.try(:code)}%[A-Z0-9]{1,13}\z/)
      errors.add(:code, :invalid)
    end
  end
end
