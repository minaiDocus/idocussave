class PonctualScripts::BudgeaDeleteConnections < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    @users      = []
    @retrievers = []

    delete_retrievers_budgea #IMPORTANT : deletion of retrievers must be done before deletion of users

    sleep(10) #Wait 10 second before processing user deletion (just in case)

    delete_users_budgea

    send_notification
  end

  def delete_users_budgea
    users = Archive::BudgeaUser.not_exist.not_deleted

    users.each do |user|
      if user.access_token.present? && client(user.access_token).destroy_user
        user.is_deleted   = true
        user.deleted_date = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        user.save

        @users << user.reload
      end
    end
  end

  def delete_retrievers_budgea
    retrievers = Archive::Retriever.not_exist.not_deleted

    retrievers.each do |retriever|
      if retriever.owner.access_token.present? && client(retriever.owner.access_token).delete_connection(retriever.budgea_id)
        retriever.is_deleted   = true
        retriever.deleted_date = Time.now.strftime('%Y-%m-%d %H:%M:%S')
        retriever.save

        @retrievers << retriever.reload
      end
    end
  end

  def client(access_token)
    Budgea::Client.new(access_token.to_s)
  end

  def send_notification
    raw_users = "Users : <br/><table style='border: 1px solid #CCC;font-family: \"Open Sans\", sans-serif; font-size:12px;'>"
      raw_users += "<tr>"
      raw_users += "<th>id</th>"
      raw_users += "<th>identifier</th>"
      raw_users += "<th>signin</th>"
      raw_users += "<td>platform</th>"
      raw_users += "<th>access_token</th>"
      raw_users += "<th>exist</th>"
      raw_users += "<th>is_updated</th>"
      raw_users += "<th>is_deleted</th>"
      raw_users += "<th>deleted_date</th>"
      raw_users += "</tr><tbody>"

    @users.each do |user|
      raw_users += "<tr>"

        raw_users += "<td>#{user.id}</td>"
        raw_users += "<td>#{user.identifier}</td>"
        raw_users += "<td>#{user.signin}</td>"
        raw_users += "<td>#{user.platform}</td>"
        raw_users += "<td>#{user.access_token}</td>"
        raw_users += "<td>#{user.exist}</td>"
        raw_users += "<td>#{user.is_updated}</td>"
        raw_users += "<td>#{user.is_deleted}</td>"
        raw_users += "<td>#{user.deleted_date}</td>"

      raw_users += "</tr>"
    end

    raw_users += "</tbody></table>"

    raw_retrievers = "Retrievers : <br/><table style='border: 1px solid #CCC;font-family: \"Open Sans\", sans-serif; font-size:12px;'>"

      raw_retrievers += "<tr>"
      raw_users += "<th>id</th>"
      raw_users += "<th>owner_id</th>"
      raw_users += "<th>budgea_id</th>"
      raw_users += "<th>id_connector</th>"
      raw_users += "<th>state</th>"
      raw_users += "<th>error</th>"
      raw_users += "<th>error_message</th>"
      raw_users += "<th>last_update</th>"
      raw_users += "<th>created</th>"
      raw_users += "<th>active</th>"
      raw_users += "<th>last_push</th>"
      raw_users += "<th>next_try</th>"
      raw_users += "<th>expire</th>"
      raw_users += "<th>log</th>"
      raw_users += "<th>exist</th>"
      raw_users += "<th>is_updated</th>"
      raw_users += "<th>is_deleted</th>"
      raw_users += "<th>deleted_date</th>"

      raw_retrievers += "</tr><tbody>"

    @retrievers.each do |retriever|
      raw_retrievers += "<tr>"

      raw_retrievers += "<td>#{retriever.id}</td>"
      raw_retrievers += "<td>#{retriever.owner_id}</td>"
      raw_retrievers += "<td>#{retriever.budgea_id}</td>"
      raw_retrievers += "<td>#{retriever.id_connector}</td>"
      raw_retrievers += "<td>#{retriever.state}</td>"
      raw_retrievers += "<td>#{retriever.error}</td>"
      raw_retrievers += "<td>#{retriever.error_message}</td>"
      raw_retrievers += "<td>#{retriever.last_update}</td>"
      raw_retrievers += "<td>#{retriever.created}</td>"
      raw_retrievers += "<td>#{retriever.active}</td>"
      raw_retrievers += "<td>#{retriever.last_push}</td>"
      raw_retrievers += "<td>#{retriever.next_try}</td>"
      raw_retrievers += "<td>#{retriever.expire}</td>"
      raw_retrievers += "<td>#{retriever.log}</td>"
      raw_retrievers += "<td>#{retriever.exist}</td>"
      raw_retrievers += "<td>#{retriever.is_updated}</td>"
      raw_retrievers += "<td>#{retriever.is_deleted}</td>"
      raw_retrievers += "<td>#{retriever.deleted_date}</td>"

      raw_retrievers += "</tr>"
    end

    raw_retrievers += "</tbody></table>"

    log_document = {
      subject: "[PonctualScripts::BudgeaDeleteConnections] suppression users/connections budgea",
      name: "PonctualScripts::BudgeaDeleteConnections",
      error_group: "[Ponctual Script] : Suppression Users/Connections Budgea",
      erreur_type: "Suppression Users/Connections Budgea",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      raw_information: raw_users + "<br/>" + raw_retrievers
    }

    ErrorScriptMailer.error_notification(log_document).deliver
  end
end