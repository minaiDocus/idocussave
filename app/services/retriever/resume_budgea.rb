# -*- encoding : UTF-8 -*-
class Retriever::ResumeBudgea
  def execute
    retrievers = Retriever.where("updated_at < ?", 30.minutes.ago)

    @infos = []

    retrievers.each do |retriever|
      access_token = retriever.user.try(:budgea_account).try(:access_token)

      next unless retriever.user.still_active? && access_token.present? && retriever.budgea_id.present?

      initial_message = retriever.error_message

      begin
        result = retriever.resume_me

        sleep(3)

        final_message = retriever.reload.error_message

        @infos << info(retriever, initial_message, final_message, result.try(:[], :from)) if final_message != initial_message
      rescue => e
        @infos << info(retriever, initial_message, e.to_s)
      end
    end

    send_notification
  end

  private

  def info(retriever, initial_message, final_message, updated_by=nil)
    {
      retriever_id: retriever.id,
      budgea_id: retriever.budgea_id,
      user_code: retriever.user.code,
      state: retriever.state,
      budgea_state: retriever.budgea_state,
      initial_message: initial_message,
      final_message: final_message,
      budgea_error_message: retriever.budgea_error_message,
      service_name: retriever.service_name,
      updated_by: updated_by,
      created_at: retriever.created_at,
      updated_at: retriever.updated_at
    }
  end


  def send_notification
    raw_retriever = "<br/><table border='1px' style='border-collapse: collapse;border: 1px solid #CCC;font-family: \"Open Sans\", sans-serif; font-size:12px;'>"
      raw_retriever += "<tr>"
      raw_retriever += "<th>id</th>"
      raw_retriever += "<th>budgea_id</th>"
      raw_retriever += "<th>user_code</th>"
      raw_retriever += "<th>state</th>"
      raw_retriever += "<th>budgea_state</th>"
      raw_retriever += "<th>initial_message</th>"
      raw_retriever += "<th>final_message</th>"
      raw_retriever += "<th>budgea_error_message</th>"
      raw_retriever += "<th>service_name</th>"
      raw_retriever += "<th>updated_by</th>"
      raw_retriever += "<th>created_at</th>"
      raw_retriever += "<th>updated_at</th>"
      raw_retriever += "</tr><tbody>"

    @infos.each do |_info|
      raw_retriever += "<tr>"

        raw_retriever += "<td>#{_info[:retriever_id]}</td>"
        raw_retriever += "<td>#{_info[:budgea_id]}</td>"
        raw_retriever += "<td>#{_info[:user_code]}</td>"
        raw_retriever += "<td>#{_info[:state]}</td>"
        raw_retriever += "<td>#{_info[:budgea_state]}</td>"
        raw_retriever += "<td>#{_info[:initial_message]}</td>"
        raw_retriever += "<td>#{_info[:final_message]}</td>"
        raw_retriever += "<td>#{_info[:budgea_error_message]}</td>"
        raw_retriever += "<td>#{_info[:service_name]}</td>"
        raw_retriever += "<td>#{_info[:updated_by]}</td>"
        raw_retriever += "<td>#{_info[:created_at]}</td>"
        raw_retriever += "<td>#{_info[:updated_at]}</td>"

      raw_retriever += "</tr>"
    end

    raw_retriever += "</tbody></table>"

    log_info = {
      subject: "[Retriever::ResumeBudgea] with error message content",
      name: "ResumeBudgeaRetriever",
      error_group: "[resume-budgea-retriever] with error message content",
      erreur_type: "ResumeBudgeaRetriever with error message content",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      raw_information: raw_retriever
    }

    ErrorScriptMailer.error_notification(log_info).deliver
  end

end
