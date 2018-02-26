class Api::Mobile::AccountSharingController < MobileApiController
  respond_to :json

  def load_shared_docs
    data_docs = []
    per_page = 20

    order_by = params[:order][:order_by] || "created_at"
    direction = params[:order][:direction]? "asc" : "desc"

    case params[:order][:order_by]
      when "approval"
        order_by = "is_approved"
      else
        order_by = "created_at"
    end

    account_sharings = AccountSharing.unscoped.where(account_id: customers).search(search_terms(params[:account_sharing_contains])).
        order(order_by => direction).
        page(params[:page]).
        per(per_page)
    nb_pages = (account_sharings.total_count.to_f / per_page.to_f).ceil

    data_docs = account_sharings.inject([]) do |memo, data|
        memo += [ {
                    id_idocus:data.id.to_s,
                    date:data.created_at,
                    approval:data.is_approved,
                    client:data.collaborator.info,
                    document:data.account.info
                  }
                ]
      end

    render json: {data_shared: data_docs, nb_pages: nb_pages, total: account_sharings.total_count}, status: 200
  end

  def load_shared_contacts
    contacts = []
    per_page = 20

    order_by = params[:order][:order_by] || "created_at"
    direction = params[:order][:direction]? "asc" : "desc"

    case params[:order][:order_by]
      when "email"
        order_by = "email"
      when "company"
        order_by = "company"
      else
        order_by = "created_at"
    end

    guest_collaborators = @organization.guest_collaborators.
      search(search_terms(params[:guest_collaborator_contains])).
      order(order_by => direction).
      page(params[:page]).
      per(per_page)

    nb_pages = (guest_collaborators.total_count.to_f / per_page.to_f).ceil

    contacts = guest_collaborators.inject([]) do |memo, data|
        memo += [ {
                    id_idocus:data.id.to_s,
                    date:data.created_at,
                    email:data.email,
                    company:data.company,
                    first_name:data.first_name,
                    last_name: data.last_name,
                    account_size:data.accounts.size.to_s
                  }
                ]
      end

    render json: {contacts: contacts, nb_pages: nb_pages, total: guest_collaborators.total_count}, status: 200
  end

  def get_list_collaborators
    tags = []
    if params[:q].present?
      users = @organization.members.active.where(is_prescriber: false)
      users = users.where(
        "code REGEXP :t OR email REGEXP :t OR company REGEXP :t OR first_name REGEXP :t OR last_name REGEXP :t",
        t: params[:q].split.join('|')
      ).order(code: :asc).select do |user|
        str = [user.code, user.email, user.company, user.first_name, user.last_name].join(' ')
        !params[:q].split.detect { |e| !str.match(/#{e}/i) }
      end

      unless @user.leader?
        users = users.select do |user|
          user.is_guest || @user.customers.include?(user)
        end
      end

      users[0..9].each do |user|
        tags << { value: user.id, label: user.info}
      end
    end

    render json: {dataList: tags}, status: 200
  end

  def get_list_customers
    tags = []
    if params[:q].present?
      users = @user.leader? ? @organization.customers.active : @user.customers.active
      users = users.where("code REGEXP :t OR company REGEXP :t OR first_name REGEXP :t OR last_name REGEXP :t", t: params[:q].split.join('|')
      ).order(code: :asc).limit(10).select do |user|
        str = [user.code, user.company, user.first_name, user.last_name].join(' ')
        params[:q].split.detect { |e| !str.match(/#{e}/i) }.nil?
      end
      users.each do |user|
        tags << { value: user.id, label: user.info }
      end
    end

    render json: {dataList: tags}, status: 200
  end

  def add_shared_docs
    account_sharing = ShareAccount.new(@user, account_sharing_params, current_user).execute
    if account_sharing.persisted?
      render json: {message: 'Dossier partagé avec succès.'}, status: 200
    else
      render json: {message: 'Impossible de créer le partage.'}, status: 200
    end
  end

  def add_shared_contacts
     guest_collaborator = CreateContact.new(user_params, @organization).execute
    if guest_collaborator.persisted?
      render json: {message: 'Créé avec succès.'}, status: 200
    else
      render json: {message: 'Impossible de créer le contact.'}, status: 200
    end
  end

  def edit_shared_contacts
    guest_collaborator = @organization.guest_collaborators.find params[:id]
    guest_collaborator.update(params.require(:user).permit(:company, :first_name, :last_name))
    if guest_collaborator.save
      render json: {message: 'Modifié avec succès.'}, status: 200
    else
      render json: {message: 'Impossible de modifier le contact.'}, status: 200
    end
  end

  def accept_shared_docs
    account_sharing = AccountSharing.unscoped.where(account_id: customers).find params[:id]
    if(AcceptAccountSharingRequest.new(account_sharing).execute)
      render json: {message: 'Le partage a été valider avec succès.'}, status: 200
    else
      render json: {message: 'Impossible de valider le partage.'}, status: 200
    end
  end

  def delete_shared_docs
    if(params[:type] && params[:type] == 'customers')
      account_sharing = AccountSharing.unscoped.where(id: params[:id]).where('account_id = :id OR collaborator_id = :id', id: @user.id).first!
      if DestroyAccountSharing.new(account_sharing, @user).execute
        render json: {message: 'Le partage a été supprimer avec succès.'}, status: 200
      else
        render json: {message: 'Impossible de supprimer le partage.'}, status: 200
      end
    else
      account_sharing = AccountSharing.unscoped.where(account_id: customers).find params[:id]
      if DestroyAccountSharing.new(account_sharing).execute
        render json: {message: 'Le partage a été supprimer avec succès.'}, status: 200
      else
        render json: {message: 'Impossible de supprimer le partage.'}, status: 200
      end
    end
  end

  def delete_shared_contacts
    guest_collaborator = @organization.guest_collaborators.find params[:id]
    DestroyCollaboratorService.new(guest_collaborator).execute
    render json: {message: 'Supprimé avec succès.'}, status: 200
  end

  def load_shared_docs_customers
    data_shared = contacts = request_sharing = []

    if @user.active? && !@user.is_prescriber && @user.organization.is_active
      data_shared = data_shared_customer
      contacts = contact_shared_customer
      request_sharing = account_sharing_request_customer
    end

    render json: {data_shared: data_shared, contacts: contacts, access: request_sharing}, status: 200
  end

  def add_shared_docs_customers
    contact, account_sharing = ShareMyAccount.new(@user, user_params, current_user).execute
    if account_sharing.persisted?
      render json: {message: 'Votre compte a été partagé avec succès.'}, status: 200
    elsif Array(account_sharing.errors[:account] || account_sharing.errors[:collaborator]).include?("est déjà pris.")
      render json: {message: 'Ce contact a déjà accès à votre compte.'}, status: 200
    elsif contact.errors[:email].include?("est déjà pris.") || account_sharing.errors[:collaborator_id].include?("n'est pas valide")
      render json: {message: "Vous ne pouvez pas partager votre compte avec le contact : #{contact.email}."}, status: 200
    else
      render json: {message: 'Un problème a eu lieu pendant le partage de compte!!'}, status: 200
    end
  end

  def add_sharing_request_customers
    account_sharing_request = AccountSharingRequest.new(account_sharing_request_params_customers)
    account_sharing_request.user = @user
    if account_sharing_request.save
      render json: {message: 'Demande envoyé avec succès.'}, status: 200
    else
      render json: {message: "Impossible d'envoyé votre demande!!"}, status: 200
    end
  end


  private

  def data_shared_customer
    data_shared = @user.account_sharings.inject([]) do |memo, data|
         memo += [ {
                      id_idocus:data.id,
                      name:data.account.info,
                    }
                  ]
    end
  end

  def contact_shared_customer
   contacts = @user.inverse_account_sharings.inject([]) do |memo, data|
      memo += [ {
                    id_idocus:data.id,
                    name:data.collaborator.info,
                  }
                ]
    end
  end

  def account_sharing_request_customer
    access = @user.account_sharings.pending.select { |e| e.collaborator == @user }.inject([]) do |memo, data|
        memo += [ {
                      id_idocus:data.id,
                      name:data.account.info,
                    }
                  ]
    end
  end

  def account_sharing_params
    params.require(:account_sharing).permit(:collaborator_id, :account_id)
  end

  def user_params
    params.require(:user).permit(:email, :company, :first_name, :last_name)
  end

  def account_sharing_request_params_customers
    params.require(:account_sharing_request).permit(:code_or_email)
  end

  def @user.leader?
    @user == @organization.leader || @user.is_admin
  end
end
