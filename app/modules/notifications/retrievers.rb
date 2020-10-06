class Notifications::Retrievers < Notifications::Notifier
  include Rails.application.routes.url_helpers

  def initialize(retriever=nil)
    @retriever = retriever
  end

  def notify_wrong_pass
    users.map do |user|
      if user.notify.try(:r_wrong_pass)
        if user == @retriever.user
          message   = "Votre mot de passe pour l'automate #{name} est invalide. Veuillez le reconfigurer s'il vous plaît."
        else
          message   = "Le mot de passe pour l'automate #{name}, du dossier #{user_info}, est invalide. Veuillez le reconfigurer s'il vous plaît."
        end

        create_notification({
          url:         url_for(user),
          user:        user,
          notice_type: 'retriever_wrong_pass',
          title:       'Automate - Mot de passe invalide',
          message:     message
        }, false)
      end
    end
  end

  def notify_info_needed
    users.map do |user|
      if user == @retriever.user
        message   = "Veuillez fournir les informations demandées pour pouvoir continuer le processus de récupération de votre automate #{name}."
      else
        message   = "Veuillez fournir les informations demandées pour pouvoir continuer le processus de récupération de l'automate #{name} pour le dossier #{user_info}."
      end

      create_notification({
        url:         url_for(user),
        user:        user,
        notice_type: 'retriever_info_needed',
        title:       'Automate - Information supplémentaire nécessaire',
        message:     message
      }, false)
    end
  end

  def notify_website_unavailable
    users.map do |user|
      if user.notify.try(:r_site_unavailable)
        if user == @retriever.user
          message   = "Le site web du fournisseur/banque de votre automate #{name} est actuellement indisponible."
        else
          message   = "Le site web du fournisseur/banque de l'automate #{name}, du dossier #{user_info}, est actuellement indisponible."
        end

        create_notification({
          url:         url_for(user),
          user:        user,
          notice_type: 'retriever_website_unavailable',
          title:       'Automate - Site web indisponible',
          message:     message
        }, false)
      end
    end
  end

  def notify_action_needed
    if @retriever.user.notify.try(:r_action_needed)
      create_notification({
        url: account_retrievers_url(account_id: @retriever.user.id),
        user: @retriever.user,
        notice_type: 'retriever_action_needed',
        title: 'Automate - Une action est nécessaire',
        message: "Votre fournisseur/banque requiert que vous validiez leurs CGU sur leur site avant de pouvoir poursuivre le processus de récupération de votre automate #{name}."
      }, true)
    end
  end

  def notify_bug
    users.each do |user|
      if user.notify.try(:r_bug)
        if user == @retriever.user
          message   = "Votre automate #{name} ne fonctionne pas correctement. #{@retriever.budgea_error_message.to_s}"
        else
          message   = "L'automate #{name} du dossier #{user_info} ne fonctionne pas correctement. #{@retriever.budgea_error_message.to_s}"
        end

        create_notification({
          url:         url_for(user),
          user:        user,
          notice_type: 'retriever_bug',
          title:       'Automate - Bug',
          message:     message
        }, false)
      end
    end
  end

  def notify_not_registered_error
    if @retriever.budgea_error_message.present?
      users.map do |user|
        if user.notify.try(:r_bug)
          if user == @retriever.user
            message   = "Votre automate #{name} a rencontré l'erreur suivante: #{@retriever.budgea_error_message.to_s}"
          else
            message   = "L'automate #{name} du dossier #{user_info} a rencontré l'erreur suivante: #{@retriever.budgea_error_message.to_s}"
          end

          create_notification({
            url:         url_for(user),
            user:        user,
            notice_type: 'retriever_bug',
            title:       'Automate - Erreur',
            message:     message
          }, false)
        end
      end
    end
  end

  def notify_new_documents(new_documents_count)
    users.map do |user|
      if user.notify.try(:r_new_documents_now?)
        create_new_documents_notification user, new_documents_count
      elsif user.notify.try(:r_new_documents_delayed?)
        Notify.update_counters user.notify.id, r_new_documents_count: new_documents_count
      end
    end
  end

  def create_new_documents_notification(user, new_documents_count, multiple=false)
    subject = new_documents_count == 1 ? 'nouveau document' : 'nouveaux documents'
    message = "#{new_documents_count} #{subject}"
    message += new_documents_count == 1 ? 'a été récupéré' : ' ont été récupérés'
    if multiple
      message += ' depuis les automates.'
    else
      if user == @retriever.user
        message += " par votre automate #{name}."
      else
        message += " par l'automate #{name} du dossier #{user_info}."
      end
    end

    create_notification({
      url:         root_url(dashboard_summary: :last_retrieved),
      user:        user,
      notice_type: 'retriever_new_documents',
      title:       'Automate - ' + subject.capitalize,
      message:     message
    }, false)
  end

  def notify_new_operations(new_operations_count)
    users.map do |user|
      if user.notify.try(:r_new_operations_now?)
        create_new_operations_notification user, new_operations_count
      elsif user.notify.try(:r_new_operations_delayed?)
        Notify.update_counters user.notify.id, r_new_operations_count: new_operations_count
      end
    end
  end

  def create_new_operations_notification(user, new_operations_count, multiple=false)
    subject = new_operations_count == 1 ? 'nouvelle opération' : 'nouvelles opérations'
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

    create_notification({
      url:         root_url(dashboard_summary: :last_retrieved),
      user:        user,
      notice_type: 'retriever_new_operations',
      title:       'Automate - ' + subject.capitalize,
      message:     message
    }, false)
  end

  def notify_no_bank_account_configured
    prescribers.each do |prescriber|
      create_notification({
        url:         account_bank_accounts_url(@retriever.user),
        user:        prescriber,
        notice_type: 'retriever_no_bank_account_configured',
        title:       'Automate - En attente de configuration',
        message:     "Aucun compte bancaire n'a été configuré pour l'automate #{name} du dossier #{user_info}."
      }, false)
    end
  end

  class << self
    def notify_summary_updates
      Notify.where('r_new_documents_count > 0').find_each do |notify|
        ActiveRecord::Base.transaction do
          Notifications::Retrievers.new.create_new_documents_notification notify.user, notify.try(:r_new_documents_count), true
          Notify.update_counters notify.id, r_new_documents_count: -notify.try(:r_new_documents_count)
        end
      end

      Notify.where('r_new_operations_count > 0').find_each do |notify|
        ActiveRecord::Base.transaction do
          Notifications::Retrievers.new.create_new_operations_notification notify.user, notify.try(:r_new_operations_count), true
          Notify.update_counters notify.id, r_new_operations_count: -notify.try(:r_new_operations_count)
        end
      end

      true
    end

    def notify_no_bank_account_configured
      Retriever.banks.find_each do |retriever|
        if retriever.bank_accounts.count > 0 && retriever.bank_accounts.configured.count == 0
          Notifications::Retrievers.new(retriever).notify_no_bank_account_configured
        end
      end
    end
  end

  private

  def users
    [@retriever.user, @retriever.user.collaborators, prescribers, developpers].flatten.compact
  end

  def prescribers
    return @prescribers if @prescribers.present?

    @prescribers = @retriever.user.prescribers + developpers
    @prescribers = @prescribers.flatten.compact
  end

  def developpers
    User.where(email: Settings.first.notify_errors_to)
  end

  def url_for(user)
    account_retrievers_url(account_id: @retriever.user.id)
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
