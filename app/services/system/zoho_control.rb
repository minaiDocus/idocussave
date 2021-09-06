# encoding: utf-8
class System::ZohoControl
  class << self
    def launch_test
      new().send_organizations('IDOC')
      sleep(7)
      new().send_collaborators('IDOC')
    end

    def send_one_organization(code)
      return false if code.blank?

      new().send_organizations(code)
      sleep(7)
      new().send_collaborators(code)
    end

    def send_organizations
      new().send_organizations
    end

    def send_collaborators
      new().send_collaborators
    end

    def generate_access_and_refresh_token_by(code)
      p new().generating_access_and_refresh_token(code)
    end
  end

  def initialize
    @organizations_count, @organizations_sent_with_success_count, @organizations_sent_with_errors_count, @organization_already_exist_count = 0, 0, 0, 0
    @users_count, @users_sent_with_success_count, @users_sent_with_errors_count, @users_already_exist_count = 0, 0, 0, 0
    reset_control
    @process_id   = DateTime.current.strftime("%Y%m%d_%H%M")
    @access_token = ZohoCrm::USER_TOKEN
  end

  def send_organizations(code='all')
    if code != 'all'
      organizations = Organization.where(code: code).select([:id, :name, :code, :description, :is_active, :is_suspended])
    else
      organizations = Organization.select([:id, :name, :code, :description, :is_active, :is_suspended])
    end

    @organizations_count = organizations.size
    organizations.each_slice(10) do |_organizations|
      process(_organizations)
    end

    options = {
      duplicated_key: "Account_Name",
      search_column:  "Code_iDocus",
      identifier_key: "Account_Number"
    }

    duplicated_data = search_duplicate_data("Accounts", options)

    mail_infos = {
      subject: "[System::ZohoControl] check duplicated organizations",
      name: "ZohoControl.send_organizations",
      error_group: "[zoho-control] check duplicated organizations",
      erreur_type: "Notifications",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: {
        organizations_info: { count: @organizations_count, success: @organizations_sent_with_success_count, errors: @organizations_sent_with_errors_count, exists: @organization_already_exist_count, inserted: @inserted, updated: @updated },
        title: (duplicated_data.count > 0 )? "#{duplicated_data.count} doublon(s) organisation(s) trouvée(s)" : "Aucun doublon detecté",
        duplicated_data: duplicated_data,
        message_content: @messages
      }
    }

    begin
      ErrorScriptMailer.error_notification(mail_infos, { attachements: [{name: File.basename(@data_type.report_file), file: File.read(@data_type.report_file)}] } ).deliver
    rescue
      ErrorScriptMailer.error_notification(mail_infos).deliver
    end
  end

  def send_collaborators(code='all')
    if code != 'all'
      users = Organization.where(code: code).first.collaborators
    else
      users = User.where(is_prescriber: true)
    end

    _memberships = []
    users.each do |user|
      member = user.memberships.first
      if member
        user.code = member.code
        user.organization_id = member.organization_id
        _memberships << user
      end
    end

    @users_count += _memberships.size
    _memberships.each_slice(10) { |_users| process(_users) }

    options = {
      duplicated_key: "Code_iDocus",
      search_column:  "Email",
      identifier_key: "Contact_Number"
    }

    duplicated_data = search_duplicate_data("Contacts", options)

    mail_infos = {
      subject: "[System::ZohoControl] check duplicated collaborators",
      name: "ZohoControl.send_collaborators",
      error_group: "[zoho-control] check duplicated collaborators",
      erreur_type: "Notifications",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: {
        users_info: { count: @users_count, success: @users_sent_with_success_count, errors: @users_sent_with_errors_count, exists: @users_already_exist_count, inserted: @inserted, updated: @updated },
        title: (duplicated_data.count > 0 )? "#{duplicated_data.count} doublon(s) contact(s) trouvé(s)" : "Aucun doublon detecté",
        duplicated_data: duplicated_data,
        message_content: @messages
      }
    }

    begin
      ErrorScriptMailer.error_notification(mail_infos, { attachements: [{name: File.basename(@data_type.report_file), file: File.read(@data_type.report_file)}] } ).deliver
    rescue
      ErrorScriptMailer.error_notification(mail_infos).deliver
    end
  end

  def generating_access_and_refresh_token(code)
    generate_access_and_refresh_token(code)
  end

  private

  def process(data)
    insert(data)
    count_report(data)
  end

  def reset_control
    @success_report, @error_report, @inserted, @updated, @messages = [], [], [], [], ""
    @success_count, @exist_count, @errors_count = 0, 0, 0
  end

  def insert(data)
    initialize_data_type(data.first)
    reset_control

    @json_content = create_json_format(data)

    p '============================================================================================='
    p @json_content
    p '============================================================================================='

    send_data_to_zoho

    @messages = "inject all" if @messages == ""

    fill_report_file(data)

    return @messages
  end

  def count_results
    { success: @success_count, errors: @errors_count, exists: @exist_count }
  end

  def result_of(object)
    retry_count = 0

    begin
      url = "#{@data_type.module_name}/search?criteria=#{@data_type.search_record_with_criteria(object)}"

      response = connection.get do |request|
        request.url url
        request.headers = headers
      end

      raise if response.status.to_i == 401 && retry_count <= 1
    rescue
      retry_count += 1
      @access_token = refresh_access_token
      retry
    end

    p '**********************************************************'
    p response.body
    p '***************************************************'

    return response.body["data"].first["id"] if response.status.to_i == 200 && response.body["data"].present? && response.body["data"].first["id"].present?
    nil
  end

  def get_record_by(id)
    retry_count = 0

    begin
      url = "#{@data_type.module_name}/#{id}"

      response = connection.get do |request|
        request.url url
        request.headers = headers
      end

      raise if response.status.to_i == 401 && retry_count <= 1
    rescue
      retry_count += 1
      @access_token = refresh_access_token
      retry
    end

    account_zoho_id, object_idocus_id = 0

    if response.status.to_i == 200 && response.body["data"].present?
      data_result = response.body["data"].first
      account_zoho_id = data_result["Account_Name"]["id"].to_i if data_result["Account_Name"].present? && data_result["Account_Name"]["id"].present?
      if data_result["Account_Number"].present?
        object_idocus_id = data_result["Account_Number"].to_i
      elsif data_result["Contact_Number"].present?
        object_idocus_id = data_result["Contact_Number"].to_i
      end
    end

    { account_zoho_id: account_zoho_id, object_idocus_id: object_idocus_id }
  end

  def count_report(data)
    if data.first.is_a?(User)
      @users_sent_with_success_count += count_results[:success]
      @users_already_exist_count += count_results[:exists]
      @users_sent_with_errors_count += count_results[:errors]
    else
      @organizations_sent_with_success_count += count_results[:success]
      @organization_already_exist_count += count_results[:exists]
      @organizations_sent_with_errors_count += count_results[:errors]
    end
  end

  def initialize_data_type(object_type)
    @data_type = (object_type.is_a? User) ? ContactZoho.new(@process_id) : AccountZoho.new(@process_id)
  end

  def decode_response(response, operation_type = 'insert')
    if response.status.in? [200, 201, 202, 204, 304, 400, 401, 403, 404, 405, 413, 415, 429, 500]
      if response.body["data"].present?
        response.body["data"].each do |result|
          if result["status"].to_s == "success"
            infos = get_record_by(result["details"]["id"])
            @success_report << { object_id: result["details"]["id"].to_i, response: result["message"], operation_type: operation_type, account_zoho_id: infos[:account_zoho_id].presence, object_idocus_id: infos[:object_idocus_id].presence }
            @success_count += 1
            @exist_count += 1 if operation_type == 'update'
          else
            @error_report << { object_id: result["details"]["id"].to_i, response: "#{result['message']} :: api_name => #{result['details']['api_name']}", operation_type: operation_type }
            @errors_count += 1
            @messages = "inject with error(s)"
          end
        end
      else
        @error_report << { object_id: 'All', response: response.body["message"], operation_type: operation_type }
        @errors_count += 1
        @messages = "inject with error(s)"
      end
    else
      @error_report << { object_id: 'All', response: "Unknown error with: #{response.status}", operation_type: operation_type }
      @errors_count += 1
      @messages = "inject with error(s)"
    end
  end

  def create_json_format(objects)
    insert_object, update_object = [], {}

    objects.each do |object|
      object_id = result_of(object)
      if object_id.to_i == 0
        insert_object << object
      elsif object_id.present? && object_id.to_i > 0
        update_object[object_id] = object
      else
        @error_report << { object_id: object.id, response: "JSON parse error", operation_type: 'search' }
        @errors_count += 1
      end
    end

    inserted  = @data_type.create_records(insert_object)
    updated   = @data_type.update_records(update_object)

    @inserted += inserted[:list]
    @updated  += updated[:list]

    { :insert => inserted[:json_content], :update => updated[:json_content] }
  end

  def send_data_to_zoho
    if @json_content[:insert].present?
      retry_count = 0

      begin
        response = connection.post do |request|
          request.url @data_type.module_name
          request.headers = headers
          request.body    = @json_content[:insert]
        end

        raise if response.status.to_i == 401 && retry_count <= 1
      rescue
        retry_count += 1
        @access_token = refresh_access_token
        retry
      end

      decode_response(response, 'insert')
    end

    if @json_content[:update].present?
      retry_count = 0

      begin
        response = connection.put do |request|
          request.url @data_type.module_name
          request.headers = headers
          request.body    = @json_content[:update]
        end

        raise if response.status.to_i == 401 && retry_count <= 1
      rescue
        retry_count += 1
        @access_token = refresh_access_token
        retry
      end

      decode_response(response, 'update')
    end
  end

  def fill_report_file(objects)
    @data_type.fill_report_file({reports: (@success_report + @error_report), objects: objects})
  end

  def generate_access_and_refresh_token(code=ZohoCrm::CODE)
    response = connection(ZohoCrm::REFRESH_TOKEN_URL).post do |request|
      request.url '/oauth/v2/token'
      # request.headers = headers
      request.body  = {grant_type: 'authorization_code', client_id: ZohoCrm::CLIENT_ID, client_secret: ZohoCrm::CLIENT_SECRET, redirect_uri: ZohoCrm::REDIRECT_URI, code: code}
    end

    return "invalid code: #{code}, reset and login with the zoho credentials(Email Address or mobile number)" if response && response.body['error'].present? && response.body['error'] == "invalid_code"

    {access_token: response.body['access_token'], refresh_token: response.body['refresh_token']}
  end

  def refresh_access_token
    response = connection(ZohoCrm::REFRESH_TOKEN_URL).post do |request|
      request.url '/oauth/v2/token'
      request.headers = headers
      request.params  = {refresh_token: ZohoCrm::REFRESH_TOKEN, client_id: ZohoCrm::CLIENT_ID, client_secret: ZohoCrm::CLIENT_SECRET, grant_type: ZohoCrm::GRANT_TYPE}
    end

    @access_token = response.body['access_token']
    return @access_token
  end

  def connection(base_url=ZohoCrm::BASE_URI)
    Faraday.new(:url => base_url) do |f|
      f.response :logger
      f.request :oauth2, 'token', token_type: :bearer
      f.request :url_encoded
      f.request :json
      f.adapter Faraday.default_adapter
      f.response :json, content_type: /\bjson$/
    end
  end

  def headers
    @headers = {
      authorization: "Zoho-oauthtoken #{@access_token}",
      'Accept' => 'application/json',
      'Content-type' => 'application/json'
    }
  end

  def search_duplicate_data(module_name, options={})
    duplicated_data = {}
    store_results   = {}
    duplicated_key  = options[:duplicated_key]
    search_column   = options[:search_column]
    identifier_key  = options[:identifier_key]

    retry_count = 0

    begin
      response = connection.get do |request|
        request.url module_name
        request.headers = headers
      end

      raise if response.status.to_i == 401 && retry_count <= 1
    rescue
      retry_count += 1
      @access_token = refresh_access_token
      retry
    end

    if response.status.to_i == 200 && response.body["data"].present?
      response.body["data"].each do |data|
        data_key = (data[duplicated_key].present?) ? data[duplicated_key].downcase.to_s : nil
        if store_results[data_key].present?
          duplicated_data[data_key] = store_results[data_key] unless duplicated_data[data_key].present?
          duplicated_data[data_key] << [data[search_column], data[identifier_key]]
        end
        store_results[data_key] = [[data[search_column], data[identifier_key]]]
      end
    end

    return duplicated_data
  end
