module Account::IbizaboxHelper
  def ibizabox_folder_state(folder)
    if folder.state == 'waiting_selection'
      link_to 'Sélectionner les documents', select_account_organization_customer_ibizabox_documents_path(@organization, @customer, document_contains: { journal: folder.journal.name }), class: 'btn btn-mini'
    else
      content_tag('span',class: ibizabox_state_label(folder.state)) do
        t('activerecord.models.ibizabox_folder.attributes.states.' + (folder.state.presence || 'none'))
      end
    end
  end


  def ibizabox_state_label(state)
    case state
    when 'processing'
      'label label-warning'
    when 'ready'
      'label label-success'
    when 'inactive'
      'label'
    end
  end
end
