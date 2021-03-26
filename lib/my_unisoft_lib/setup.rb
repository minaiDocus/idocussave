# -*- encoding : UTF-8 -*-
module MyUnisoftLib
  class Setup
    def initialize(params)
      @organization = params[:organization]
      @customer     = params[:customer]
      @params       = params[:columns]
    end

    def execute
      @my_unisoft = @customer.nil? ? @organization.my_unisoft.presence : @customer.my_unisoft.presence

      @my_unisoft = Software::MyUnisoft.new if @my_unisoft.nil?

      @owner      = nil

      @api_token = @params[:api_token]

      unless @customer
        @owner = @organization
        update_and_save
      else
        @owner    = @customer

        if @params[:action] == "update"
          return false if !@params[:is_used] && @my_unisoft.nil?

          return true if !@params[:is_used] && @my_unisoft.present? && @my_unisoft.destroy

          update_and_save
        else
          if @params[:remove_customer]
            @my_unisoft.api_token     = nil
            @my_unisoft.society_id    = nil
            @my_unisoft.access_routes = ""
            @my_unisoft.auto_deliver  = -1

            return true if @my_unisoft.save
          elsif @api_token.present?
            list_keys                 = get_list_key

            @my_unisoft.api_token     = @api_token if @api_token.present?
            @my_unisoft.access_routes = list_keys.join(',')

            info_societe              = client.get_society_info

            if info_societe[:status] == "success"
              @my_unisoft.society_id = info_societe[:body]['society_id']
              @my_unisoft.name       = info_societe[:body]['name']
            end

            update_and_save
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

    def update_and_save
      @my_unisoft.owner           = @owner
      @my_unisoft.auto_deliver    = @params[:auto_deliver]  if @params[:auto_deliver].present?
      @my_unisoft.is_used         = @params[:is_used]       if @params[:is_used].to_s.present?

      @my_unisoft.save
    end


    def client
      @client ||= MyUnisoftLib::Api::Client.new(@api_token)
    end
  end

end