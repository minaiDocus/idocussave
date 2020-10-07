# -*- encoding : UTF-8 -*-
class BudgeaRetrieverAdminToXlsService
  def execute(export_type='data')
    accounts              = BudgeaAccount.where.not(encrypted_access_token: nil)
    list_retriever_budgea = []
    body_csv_normal       = []
    body_csv_failed       = []
    body_csv_bug          = []

    accounts.each do |account|
      access_token   = account.access_token
      account_active = account.user.active?

      response       = Budgea::Client.new(access_token).get_all_connections

      begin
        json_content = response.with_indifferent_access
      rescue
        next
      end

      next if json_content['connections'].nil?

      json_content['connections'].each do |connection|
        id_connection        = connection['id']
        error_message_budgea = connection['error_message']
        active_budgea        = connection['active']
        id_connector_budgea  = connection['id_connector']
        budgea_state         = connection['state']
        id_user              = connection['id_user']

        list_retriever_budgea << id_connection

        retriever = Retriever.where(budgea_id: id_connection)

        if retriever.present?
          state             = retriever.first.state
          retriever_state   = retriever.first.budgea_state
          retriever_message = retriever.first.budgea_error_message

          body_csv_normal << [account.user.code, account_active, retriever.first.name, retriever.first.journal_name, account.identifier, access_token, state, retriever_message, retriever.first.service_name, retriever_state, budgea_state, id_connector_budgea, error_message_budgea, 'response.status', id_connection, id_user]

        else
          body_csv_failed << [account.user.code, account_active, '', '', account.identifier, access_token, '', '', '', '', budgea_state, id_connector_budgea, error_message_budgea, 'response.status', id_connection, id_user]
        end
      end

    end
    list_retriever_budgea.uniq! if list_retriever_budgea.any?

    body_csv_bug = verify_retriever_idocus_and_not_at_budgea_with list_retriever_budgea if list_retriever_budgea.any?

    if export_type == 'data'
      for_export(body_csv_normal, body_csv_failed, body_csv_bug)
    elsif export_type == 'file'
      file = File.open(Rails.root.join('files', 'retrievers_export.xls'), 'w')
      file.write for_export(body_csv_normal, body_csv_failed, body_csv_bug).to_s.force_encoding('UTF-8')
      file.close
    else
      { normal: body_csv_normal, failed: body_csv_failed, bug: body_csv_bug }
    end
  end

  def for_users
    users_list_for_deleting     = []
    retriever_list_for_deleting = []
    budgea_id_list              = []

    all_ = Budgea::Client.new.get_all_users

    all_['users'].last(5).each do |user|
      account = BudgeaAccount.where(user_id: user['id']).first

      if account
        list_connections_budgea = get_list_connections_budgea_by account.access_token if account.access_token

        if list_connections_budgea.present?
          list_connections_budgea_ids = list_connections_budgea['connections'].map { |connections_budgea| connections_budgea['id'] }

          list_retrievers = Retriever.where(budgea_id: list_connections_budgea_ids).collect(&:budgea_id)

          verif_retrievers = list_connections_budgea['connections'].reject { |budgea| list_retrievers.include?(budgea['id']) }

          if verif_retrievers.count > 0
            users_list_for_deleting << user
            retriever_list_for_deleting << verif_retrievers
          end        
        else
          
          if need_to_renew_token_of(user['id'])
            response = Budgea::Client.new.renew_access_token(user['id'])

            list_retrievers = get_list_connections_budgea_by(response['jwt_token'])
            users_list_for_deleting << user.merge({ "access_token" => response['jwt_token']})
          else
            list_retrievers = get_list_retriever_of user['id']
          end

          retriever_list_for_deleting << list_retrievers
        end
      end
    end

    add_to_user_budgea_not_present_idocus(users_list_for_deleting.flatten)
    add_to_retriever_budgea_not_present_idocus(retriever_list_for_deleting.flatten)

    user_export(users_list_for_deleting, retriever_list_for_deleting)
  end

  private

  def get_list_connections_budgea_by(token)
    list_connections_budgea = []

    response = Budgea::Client.new(token).get_all_connections.try(:with_indifferent_access)

    response['connections'].each { |connection| list_connections_budgea << connection } if response['total'].present? && response['total'] > 0

    list_connections_budgea.flatten
  end

  def add_to_retriever_budgea_not_present_idocus(list_retrievers)
    list_retrievers.each do  |retriever|
      next if retriever.nil?

      backup_retriever = Archive::Retriever.new
      backup_retriever.assign_attributes(budgea_retriever)
      backup_retriever.save
    end
  end

  def add_to_user_budgea_not_present_idocus(users)
    users.each do |budgea_user|
      new_user = Archive::BudgeaUser.new
      new_user.assign_attributes(budgea_user)
      new_user.save
    end
  end

  def need_to_renew_token_of(user_id)
    Archive::BudgeaUser.has_token.where(id: user_id).count == 0
  end

  def get_list_retriever_of(user_id)
    list_retrievers = []

    list_retrievers << Retriever.where(user_id: user_id).collect(&:id)
    list_retrievers << Archive::Retriever.where(id_user: user_id).collect(&:id)

    list_retrievers
  end

  def for_export(body_csv_normal, body_csv_failed, body_csv_bug)
    book = Spreadsheet::Workbook.new

    sheet1 = book.create_worksheet name: 'Normal'
    sheet2 = book.create_worksheet name: 'Failed'
    sheet3 = book.create_worksheet name: 'Bug'

    headers = []
    headers += ['User code', 'Active?', 'Nom retriever', 'Journal retriever', 'Identifier', 'Access token', 'Etat', 'Etat retriever', 'Service name', 'Message retriever', 'Etat budgea', 'Id connecteur Budgea', 'Message erreur budgea', 'Code reponse','ID connection', 'User ID' ]

    insert_book(headers, sheet1, body_csv_normal)
    insert_book(headers, sheet2, body_csv_failed)
    insert_book(headers, sheet3, body_csv_bug)

    io = StringIO.new('')
    book.write(io)
    io.string
  end

  def user_export(users, retrievers)
    book = Spreadsheet::Workbook.new

    sheet1 = book.create_worksheet name: 'Utilisateurs non idocus'
    sheet2 = book.create_worksheet name: 'Retrievers'

    headers_users = []
    headers_users += ['ID', 'Date', 'platform', 'Access Token']

    insert_book(headers_users, sheet1, users)

    headers_retrievers = []
    headers_retrievers += []

    insert_book(headers_retrievers, sheet2, retrievers)

    io = StringIO.new('')
    book.write(io)
    io.string
  end

  def insert_book(headers, sheet, body_csv)
    sheet.row(0).concat headers

    body_csv.each_with_index do |data, index|
      sheet.row(index + 1).replace(data)
    end
  end

  def verify_retriever_idocus_and_not_at_budgea_with(list_retriever_budgea)
    retrievers = Retriever.where.not(budgea_id: list_retriever_budgea)
    body_csv   = []

    if retrievers
      retrievers.each do |retriever|
        state             = retriever.state
        retriever_state   = retriever.budgea_state
        retriever_message = retriever.budgea_error_message

        body_csv << [retriever.user.code, retriever.user.active?, retriever.name, retriever.journal_name, '', '', retriever.state, retriever.budgea_error_message, retriever.service_name, retriever.budgea_state, '', '', '', '',  '', '']
      end
    end

    body_csv
  end
end