# encoding: utf-8
class ZohoControl
  # AUTHTOKEN = '7e2b6d448a6d833f46ce3f83d5d25c93' ###test
  AUTHTOKEN = '5064b25445e1bd95b9d78c49a536ffcd' ###prod
  Zoho_uri = 'https://crm.zoho.com/crm/private/xml/'
  ZScope = 'crmapi'

  class << self
    def send_organizations
      new().send_organizations
    end

    def send_collaborators
      new().send_collaborators
    end
  end

  def initialize
    reset_control
    @process_id = DateTime.current.strftime("%Y%m%d_%H%M")
  end

  def send_organizations
    time_start = DateTime.current
    @organizations_count, @success_org_count, @errors_org_count, @exist_org_count = 0, 0, 0, 0
    @users_count, @success_usr_count, @errors_usr_count, @exist_usr_count = 0, 0, 0, 0

    organizations = Organization.select([:id, :name, :code, :description])
    @organizations_count = organizations.size
    organizations.each_slice(10) do |orgs|
      sending_process(orgs)
    end

    {
      time_start:     time_start,
      organizations:  { count: @organizations_count, success: @success_org_count, error: @errors_org_count, exist: @exist_org_count },
      users:          { count: @users_count, success: @success_usr_count, error: @errors_usr_count, exist: @exist_usr_count }
    }
  end

  def send_collaborators
    @organizations_count, @success_org_count, @errors_org_count, @exist_org_count = 0, 0, 0, 0
    @users_count, @success_usr_count, @errors_usr_count, @exist_usr_count = 0, 0, 0, 0

    users = User.where(is_prescriber: true)

    send_users = []
    users.each do |u|
      member = u.memberships.first
      if member
        u.code = member.code
        u.organization_id = member.organization_id
        send_users << u
      end
    end

    @users_count += send_users.size
    send_users.each_slice(10) { |usrs| sending_process(usrs) }
    true
  end

  def get_datas(module_cible)
    start_ind = 1
    end_ind = 200
    datas = []
    begin
      part = []
      zoho_data = send_request_uri("#{Zoho_uri}#{module_cible}/getRecords", { authtoken: AUTHTOKEN, scope: ZScope, fromIndex:start_ind, toIndex: end_ind })
      docs = Nokogiri::XML(zoho_data)
      if docs.css("row").present?
        docs.css("row").each do |rw|
          part[rw['no'].to_i] = {}
          rw.css("FL").each do |fl|
            part[rw['no'].to_i][fl['val'].to_s] = fl.text
          end
        end
      end
      start_ind = end_ind
      end_ind = end_ind + 200
      part.compact!
      datas += part
    end while part.count == 200
    return datas
  end

  private

  def sending_process(datas)
    mess = inject_datas(datas)
    count_report(datas)
  end

  def reset_control
    @inject_report_success, @inject_report_errors, @liste_inserted_data, @liste_updated_data, @messages = [], [], [], [], ""
    @success_count, @exist_count, @errors_count = 0, 0, 0
  end

  def inject_datas(datas)
    initialize_data_type(datas.first)
    reset_control

    @xml_inject = create_xml_object(datas)

    send_xml_to_zoho

    if @messages == ""
      @messages = "inject all"
    end

    feel_report_data(datas.first)

    return @messages
  end

  def get_inject_report
    return { success: @inject_report_success, errors: @inject_report_errors }
  end

  def get_inject_count
    return { success: @success_count, errors: @errors_count, exists: @exist_count }
  end

  def is_exist_object?(object)
    zoho_obj = send_request_uri("#{Zoho_uri}#{@data_type.module_zoho}/searchRecords", { authtoken: AUTHTOKEN, scope: ZScope, criteria: "#{@data_type.zoho_criteria_search(object)}" })
    return_existance_object(zoho_obj)
  end

  def return_existance_object(message)
    docs = Nokogiri::XML(message)
    if docs.css("nodata").present?
      return 0
    elsif docs.css("row").present?
      ids = docs.css("row FL[val='#{@data_type.module_zoho_id}']").text
      return ids
    else
      return nil
    end
  end

  def count_report(datas)
    if datas.first.is_a?(User)
      @success_usr_count += get_inject_count[:success]
      @exist_usr_count += get_inject_count[:exists]
      @errors_usr_count += get_inject_count[:errors]
    else
      @success_org_count += get_inject_count[:success]
      @exist_org_count += get_inject_count[:exists]
      @errors_org_count += get_inject_count[:errors]
    end
  end

  def initialize_data_type(obj_type)
    if obj_type.is_a? User
      @data_type = ContactZoho.new(@process_id)
    else
      @data_type = AccountZoho.new(@process_id)
    end
  end

  def decode_zoho_response(response, type = 'insert')
    tab_data = type == 'insert'? @liste_inserted_data : @liste_updated_data

    if response =~ /<\?xml/si
      docs = Nokogiri::XML(response)
      msg = docs.css("row").each do |rw|
        if rw.css("success").present?
          @inject_report_success << { object_id: tab_data[rw['no'].to_i], retour: "Record #{type}", type: type }
          @success_count += 1
          @exist_count +=1 if type == 'update'
        else
          @inject_report_errors << { object_id: tab_data[rw['no'].to_i], retour: rw.css("details").text, type: type }
          @errors_count += 1
          @messages = "inject with error(s)"
        end
      end
    else
      @inject_report_errors << { object_id: 'All', retour: response, type: type }
      @errors_count += 1
      @messages = "inject with error(s)"
    end
  end

  def create_xml_object(objects)
    insert_obj, update_obj = [], {}

    objects.each do |obj|
      obj_id = is_exist_object?(obj)
      if obj_id.to_i == 0
        insert_obj << obj
      elsif obj_id.present? && obj_id.to_i > 0
        update_obj[obj_id.to_s] = obj
      else
        @inject_report_errors << { object_id: obj.id, retour:  "Error parsing xml", type: 'search' }
        @errors_count += 1
      end
    end

    res_insert = @data_type.zoho_xml_insert_format(insert_obj)
    res_update = @data_type.zoho_xml_update_format(update_obj)

    @liste_inserted_data += res_insert[:list]
    @liste_updated_data += res_update[:list]

    return { :insert => res_insert[:xml], :update => res_update[:xml] }
  end

  def send_xml_to_zoho
    if @xml_inject[:insert].present?
      zoho_response = send_request_uri("#{Zoho_uri}#{@data_type.module_zoho}/insertRecords", { authtoken: AUTHTOKEN, scope:ZScope, xmlData: @xml_inject[:insert], version: 4 })
      decode_zoho_response(zoho_response, 'insert')
    end

    if @xml_inject[:update].present?
      zoho_response = send_request_uri("#{Zoho_uri}#{@data_type.module_zoho}/updateRecords", { authtoken: AUTHTOKEN, scope:ZScope, xmlData: @xml_inject[:update], version: 4 })
      decode_zoho_response(zoho_response, 'update')
    end
  end

  def feel_report_data(obj)
    @data_type.feel_report_data({reports: (@inject_report_success + @inject_report_errors), object: obj})
  end

  def send_request_uri(uri, params_get)
    begin
      uri = URI.parse(uri)
      uri.query = URI.encode_www_form(params_get)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      response = http.get(uri.request_uri)
      response.body
    rescue Exception => e
      e.to_s
    end
  end
