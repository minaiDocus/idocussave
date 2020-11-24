# frozen_string_literal: true

module Admin::EventsHelper
  def event_action_options_for_select
    list = t('activerecord.models.event.actions').map { |k, v| [v, k] }

    options_for_select(list, (begin
                                        params[:event_contains][:action]
                              rescue StandardError
                                nil
                                      end))
  end

  def event_target_type_options_for_select
    list = [
      %w[Page page],
      ['Journal Comptable / Utilisateur', 'account_book_type/user']
    ]
    options_for_select(list, (begin
                                        params[:event_contains][:target_type]
                              rescue StandardError
                                nil
                                      end))
  end

  def journal_ordered_attributes
    %w[
      name
      pseudonym
      description
      domain
      entry_type
      default_account_number
      account_number
      default_charge_account
      charge_account
      vat_accounts
      anomaly_account
      is_expense_categories_editable
      expense_categories
      instructions
      position
      is_default
      user_id
      created_at
      updated_at
    ]
  end

  def format_target_attribute(key, value)
    if value.is_a?(Time)
      l(value, format: "%d %b '%y %H:%M:%S")
    elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
      value ? t('yes_value') : t('no_value')
    elsif key == 'user_id'
      user = User.find value

      link_to user.code, admin_user_path(user) if user
    elsif key == 'entry_type'
      t("activerecord.models.account_book_type.attributes.entry_type_#{value}")
    else
      value
    end
  end
end
