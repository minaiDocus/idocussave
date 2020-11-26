class Notifications::Firebase < Notifications::Notifier
  def initialize(arguments={})
    super
  end

  def send_firebase_notification
    send_message(@arguments[:notification].user, @arguments[:notification].title, @arguments[:notification].message, false)
  end

  def send_message(user, title="", message="", to_be_added=false)
    user.firebase_tokens.each do |token|
      if token.valid_token?
        payload = {
          "to": token.name,
          "notification": {
            "title": title,
            "body": message,
          },
          "data":{
            "title": title,
            "body": message,
            "to_be_added": to_be_added
          }
        }
        token.update_last_sending_date if send_request_fcm(payload)
      end
      token.delete_unless_valid
    end
  end

  def send_broadcast_message(title="", message="", to_be_added=false)
    payload = {
     "notification": {
        "title": title,
        "body": message,
      },
      "data":{
        "title": title,
        "body": message,
        "to_be_added": to_be_added
      }
    }

    send_request_fcm(payload)
  end

  private

  def send_request_fcm(payload)
    begin
      connection = Faraday.new(:url => api_uri) do |f|
        f.response :logger
        f.request :json
        f.adapter Faraday.default_adapter
      end

      response = connection.post do |request|
        request.headers = {
          'Content-type' => 'application/json',
          'Authorization' => basic_server_key
        }
        request.body = payload.to_json
      end

      p response
      true
    rescue Exception => e
      e.to_s
      false
    end
  end

  def api_uri
    Rails.application.credentials[Rails.env.to_sym][:firebase_api][:base_uri]
  end

  def basic_server_key
    Rails.application.credentials[Rails.env.to_sym][:firebase_api][:basic_server_key]
  end
end