end

#Organizations Model
class AccountZoho
  def initialize(process_id)
    @file_report = Rails.root.join('files', 'zoho_reports', "organizations_#{process_id}.csv")
    init_file_report
  end

  def init_file_report
    unless File.exist?(@file_report)
      fp = File.new(@file_report, 'w+')
      fp.write("id_organization; Retour; type \n")
      fp.close
    end 
  end

  def zoho_criteria_search(obj)
    "(Code iDocus:#{obj.code}%)"
  end

  def module_zoho
    "Accounts"
  end

  def module_zoho_id
    "ACCOUNTID"
  end

  def zoho_xml_insert_format(datas)
    num_parse = 0
    liste_inserted_data = []
    document = Nokogiri::XML::Builder.new do |xml|
      xml.Accounts {
        datas.each do |org|
            num_parse += 1
            liste_inserted_data[num_parse] = org.id
            xml.row(no: num_parse) {
              xml.FL(org.name, val: 'Account Name')
              xml.FL(org.code, val: 'Code iDocus')
              xml.FL(org.description, val: 'Description')
            }
        end
      }
    end
    {xml: (num_parse > 0)? document.to_xml : "", list: liste_inserted_data}
  end

  def zoho_xml_update_format(datas)
    num_parse = 0
    liste_updated_data = []
    document = Nokogiri::XML::Builder.new do |xml|
      xml.Accounts {
        datas.each do |key, org|
            num_parse += 1
            liste_updated_data[num_parse] = org.id
            xml.row(no: num_parse) {
              xml.FL(key.to_i, val: 'Id')
              xml.FL(org.code, val: 'Code iDocus')
            }
        end
      }
    end
    {xml: (num_parse > 0)? document.to_xml : "", list: liste_updated_data}
  end

  def feel_report_data(args)
      args[:reports].each do |report|
        id = report[:object_id]
        msg = report[:retour]
        type = report[:type]

        write_file_report("#{id};#{msg};#{type}")
      end
  end

  def write_file_report(msg)
    fp = File.new(@file_report, 'a+')
    fp.write("#{msg}\n")
    fp.close
  end
