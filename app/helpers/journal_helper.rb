# -*- encoding : UTF-8 -*-
module JournalHelper
  def ibiza_journals_for_select
    Rails.cache.fetch [:ibiza, :user, @user.ibiza_id, :journals], expires_in: 5.minutes do
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

  def journal_domain_for_select
    AccountBookType::DOMAINS.map do |e|
      e.present? ? [e, e] : ['Aucun', e]
    end
  end
end
