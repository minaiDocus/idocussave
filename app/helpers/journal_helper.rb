# -*- encoding : UTF-8 -*-
# FIXME : whole check
module JournalHelper
  def is_journal_name_disabled
    !(@user.is_admin || Settings.first.is_journals_modification_authorized || !@customer || @journal.is_open_for_modification?)
  end


  def journal_name_hint
    if !@user.is_admin && !Settings.first.is_journals_modification_authorized && @customer && @journal.is_open_for_modification?
      distance_of_time = distance_of_time_in_words_to_now((@journal.created_at || Time.now) + 24.hours)

      "Ne sera plus modifiable après #{distance_of_time}. Assurez-vous qu’il sera bien le nom adopté définitivement."
    else
      ''
    end
  end


  def ibiza_journals
    if @customer.ibiza_id.present?
      Rails.cache.fetch [:ibiza, :user, @customer.ibiza_id.gsub(/({|})/, ''), :journals], expires_in: 5.minutes do
        service = IbizaJournalsService.new(@customer)

        service.execute

        if service.success?
          service.journals
        else
          []
        end
      end
    else
      []
    end
  end


  def ibiza_journals_beginning_with_a_number?
    ibiza_journals.select do |j|
      j[:name].match(/\A\d/)
    end.any?
  end


  def ibiza_journals_beginning_with_a_number_hint
    if ibiza_journals_beginning_with_a_number?
      'iDocus ne supportant pas les journaux comptables avec un nom numérique, nous avons rajouter JC devant le nom du journal comptable issu de votre outil'
    end
  end


  def journals_for_select(journal_name, type = nil)
    journals = ibiza_journals

    if journals.any?
      journals = journals.select do |j|
        j[:closed].to_i == 0
      end

      if type == 'bank'
        journals = journals.select do |j|
          j[:type].to_i.in? [5, 6]
        end
      end

      values = journals.map do |j|
        description = "#{j[:name]} (#{j[:description]})"
        description = 'JC' + description if j[:name] =~ /\A\d/
        [description, j[:name]]
      end

      if journal_name.present? && !journal_name.in?(values.map(&:last))
        description = journal_name
        description = 'JC' + description if journal_name =~ /\A\d/
        values << ["#{description} (inaccessible depuis la ged ibiza)", journal_name]
        values.sort_by(&:first)
      else
        values
      end
      
    elsif journal_name.present?
      description = journal_name
      description = 'JC' + description if journal_name =~ /\A\d/
      [["#{description} (inaccessible depuis la ged ibiza)", journal_name]]
    else
      []
    end
  end


  def journal_domain_for_select
    AccountBookType::DOMAINS.map do |e|
      e.present? ? [e, e] : ['Aucun', e]
    end
  end

  def journal_currencies
    CurrencyRate.lists
  end
end
