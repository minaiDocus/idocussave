# frozen_string_literal: true

class Api::Mobile::PreseizuresController < MobileApiController
  respond_to :json

  def get_details
    preseizure = Pack::Report::Preseizure.find params[:id]

    unit = preseizure.try(:unit) || 'EUR'
    preseizure_entries = preseizure.entries
    pre_tax_amount = preseizure_entries.select { |entry| entry.account.type == 2 }.try(:first).try(:amount) || 0

    analytics = preseizure.analytic_reference
    data_analytics = []
    if analytics
      3.times do |i|
        j = i + 1
        references = analytics.send("a#{j}_references")
        name       = analytics.send("a#{j}_name")
        next unless references.present?

        references = JSON.parse(references)
        references.each do |ref|
          if name.present? && ref['ventilation'].present? && (ref['axis1'].present? || ref['axis2'].present? || ref['axis3'].present?)
            data_analytics << { name: name, ventilation: ref['ventilation'], axis1: ref['axis1'], axis2: ref['axis2'], axis3: ref['axis3'] }
            end
        end
      end
    end

    render json: { pre_tax_amount: pre_tax_amount, preseizure: preseizure, preseizure_entries: preseizure_entries, preseizure_accounts: preseizure.accounts, analytics: data_analytics, accountCompletion: accountCompletionOf(preseizure) }, status: 200
  end

  def deliver
    if params[:ids].present?
      preseizures = Pack::Report::Preseizure.not_delivered.not_locked.where(id: params[:ids])
    elsif params[:id]
      reports = if params[:type] == 'report'
                  Pack::Report.where(id: params[:id])
                else
                  Pack.find(params[:id]).try(:reports)
                end

      if reports.present?
        preseizures = Pack::Report::Preseizure.not_delivered.not_locked.where(report_id: reports.collect(&:id))
      end
    end

    if preseizures.present?
      preseizures.group_by(&:report_id).each do |_report_id, preseizures_by_report|
        PreAssignment::CreateDelivery.new(preseizures_by_report, %w[ibiza exact_online my_unisoft]).execute
      end
    end

    render json: { success: true }, status: :ok
  end

  def edit_preseizures
    preseizures = Pack::Report::Preseizure.where(id: params[:ids])
    error = ''

    preseizures.each do |preseizure|
      preseizure.assign_attributes params[:datas].permit(:date, :deadline_date, :third_party, :operation_label, :piece_number, :amount, :currency, :conversion_rate, :observation)
      if preseizure.conversion_rate_changed? || preseizure.amount_changed?
        preseizure.update_entries_amount
      end
      error = preseizure.errors.full_messages unless preseizure.save
    end

    if error.present?
      render json: { error: true, message: error }, status: 200
    else
      render json: { success: true }, status: 200
    end
  end

  def edit_entry
    entry = Pack::Report::Preseizure::Entry.find params[:id]

    error = ''
    unless entry.update_attributes params[:datas].permit(:type, :amount)
      error = entry.errors.full_messages
    end

    if error.present?
      render json: { error: true, message: error }, status: 200
    else
      render json: { success: true }, status: 200
    end
  end

  def edit_account
    account = Pack::Report::Preseizure::Account.find params[:id]

    error = ''
    unless account.update_attributes params[:datas].permit(:number, :lettering)
      error = account.errors.full_messages
    end

    if error.present?
      render json: { error: true, message: error }, status: 200
    else
      render json: { success: true }, status: 200
    end
  end

  private

  def accountCompletionOf(preseizure)
    account_completions = {}

    preseizure.accounts.each do |account|
      account_completions[account.id.to_s] = account.get_similar_accounts
    end

    account_completions
  end
end
