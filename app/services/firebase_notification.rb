class FirebaseNotification
  class << self
    def send_notification(notification)
      send_message(notification.user, notification.title, notification.message, false)
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
                          "message":{
                              "title": title,
                              "body": message,
                              "to_be_added": to_be_added
                            }
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
                    "message":{
                                "title": title,
                                "body": message,
                                "to_be_added": to_be_added
                              }
                  }
                }
        send_request_fcm(payload)
    end

    private

    def send_request_fcm(payload)
      begin
        response = Typhoeus::Request.new(
          api_uri,
          method:  :post,
          headers:  { 
                      'Content-type' => 'application/json', 
                      'Authorization' => basic_server_key 
                    },
          body:  payload.to_json
        ).run
        true
      rescue Exception => e
        e.to_s
        false
      end
    end

    def api_uri
      Rails.application.secrets.firebase_api['base_uri']
    end

    def basic_server_key
      Rails.application.secrets.firebase_api['basic_server_key']
    end

  end
end