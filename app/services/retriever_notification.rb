class RetrieverNotification
  include Rails.application.routes.url_helpers

  def initialize(retriever=nil)
    @retriever = retriever
  end

  def notify_wrong_pass
    users.map do |user|
      notification = Notification.new
      notification.user        = user
      notification.url         = url_for user
      notification.notice_type = 'retriever_wrong_pass'
      notification.title       = 'Automate - Mot de passe invalide'
      if user == @retriever.user
        notification.message   = "Votre mot de passe pour l'automate #{name} est invalide. Veuillez le reconfigurer s'il vous plaît."
      else
        notification.message   = "Le mot de passe pour l'automate #{name}, du dossier #{user_info}, est invalide. Veuillez le reconfigurer s'il vous plaît."
      end
      notification.save
    end
  end

  def notify_info_needed
    users.map do |user|
      notification = Notification.new
      notification.user        = user
      notification.url         = url_for user
      notification.notice_type = 'retriever_info_needed'
      notification.title       = 'Automate - Information supplémentaire nécessaire'
      if user == @retriever.user
        notification.message   = "Veuillez fournir les informations demandées pour pouvoir continuer le processus de récupération de votre automate #{name}."
      else
        notification.message   = "Veuillez fournir les informations demandées pour pouvoir continuer le processus de récupération de l'automate #{name} pour le dossier #{user_info}."
      end
      notification.save
    end
  end

  def notify_website_unavailable
    users.map do |user|
      if user.notify.r_site_unavailable
        notification = Notification.new
        notification.user        = user
        notification.url         = url_for user
        notification.notice_type = 'retriever_website_unavailable'
        notification.title       = 'Automate - Site web indisponible'
        if user == @retriever.user
          notification.message   = "Le site web du fournisseur/banque de votre automate #{name} est actuellement indisponible."
        else
          notification.message   = "Le site web du fournisseur/banque de l'automate #{name}, du dossier #{user_info}, est actuellement indisponible."
        end
        notification.save
      end
    end
  end

  def notify_action_needed
    if @retriever.user.notify.r_action_needed
      notification = Notification.new
      notification.user        = @retriever.user
      notification.notice_type = 'retriever_action_needed'
      notification.title       = 'Automate - Une action est nécessaire'
      notification.message     = "Votre fournisseur/banque requiert que vous validiez leurs CGU sur leur site avant de pouvoir poursuivre le processus de récupération de votre automate #{name}."
      notification.url         = account_retrievers_url(account_id: @retriever.user.id)
      notification.save
      NotifyWorker.perform_async(notification.id)
    end
  end

  def notify_bug
    users.each do |user|
      if user.notify.r_bug
        notification = Notification.new
        notification.user        = user
        notification.url         = url_for user
        notification.notice_type = 'retriever_bug'
        notification.title       = 'Automate - Bug'
        if user == @retriever.user
          notification.message   = "Votre automate #{name} ne fonctionne pas correctement."
        else
          notification.message   = "L'automate #{name} du dossier #{user_info} ne fonctionne pas correctement."
        end
        notification.save
        NotifyWorker.perform_async(notification.id)
      end
    end
    NotificationsMailer.delay(queue: :mailers).notify_retrievers_bug_to_admin @retriever
  end

  def notify_new_documents(new_documents_count)
    users.map do |user|
      if user.notify.r_new_documents_now?
        create_new_documents_notification user, new_documents_count
      elsif user.notify.r_new_documents_delayed?
        Notify.update_counters user.notify.id, r_new_documents_count: new_documents_count
      end
    end
  end

  def create_new_documents_notification(user, new_documents_count, multiple=false)
    subject = new_documents_count == 1 ? 'nouveau document' : 'nouveaux documents'
    notification = Notification.new
    notification.user        = user
    notification.url         = root_url dashboard_summary: :last_retrieved
    notification.notice_type = 'retriever_new_documents'
    notification.title       = 'Automate - ' + subject.capitalize
    message = "#{new_documents_count} #{subject} "
    message += new_documents_count == 1 ? 'a été récupéré' : 'ont été récupérés'
    if multiple
      message += ' depuis les automates.'
    else
      if user == @retriever.user
        message += " par votre automate #{name}."
      else
        message += " par l'automate #{name} du dossier #{user_info}."
      end
    end
    notification.message     = message
    notification.save!
  end

  def notify_new_operations(new_operations_count)
    users.map do |user|
      if user.notify.r_new_operations_now?
        create_new_operations_notification user, new_operations_count
      elsif user.notify.r_new_operations_delayed?
        Notify.update_counters user.notify.id, r_new_operations_count: new_operations_count
      end
    end
  end

  def create_new_operations_notification(user, new_operations_count, multiple=false)
    subject = new_operations_count == 1 ? 'nouvelle opération' : 'nouvelles opérations'
    notification = Notification.new
    notification.user        = user
    notification.url         = root_url dashboard_summary: :last_retrieved
    notification.notice_type = 'retriever_new_operations'
    notification.title       = 'Automate - ' + subject.capitalize
    message = "#{new_operations_count} #{subject} "
    message += new_operations_count == 1 ? 'a été récupéré' : 'ont été récupérés'
    if multiple
      message += ' depuis les automates.'
    else
      if user == @retriever.user
        message += " par votre automate #{name}."
      else
        message += " par l'automate #{name} du dossier #{user_info}."
      end
    end
    notification.message     = message
    notification.save!
  end

  def notify_no_bank_account_configured
    prescribers.each do |prescriber|
      notification = Notification.new
      notification.user        = prescriber
      notification.url         = account_organization_customer_bank_accounts_url @retriever.user.organization, @retriever.user
      notification.notice_type = 'retriever_no_bank_account_configured'
      notification.title       = 'Automate - En attente de configuration'
      notification.message     = "Aucun compte bancaire n'a été configuré pour l'automate #{name} du dossier #{user_info}."
      notification.save
    end
  end

  class << self
    def notify_summary_updates
      Notify.where('r_new_documents_count > 0').find_each do |notify|
        ActiveRecord::Base.transaction do
          RetrieverNotification.new.create_new_documents_notification notify.user, notify.r_new_documents_count, true
          Notify.update_counters notify.id, r_new_documents_count: -notify.r_new_documents_count
        end
      end

      Notify.where('r_new_operations_count > 0').find_each do |notify|
        ActiveRecord::Base.transaction do
          RetrieverNotification.new.create_new_operations_notification notify.user, notify.r_new_operations_count, true
          Notify.update_counters notify.id, r_new_operations_count: -notify.r_new_operations_count
        end
      end

      true
    end

    def notify_no_bank_account_configured
      Retriever.banks.find_each do |retriever|
        if retriever.bank_accounts.count > 0 && retriever.bank_accounts.configured.count == 0
          RetrieverNotification.new(retriever).notify_no_bank_account_configured
        end
      end
    end
  end

  private

  def users
    [@retriever.user, @retriever.user.collaborators, prescribers].flatten.compact
  end

  def prescribers
    @prescribers ||= @retriever.user.prescribers
  end

  def url_for(user)
    if user.is_prescriber
      account_organization_customer_retrievers_url(@retriever.user.organization, @retriever.user)
    else
      account_retrievers_url(account_id: @retriever.user.id)
    end
  end

  def default_url_options
    ActionMailer::Base.default_url_options
  end

  def name
    @name ||= ActionController::Base.helpers.sanitize @retriever.clear_name
  end

  def user_info
    @user_info ||= ActionController::Base.helpers.sanitize @retriever.user.info
  end
end
