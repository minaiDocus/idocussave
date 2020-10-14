# frozen_string_literal: true

module Account::IbizaboxHelper
  def ibizabox_folder_state(folder)
    if folder.state == 'waiting_selection'
      link_to 'Sélectionner les documents', select_account_organization_customer_ibizabox_documents_path(@organization, @customer, document_contains: { journal: folder.journal.name }), class: 'btn btn-mini'
    else
      content_tag('span', class: ibizabox_state_label(folder.state)) do
        t('activerecord.models.ibizabox_folder.attributes.states.' + (folder.state.presence || 'none'))
      end
    end
  end

  def ibiza_journal_accessible?(folder, ibiza_journals)
    @is_accessible = false

    unless ibiza_journals.nil? || ibiza_journals.at_css('data').children.empty?
      ibiza_journals.css('wsJournals').each do |node|
        journal = folder.journal
        ref_ibiza = node.at_css('ref').try(:content)
        ref_folder = journal.use_pseudonym_for_import ? (journal.pseudonym.presence || journal.name) : journal.name

        if ref_folder == ref_ibiza && !ref_folder.nil? && node.at_css('presentInGed').try(:content).to_i == 1
          return @is_accessible = true
        end
      end
    end
    @is_accessible
  end

  def ibizabox_state_label(state)
    case state
    when 'processing'
      'fs-origin badge badge-warning'
    when 'ready'
      'fs-origin badge badge-success'
    when 'inactive'
      'fs-origin badge badge-secondary'
    end
  end
end
