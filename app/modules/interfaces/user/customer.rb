module Interfaces::User::Customer
  def active?
    !inactive?
  end

  def inactive?
    inactive_at.present?
  end

  def still_active?
    active? || inactive_at.to_date > Date.today.end_of_month
  end

  def configured?
    current_configuration_step.nil?
  end

  def uses_many_exportable_softwares?
    softwares_count = 0
    softwares_count += 1 if uses?(:coala)
    softwares_count += 1 if uses?(:quadratus)
    softwares_count += 1 if uses?(:csv_descriptor)

    softwares_count > 1
  end


  def uses_api_softwares?
    uses?(:ibiza) || uses?(:exact_online) || uses?(:my_unisoft)
  end


  def uses_non_api_softwares?
    uses?(:coala) || uses?(:quadratus) || uses?(:cegid) || uses?(:csv_descriptor) || use_to(:fec_agiris)
  end


  def uses?(software)
    self.try(software).try(:used?) && self.organization.try(software).try(:used?)
  end


  def uses_ibiza_analytics?
    uses?(:ibiza) && self.try(:ibiza).ibiza_id.present? && self.try(:ibiza).try(:compta_analysis_activated?)
  end


  def validate_ibiza_analytics?
    uses_ibiza_analytics? && self.try(:ibiza).try(:analysis_to_validate?)
  end


  def uses_manual_delivery?
    ( uses?(:ibiza) && !self.try(:ibiza).try(:auto_deliver?) ) ||
    ( uses?(:exact_online) && !self.try(:exact_online).try(:auto_deliver?) )
  end

  def jefacture_api_key
    organization.jefacture_api_key
  end

  def find_or_create_subscription
    self.subscription ||= Subscription.create(user_id: id)
  end

  def create_or_update_software(attributes)
    if attributes[:software].to_s == "my_unisoft"
      MyUnisoftLib::Setup.new({organization: @organization, customer: self, columns: {is_used: attributes[:columns][:is_used], action: "update"}}).execute
    else
      software = self.send(attributes[:software].to_sym) || Interfaces::Software::Configuration.softwares[attributes[:software].to_sym].new
      begin
        software.assign_attributes(attributes[:columns])
      rescue
        software.assign_attributes(attributes[:columns].to_unsafe_hash)
      end

      counter = 0
      counter += 1 if software.try(:ibiza).try(:used?)
      counter += 1 if software.try(:my_unisoft).try(:used?)
      counter += 1 if software.try(:exact_online).try(:used?)

      if counter <= 1
        if software.is_a?(Software::Ibiza) # Assign default value to avoid validation exception
          software.state                            = 'none'
          software.state_2                          = 'none'
          software.voucher_ref_target               = 'piece_number'
          software.is_auto_updating_accounting_plan = true
        end

        software.owner = self
        software.save
        software
      else
        software = nil
      end
    end
  end

  def prescribers
    collaborator? ? [] : ((organization&.admins || []) | group_prescribers)
  end

  def group_prescribers
    collaborator? ? [] : groups.flat_map(&:collaborators)
  end

  def compta_processable_journals
    account_book_types.compta_processable
  end

  def pre_assignement_displayed?
    collaborator? || is_pre_assignement_displayed
  end

  def has_collaborator_action?
    collaborator? || (is_pre_assignement_displayed && act_as_a_collaborator_into_pre_assignment)
  end

  def authorized_all_upload?
    (self.try(:options).try(:upload_authorized?) && authorized_bank_upload?) || self.organization.specific_mission
  end

  def authorized_upload?
    self.try(:options).try(:upload_authorized?) || authorized_bank_upload? || self.organization.specific_mission
  end

  def authorized_bank_upload?
    period = self.try(:subscription).try(:current_period)

    if period
      self.try(:options).try(:retriever_authorized?) && period.is_active?(:retriever_option)
    else
      false
    end
  end
end