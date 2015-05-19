# -*- encoding : UTF-8 -*-
module JournalHelper
  def is_journal_name_disabled
    !(@user.is_admin || Settings.is_journals_modification_authorized || !@customer || @journal.is_open_for_modification?)
  end

  def journal_name_hint
    if !@user.is_admin && !Settings.is_journals_modification_authorized && @customer && @journal.is_open_for_modification?
      distance_of_time = distance_of_time_in_words_to_now((@journal.created_at || Time.now) + 24.hours)
      "Ne sera plus modifiable après #{distance_of_time}. Assurez-vous qu’il sera bien le nom adopté définitivement."
    else
      ''
    end
  end

  def ibiza_journals_for_select
    Rails.cache.fetch [:ibiza, :user, @customer.ibiza_id, :journals], expires_in: 5.minutes do
      service = IbizaJournalsService.new(@customer)
      service.execute
      if service.success?
        service.journals.map do |e|
          ["#{e[:name]} (#{e[:description]})", e[:name]]
        end
      else
        []
      end
    end
  end

  def journals_for_select(journal_name)
    values = ibiza_journals_for_select
    if values.any?
      if journal_name.present? && !journal_name.in?(values.map(&:last))
        values << ["#{journal_name} (n'existe pas)", journal_name]
        values.sort_by(&:first)
      else
        values
      end
    elsif journal_name.present?
      [[journal_name, journal_name]]
    else
      []
    end
  end

  def journal_domain_for_select
    AccountBookType::DOMAINS.map do |e|
      e.present? ? [e, e] : ['Aucun', e]
    end
  end
end
