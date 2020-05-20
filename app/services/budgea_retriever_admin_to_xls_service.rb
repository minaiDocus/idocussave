# -*- encoding : UTF-8 -*-

class BudgeaRetrieverAdminToXlsService
  def execute(export_csv=false)
    accounts              = BudgeaAccount.where.not(encrypted_access_token: nil)
    list_retriever_budgea = []
    body_csv_normal       = []
    body_csv_failed       = []
    body_csv_bug          = []

    accounts.each do |account|
      access_token   = account.access_token
      account_active = account.user.active?

      response       = Budgea::Client.new(access_token).get_all_connections

      json_content   = JSON.parse(response.body)

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

          body_csv_normal << [account.user.code, account_active, retriever.first.name, retriever.first.journal_name, account.identifier, access_token, state, retriever_message, retriever.first.service_name, retriever_state, budgea_state, id_connector_budgea, error_message_budgea, response.status, id_connection, id_user]

        else
          body_csv_failed << [account.user.code, account_active, '', '', account.identifier, access_token, '', '', '', '', budgea_state, id_connector_budgea, error_message_budgea, response.status, id_connection, id_user]
        end
      end

    end

    list_retriever_budgea.uniq! if list_retriever_budgea.any?

    body_csv_bug = verify_retriever_idocus_and_not_at_budgea_with list_retriever_budgea if list_retriever_budgea.any?

    if export_csv
      for_export(body_csv_normal, body_csv_failed, body_csv_bug)
    else
      { normal: body_csv_normal, failed: body_csv_failed, bug: body_csv_bug }
    end
  end

  private

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