end

#Organizations Model
class AccountZoho
  def initialize(process_id)
    @report_file = Rails.root.join('files', 'zoho_reports', "organizations_#{process_id}.csv")
    initialize_report_file
  end

  def report_file
    @report_file
  end

  def initialize_report_file
    unless File.exist?(@report_file)
      report_file = File.new(@report_file, 'w+')
      report_file.write("account_zoho_id ; organization_idocus_id; response_content; operation_type \n")
      report_file.close
    end
  end

  def search_record_with_criteria(object)
    "((Code_iDocus:equals:#{URI.encode_www_form_component(object.code.strip)})or(Identifiant_iDocus:equals:#{URI.encode_www_form_component(object.id)})or(Account_Name:equals:#{URI.encode_www_form_component(object.name.to_s.gsub(/\(/, "%28").gsub(/\)/, "%29"))}))"
  end

  def module_name
    "Accounts"
  end

  def create_records(data)
    counter = 0
    inserted = []
    data_content = []
    data.each do |organization|
      counter += 1
      inserted << organization.id
      record_data = {
        "Client_iDocus": true,
        "Identifiant_iDocus": organization.id,
        "Account_Number": organization.id,
        "Account_Name": organization.name,
        "Code_iDocus": organization.code,
        "Description": organization.description,
        "Abonnement_iDocus": (organization.is_active) ? 'actif' : 'résilié',
        "Nombre_de_Clients_Actifs": organization.customers.active.count.to_s
      }
      data_content << record_data
    end

    data_to_json = {
      "data": data_content
    }

    {json_content: (counter > 0)? data_to_json.to_json : "", list: inserted}
  end

  def update_records(data)
    counter = 0
    updated = []
    data_content = []
    data.each do |key, organization|
      counter += 1
      updated << organization.id
      record_data = {
        "id": key,
        "Client_iDocus": true,
        "Identifiant_iDocus": organization.id,
        "Account_Number": organization.id,
        "Account_Name": organization.name,
        "Code_iDocus": organization.code,
        "Abonnement_iDocus": (organization.is_active) ? 'actif' : 'résilié',
        "Nombre_de_Clients_Actifs": organization.customers.active.count.to_s
      }
      data_content << record_data
    end

    data_to_json = {
      "data": data_content
    }

    {json_content: (counter > 0)? data_to_json.to_json : "", list: updated}
  end

  def fill_report_file(reports)
      reports[:reports].each do |report|
        account_zoho_id        = report[:object_id]
        response_content       = report[:response]
        operation_type         = report[:operation_type]
        organization_idocus_id = report[:object_idocus_id].presence

        write_report_file("#{account_zoho_id};#{organization_idocus_id};#{response_content};#{operation_type}")
      end
  end

  def write_report_file(report_content)
    report_file = File.new(@report_file, 'a+')
    report_file.write("#{report_content}\n")
    report_file.close
  end