end

#Collaborators Model
class ContactZoho
  def initialize(process_id)
    @file_report = Rails.root.join('files', 'zoho_reports', "users_#{process_id}.csv")
    init_file_report
  end

  def init_file_report
    unless File.exist?(@file_report)
      fp = File.new(@file_report, 'w+')
      fp.write("id_organization; | ; id_user; Retour; type \n")
      fp.close
    end 
  end

  def zoho_criteria_search(obj)
    "(Email:#{obj.email}%)"
  end

  def module_zoho
    "Contacts"
  end

  def module_zoho_id
    "CONTACTID"
  end

  def zoho_xml_insert_format(datas)
    num_parse = 0
    liste_inserted_data = []
    document = Nokogiri::XML::Builder.new do |xml|
      xml.Contacts {
        datas.each do |usr|
            num_parse += 1
            liste_inserted_data[num_parse] = usr.id
            xml.row(no: num_parse) {
              xml.FL(usr.email, val: 'Email')
              xml.FL(usr.last_name, val: 'Last Name')
              xml.FL(usr.first_name, val: 'First Name')
              xml.FL(Organization.find(usr.organization_id).name, val: 'Account Name')
              xml.FL(usr.phone_number, val: 'Phone')
              xml.FL(usr.code, val: 'Code iDocus')
            }
        end
      }
    end
    {xml: (num_parse > 0)? document.to_xml : "", list: liste_inserted_data}
  end

  def zoho_xml_update_format(datas)
    num_parse = 0
    liste_updated_data = []
    document = Nokogiri::XML::Builder.new do |xml|
      xml.Contacts {
        datas.each do |key, usr|
            num_parse += 1
            liste_updated_data[num_parse] = usr.id
            xml.row(no: num_parse) {
              xml.FL(key.to_i, val: 'Id')
              xml.FL(usr.code, val: 'Code iDocus')
              xml.FL(Organization.find(usr.organization_id).try(:name), val: 'Account Name')
            }
        end
      }
    end
    {xml: (num_parse > 0)? document.to_xml : "", list: liste_updated_data}
  end

  def feel_report_data(args)
      org_id = args[:object].try(:organization_id)
      args[:reports].each do |report|
        id = report[:object_id]
        msg = report[:retour]
        type = report[:type]

        write_file_report("#{org_id};|;#{id};#{msg};#{type}")
      end
  end

  def write_file_report(msg)
    fp = File.new(@file_report, 'a+')
    fp.write("#{msg}\n")
    fp.close
  end
end
    
   
    
  
  
  
  
  
  




