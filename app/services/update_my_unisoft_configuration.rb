class UpdateMyUnisoftConfiguration
  def initialize(organization, customer=nil)
    @organization = organization
    @customer     = customer
  end

  def execute(params)
    @params = params

    unless @customer
      @mu  = Software::MyUnisoft.where(organization_id: @organization.id, user_id: nil).first || Software::MyUnisoft.new

      save
    else
      @mu  = Software::MyUnisoft.where(organization_id: @organization.id, user_id: @customer.id).first

      if params[:action] == "update"        
        if params[:is_my_unisoft_used]
          @mu           = Software::MyUnisoft.new if @mu.nil?
          @mu.user_used = true
        else
          @mu.destroy

          return true
        end

        save
      else
        if params[:remove_customer]
          @mu.api_token  = nil
          @mu.society_id = nil

          @mu.save

          return true
        else
          @api_token = params[:api_token]
          list_keys  = get_list_key

          @mu.access_routes = list_keys.join(',')

          info_societe = client.get_society_info

          if info_societe[:status] == "success"
            info = info_societe[:body]
            @mu.society_id = info['society_id']
            @mu.name       = info['name']
          end

          save
        end
      end
    end

    true
  end

  private

  def get_list_key
    keys = []

    response = client.get_routes   

    if response[:status] == "success"
      routes = response[:body]

      routes.each do |route|
        keys << route['path'] if route['path'].match(/account/) || route['path'].match(/entry/)
      end
    end

    keys
  end

  def save
    @mu.organization_used         = @params[:organization_used]    
    @mu.organization_auto_deliver = @params[:organization_auto_deliver]
    @mu.api_token                 = @params[:api_token]                    if @params[:api_token].present?
    @mu.customer_auto_deliver     = @params[:customer_auto_deliver]        if @params[:customer_auto_deliver].present?
    @mu.organization              = @organization                          if @organization
    @mu.user                      = @customer                              if @customer

    @mu.save    
  end


  def client
    @client ||= MyUnisoft::Client.new(@api_token)
  end
end