end

#Collaborators Model
class ContactZoho
  def initialize(process_id)
    @report_file = Rails.root.join('files', 'zoho_reports', "users_#{process_id}.csv")
    initialize_report_file
  end

  def report_file
    @report_file
  end

  def initialize_report_file
    unless File.exist?(@report_file)
      report_file = File.new(@report_file, 'w+')
      report_file.write("account_zoho_id ; contact_zoho_id ; organization_idocus_id; user_idocus_id; response_content; operation_type \n")
      report_file.close
    end 
  end

  def search_record_with_criteria(object)
    "((Email:equals:#{URI.encode_www_form_component(object.email)})or(Contact_Number:equals:#{URI.encode_www_form_component(object.id)}))"
  end

  def module_name
    "Contacts"
  end

  def create_records(data)
    counter = 0
    inserted = []
    data_content = []
    data.each do |user|
      counter += 1
      inserted << user.id
      record_data = {
        "Contact_Number": user.id,
        "Email": user.email,
        "Last_Name": user.last_name.presence || '-',
        "Fonction": user.memberships.first.admin? ? "Administrateur IDOCUS" : 'Collaborateur',
        "First_Name": user.first_name.presence || '-',
        "Account_Name"=>{
          "name": user.memberships.first.organization.name
        }
      }
      data_content << record_data
    end

    data_to_json = {
      "data": data_content
    }

    {json_content: (counter > 0)? data_to_json.to_json : "", list: inserted}
  end

  def update_records(data)
    counter = 0
    updated = []
    data_content = []
    data.each do |key, user|
      counter += 1
      updated << user.id
      record_data = {
        "id": key,
        "Contact_Number": user.id,
        "Fonction": user.memberships.first.admin? ? "Administrateur IDOCUS" : 'Collaborateur',
        "Account_Name"=>{
          "name": user.memberships.first.organization.name
        }
      }
      data_content << record_data
    end

    data_to_json = {
      "data": data_content
    }

    { json_content: (counter > 0)? data_to_json.to_json : "", list: updated }
  end

  def fill_report_file(reports)
      reports[:reports].each do |report|
        contact_zoho_id  = report[:object_id]
        response_content = report[:response]
        operation_type   = report[:operation_type]
        user_idocus_id   = report[:object_idocus_id].presence
        account_zoho_id  = report[:account_zoho_id].presence
        organization_idocus_id = 0
        reports[:objects].map{|user| organization_idocus_id = user.organization_id if user.id == user_idocus_id.to_i}

        write_report_file("#{account_zoho_id};#{contact_zoho_id};#{organization_idocus_id};#{user_idocus_id};#{response_content};#{operation_type}")
      end
  end

  def write_report_file(report_content)
    report_file = File.new(@report_file, 'a+')
    report_file.write("#{report_content}\n")
    report_file.close
  end
end
