# -*- encoding : UTF-8 -*-
class BudgeaArchiveFetcher
  class <<  self
    def execute
      new.execute
    end

    def to_csv
      book = Spreadsheet::Workbook.new

      sheet1 = book.create_worksheet name: 'Comptes'
      sheet2 = book.create_worksheet name: 'Automates'

      accounts_headers  = ['Identifier', 'Code idocus', 'Signin', 'Nombre automates', 'Access token']
      accounts_body     = []

      retrievers_headers = ['Budgea ID', 'User ID', 'ID iDocus', 'Active', 'Créé le', 'Modifié le', 'Etat Budgea', 'Etat idocus', 'Error', 'Push', 'log']
      retrievers_body    = []

      Archive::BudgeaUser.all.each do |account|
        connections = account.archive_retrievers
        accounts_body << [account.identifier, account.stored_account.try(:user).try(:code), account.signin, connections.size, account.access_token]

        connections.each do |connection|
          retrievers_body << [
                              connection.budgea_id,
                              connection.owner.identifier,
                              connection.stored_retriever.try(:id),
                              connection.active,
                              connection.created,
                              connection.last_update,
                              connection.state,
                              connection.stored_retriever.try(:budgea_error_message),
                              (connection.error || connection.error_message),
                              connection.last_push,
                              connection.log
                            ]
        end
      end

      insert_book(accounts_headers, sheet1, accounts_body)
      insert_book(retrievers_headers, sheet2, retrievers_body)

      book.write(Rails.root.join('files', 'budgea_archive.xls'))
    end

    def insert_book(headers, sheet, body_csv)
      sheet.row(0).concat headers

      body_csv.each_with_index do |data, index|
        sheet.row(index + 1).replace(data)
      end
    end
  end

  def execute
    @clients = {}
    sleep_counter = 0

    all_users.each do |account|
      sleep_counter += 1

      user = archive_user(account)

      next unless user.access_token.present?

      get_all_connections_of(user).each do |conx|
        connection = archive_connection(conx, user)
      end

      sleep 6 if (sleep_counter % 7) == 0
    end
  end

  private

  def all_users
    client.get_all_users['users']
  end

  def archive_user(account)
    exist_user = BudgeaAccount.where(identifier: account['id']).first
    
    ach_user              = Archive::BudgeaUser.where(identifier: account['id']).first || Archive::BudgeaUser.new
    ach_user.identifier   = account['id']
    ach_user.access_token = ach_user.try(:access_token) || exist_user.try(:access_token) || jwt_token_of(account, exist_user)
    ach_user.signin       = account['signin']
    ach_user.platform     = account['platform']
    ach_user.exist        = exist_user.present?

    ach_user.save

    ach_user
  end

  def archive_connection(conx, user)
    exist_retriever = Retriever.where(budgea_id: conx['id']).first

    ach_retriever               = Archive::Retriever.where(budgea_id: conx['id']).first || Archive::Retriever.new
    ach_retriever.owner_id      = user.id
    ach_retriever.budgea_id     = conx['id']
    ach_retriever.id_connector  = conx['id_connector']
    ach_retriever.state         = conx['state']
    ach_retriever.error         = conx['error']
    ach_retriever.error_message = conx['error_message']
    ach_retriever.last_update   = conx['last_update']
    ach_retriever.created       = conx['created']
    ach_retriever.active        = conx['active']
    ach_retriever.last_push     = conx['last_push']
    ach_retriever.expire        = conx['expire']
    ach_retriever.log           = conx['log']
    ach_retriever.exist         = exist_retriever.present?

    ach_retriever.save

    ach_retriever
  end

  def get_all_connections_of(user)
    client(user.access_token).get_all_connections['connections']
  end

  def jwt_token_of(account, exist_user=nil)
    return nil if exist_user.present?

    client.renew_access_token(account['id'])['jwt_token']
  end

  def client(access_token='super')
    return @clients[access_token.to_s] if @clients[access_token.to_s].present?

    @clients[access_token.to_s] = Budgea::Client.new(access_token.to_s)
  end
end
