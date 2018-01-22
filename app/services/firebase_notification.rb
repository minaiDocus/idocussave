class FirebaseNotification
  class << self
    def fcm_send_notification(notification)
      fcm_send_message(notification.title, notification.message, notification.user, false)
    end

    def fcm_send_message(title="", message="", user=nil, to_be_added=false)
      tokens = user.firebase_tokens
      tokens.each do |token|
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

    def fcm_send_broadcast_message(title="", message="", to_be_added=false)
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
        header = {
                  'Content-type' => 'application/json', 
                  'Authorization' => basic_server_key
                 }
        uri = URI.parse(api_uri)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        req = Net::HTTP::Post.new(uri.path, header)
        req.body = payload.to_json
        res = https.request(req)
        true
      rescue Exception => e
        e.to_s
        false
      end
    end

    def api_uri
      'https://fcm.googleapis.com/fcm/send'
    end

    def basic_server_key
      'key=AAAA28lsVzI:APA91bGcBSq2NFkSKwzLaMmJSeYWn-FcUxgSY3AB9amMj4MGzJ7mjXIgEI2dcv2oilaKNriwcaS12UrC5VWifI-P-HUm7tCOmbZn9yagd1LrbnRu05nlyRccTA4VyDCoZfVZSD9S-ziI'
    end

  end
end