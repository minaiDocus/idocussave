class NeobeApi
  include Savon::Model
  
  endpoint "https://api.neobe.com:443/soap_srv.php?key=#{NEOBE_KEY}"
  namespace "urn:ApiWsdl"
  
  METHOD_LIST = [
                              "get_list_account()",
                              "get_all_space()",
                              "get_all_used_space()",
                              
                              "add_account(space, recipient, password, expiration, unlocker, local, dd)",
                              "delete_account(account_number)",
                              "delete_id_machine(account_number)",
                              "clean_account(account_number)",

                              "get_login(account_number)",
                              "get_password(account_number)",
                              "get_comment(account_number)",
                              "get_etat(account_number)",
                              "get_last_saving(account_number)",
                              "get_used_space(account_number)",
                              "get_delay_of_last_activity(account_number)",
                              "get_exp(account_number)",
                              "get_exp_f(account_number)",
                              "get_id_machine(account_number)",
                              "get_nb_files(account_number)",
                              "get_nb_files_max(account_number)",
                              "get_pack(account_number)",
                              "is_dd(account_number)",
                              "is_local(account_number)",
                              "is_multi(account_number)",
                              "is_unlocker(account_number)",

                              "set_password(account_number, password)",
                              "set_comment(account_number, comment)",
                              "set_etat(account_number, etat)",
                              "set_space(account_number, space)",
                              "set_date(account_number, date)",
                              "set_date_f(account_number, date)",
                              "set_pack(account_number, pack)",
                              "set_dd(account_number, flag)",
                              "set_local(account_number, flag)",
                              "set_multi(account_number, flag)",
                              "set_unlocker(account_number, flag)",                              
                            ]
                            
  STATE =   [
                    ["Active","AC"],
                    ["Disabled","DE"],
                    ["Deleting scheduled","EP"]
                  ]
  
  class << self
  
  private
  
    def valid_account_number account_number
      unless account_number.to_i.to_s.length == 5
        false
      else
        account_number.to_s
      end
    end
    
    # requête générique
    def request service, options=[]
      if service.is_a? String
        service_camelcase = "#{service.split[0]}#{service.split[1..-1].map(&:capitalize).join}Api"
        service_symbole = "#{service.gsub(/\s+/,"_")}_api"
      elsif service.is_a? Symbol
        service_camelcase = "#{service.to_s.split('_')[0]}#{service.to_s.split('_')[1..-1].map(&:capitalize).join}Api"
        service_symbole = "#{service.to_s}_api"
      else
        raise TypeError, 'You must give a string or a symbol, like "get list account" or :get_list_account'
      end
      response = client.request :urn, service_camelcase do
        soap.xml do |xml|
          xml.tag! "soapenv:Envelope", "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema", "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/", "xmlns:urn" => service_camelcase do
            xml.tag! "soapenv:Header"
            xml.tag! "soapenv:Body" do
              if options.empty?
                xml.tag! "urn:#{service_camelcase}", "soapenv:encodingStyle" => "http://schemas.xmlsoap.org/soap/encoding/"
              else
                xml.tag! "urn:#{service_camelcase}", "soapenv:encodingStyle" => "http://schemas.xmlsoap.org/soap/encoding/" do
                  options.each do |option|
                    xml.tag! option[:name], "xsi:type" => "xsd:#{option[:type]}" do
                      xml.text! option[:value]
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  
  public
    
    # méthode global
    
    def get_list_account
      request(:get_list_account).to_array(:get_list_account_api_response, :return).first[:item]
    end
    
    def get_all_space
      request(:get_all_space).to_array(:get_all_space_api_response, :return).first
    end
    
    def get_all_used_space
      request(:get_all_used_space).to_array(:get_all_used_space_api_response, :return).first rescue "Error"
    end
    
    ### getteur ###
    
    def get_login account_number
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:get_login, options).to_array(:get_login_api_response, :return).first
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def get_password account_number
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:get_password, options).to_array(:get_password_api_response, :return).first
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def get_comment account_number
      response = {}
      if account_number = valid_account_number(account_number)
      options = [{ :name => "account", :type => "int", :value => account_number }]
      res = request(:get_comment, options).to_array(:get_comment_api_response, :return).first
      res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def get_etat account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:get_etat, options).to_array(:get_etat_api_response, :return).first
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def get_last_saving account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:get_last_saving, options).to_array(:get_last_saving_api_response, :return).first
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def get_space account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:get_space, options).to_array(:get_space_api_response, :return).first
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def get_used_space account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:get_used_space, options).to_array(:get_used_space_api_response, :return).first
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def get_delay_of_last_activity account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:get_delay_of_last_activity, options).to_array(:get_delay_of_last_activity_api_response, :return).first
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def get_exp account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:get_exp, options).to_array(:get_exp_api_response, :return).first
        res == "0000-00-00" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def get_exp_f account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:get_exp_f, options).to_array(:get_exp_f_api_response, :return).first
        res == "0000-00-00" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def get_id_machine account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:get_id_machine, options).to_array(:get_id_machine_api_response, :return).first
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def get_nb_files account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:get_nb_files, options).to_array(:get_nb_files_api_response, :return).first
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def get_nb_files_max account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:get_nb_files_max, options).to_array(:get_nb_files_max_api_response, :return).first
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def get_pack account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:get_pack, options).to_array(:get_pack_api_response, :return).first
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def is_dd account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        response[:success] = true
        res = request(:is_dd, options).to_array(:is_dd_api_response)[0][:return]
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def is_local account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:is_local, options).to_array(:is_local_api_response)[0][:return]
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def is_multi account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:is_multi, options).to_array(:is_multi_api_response)[0][:return]
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def is_unlocker account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        res = request(:is_unlocker, options).to_array(:is_unlocker_api_response)[0][:return]
        res == "error" ? { :success => false, :value => ""} : { :success => true, :value => res}        
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    ### setter ###
    
    # méthode spécifique
    
    def add_account space, recipient, password, expiration, unlocker=false, local=true, dd=false
      response = {}
      if space.is_a?(Integer) && recipient.is_a?(String) && !recipient.blank? && password.is_a?(String) && !password.blank? && expiration.match(/20\d{2}-(0\d|1[012])-([012]\d|3[01])/)
        space = space.to_s
        unlocker = unlocker.is_a?(Boolean) ? unlocker.to_s : "false"
        local = local.is_a?(Boolean) ? local.to_s : "true"
        dd = dd.is_a?(Boolean) ? dd.to_s : "false"
        options = []
        
        options << { :name => "space", :type => "int", :value => space }
        options << { :name => "recipient", :type => "string", :value => recipient }
        options << { :name => "password", :type => "string", :value => password }
        options << { :name => "expiration", :type => "date", :value => expiration }
        options << { :name => "unlocker", :type => "boolean", :value => unlocker }
        options << { :name => "local", :type => "boolean", :value => local }
        options << { :name => "dd", :type => "boolean", :value => dd }
        
        begin
          res = request(:add_account, options)
          response[:success] = true
          response[:value] = res.to_array(:add_account_api_response, :return).first.to_i
          response
        rescue
          response[:success] = false
          response[:value] = res
          response
        end
      else
        response[:success] = false
        response[:value] = "Invalid parameter"
        response
      end
    end
    
    def delete_account account_number
      response = {}
      if account_number = valid_account_number(account_number)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        begin
          res = request(:delete_account, options)
          response[:success] = true
          response[:value] = res.to_array(:delete_account_api_response, :return).first
          response
        rescue
          response[:success] = false
          response[:value] = res
          response
        end
      else
        response[:success] = false
        response[:value] = "Invalid parameter"
        response
      end
    end
    
    def delete_id_machine account_number
      response = {}
      options = [{ :name => "account", :type => "int", :value => account_number }]
      begin
        res = request(:delete_id_machine, options)
        response[:success] = true
        response[:value] = res.to_array(:delete_id_machine_api_response, :return).first
        response
      rescue
        response[:success] = false
        response[:value] = res
        response
    end
    end
    
    def clean_account account_number
      response = {}
      options = [{ :name => "account", :type => "int", :value => account_number }]
      begin
        res = request(:clean_account, options)
        response[:success] = true
        response[:value] = res.to_array(:clean_account_api_response, :return).first
        response
      rescue
        response[:success] = false
        response[:value] = res
        response
      end
    end
    
    def set_password account_number, password
      response = {}
      if((account_number = valid_account_number(account_number)) && password.to_s.length >= 4)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        options << { :name => "password", :type => "string", :value => password.to_s }
        begin
          res = request(:set_password, options).to_array(:set_password_api_response, :return).first
          res == false ? { :success => false, :value => "not updated"} : { :success => true, :value => "updated"}
        rescue
          { :success => false, :value => res}
        end
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def set_comment account_number, comment
      response = {}
      if((account_number = valid_account_number(account_number)) && !comment.blank?)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        options << { :name => "comment", :type => "string", :value => comment.to_s }
        begin
          res = request(:set_comment, options).to_array(:set_comment_api_response, :return).first
          res == false ? { :success => false, :value => "not updated"} : { :success => true, :value => "updated"}
        rescue
          { :success => false, :value => res}
        end
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def set_space account_number, space
      response = {}
      if((account_number = valid_account_number(account_number)) && space.to_i > 0 )
        options = [{ :name => "account", :type => "int", :value => account_number }]
        options << { :name => "space", :type => "int", :value => space.to_s }
        begin
          res = request(:set_space, options).to_array(:set_space_api_response, :return).first
          res == false ? { :success => false, :value => "not updated"} : { :success => true, :value => "updated"}
        rescue
          { :success => false, :value => res}
        end
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def set_etat account_number, etat
      response = {}
      if((account_number = valid_account_number(account_number)) && ((etat == "AC") || (etat == "DE") || (etat == "EP")))
        options = [{ :name => "account", :type => "int", :value => account_number }]
        options << { :name => "etat", :type => "string", :value => etat }
        begin
          res = request(:set_etat, options).to_array(:set_etat_api_response, :return).first
          res == false ? { :success => false, :value => "not updated"} : { :success => true, :value => "updated"}
        rescue
          { :success => false, :value => res}
        end
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def set_date account_number, date
      response = {}
      if((account_number = valid_account_number(account_number)) && date.match(/20\d{2}-(0\d|1[012])-([012]\d|3[01])/))
        options = [{ :name => "account", :type => "int", :value => account_number }]
        options << { :name => "date", :type => "date", :value => date }
        begin
          res = request(:set_date, options).to_array(:set_date_api_response, :return).first
          res == false ? { :success => false, :value => "not updated"} : { :success => true, :value => "updated"}
        rescue
          { :success => false, :value => res}
        end
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def set_date_f account_number, date
      response = {}
      if((account_number = valid_account_number(account_number)) && date.match(/20\d{2}-(0\d|1[012])-([012]\d|3[01])/))
        options = [{ :name => "account", :type => "int", :value => account_number }]
        options << { :name => "date", :type => "date", :value => date }
        begin
          res = request(:set_date_f, options).to_array(:set_date_f_api_response, :return).first
          res == false ? { :success => false, :value => "not updated"} : { :success => true, :value => "updated"}
        rescue
          { :success => false, :value => res}
        end
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def set_pack account_number, pack
      response = {}
      if((account_number = valid_account_number(account_number)) && !pack.blank?)
        options = [{ :name => "account", :type => "int", :value => account_number }]
        options << { :name => "pack", :type => "int", :value => pack }
        begin
          res = request(:set_pack, options).to_array(:set_pack_api_response, :return).first
          res == false ? { :success => false, :value => "not updated"} : { :success => true, :value => "updated"}
        rescue
          { :success => false, :value => res}
        end
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def set_dd account_number, flag
      response = {}
      if((account_number = valid_account_number(account_number)) && (flag.to_s == "false" || flag.to_s == "true"))
        options = [{ :name => "account", :type => "int", :value => account_number }]
        options << { :name => "flag", :type => "boolean", :value => flag.to_s }
        begin
          res = request(:set_dd, options).to_array(:set_dd_api_response, :return).first
          res == false ? { :success => false, :value => "not updated"} : { :success => true, :value => "updated"}
        rescue
          { :success => false, :value => res}
        end
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def set_local account_number, flag
      response = {}
      if((account_number = valid_account_number(account_number)) && (flag.to_s == "false" || flag.to_s == "true"))
        options = [{ :name => "account", :type => "int", :value => account_number }]
        options << { :name => "flag", :type => "boolean", :value => flag.to_s }
        begin
          res = request(:set_local, options).to_array(:set_local_api_response, :return).first
          res == false ? { :success => false, :value => "not updated"} : { :success => true, :value => "updated"}
        rescue
          { :success => false, :value => res}
        end
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def set_multi account_number, flag
      response = {}
      if((account_number = valid_account_number(account_number)) && (flag.to_s == "false" || flag.to_s == "true"))
        options = [{ :name => "account", :type => "int", :value => account_number }]
        options << { :name => "flag", :type => "boolean", :value => flag.to_s }
        begin
          res = request(:set_multi, options).to_array(:set_multi_api_response, :return).first
          res == false ? { :success => false, :value => "not updated"} : { :success => true, :value => "updated"}
        rescue
          { :success => false, :value => res}
        end
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
    def set_unlocker account_number, flag
      response = {}
      if((account_number = valid_account_number(account_number)) && (flag.to_s == "false" || flag.to_s == "true"))
        options = [{ :name => "account", :type => "int", :value => account_number }]
        options << { :name => "flag", :type => "boolean", :value => flag.to_s }
        begin
          res = request(:set_unlocker, options).to_array(:set_unlocker_api_response, :return).first
          res == false ? { :success => false, :value => "not updated"} : { :success => true, :value => "updated"}
        rescue
          { :success => false, :value => res}
        end
      else
        { :success => false, :value => "Invalid parameter"}
      end
    end
    
  end
  
end