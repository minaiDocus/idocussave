class UpdateMyUnisoftConfiguration
  def initialize(organization, customer=nil)
    @organization = organization
    @customer     = customer
  end

  def execute(params)
    @params = params

    unless @customer
      @mu       = @organization.my_unisoft.presence || Software::MyUnisoft.new
      @mu.owner = @organization

      save
    else
      @mu  = @customer.my_unisoft

      if params[:action] == "update" 
        return false if !@params[:is_used] && @mu.nil?

        if @mu.present? && !@params[:is_used]
          @mu.destroy

          return true
        end

        @mu         = Software::MyUnisoft.new if @mu.nil?
        @mu.owner   = @customer

        save
      else
        if params[:remove_customer]
          @mu.api_token     = nil
          @mu.society_id    = nil
          @mu.access_routes = ""
          @mu.auto_deliver  = -1

          @mu.save

          return true
        elsif params[:api_token].present?
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
    @mu.auto_deliver    = @params[:auto_deliver]  if @params[:auto_deliver].present?
    @mu.api_token       = @params[:api_token]     if @params[:api_token].present?
    @mu.is_used         = @params[:is_used]       if @params[:is_used].present?

    @mu.save
  end


  def client
    @client ||= MyUnisoftLib::Api::Client.new(@api_token)
  end
end