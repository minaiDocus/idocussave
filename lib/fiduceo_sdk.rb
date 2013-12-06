module Fiduceo
  class << self
    attr_reader :config, :request, :response

    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end

    def config=(new_config)
      config.protocol = new_config['protocol'] if new_config['protocol']
      config.domain = new_config['domain'] if new_config['domain']
      config.proxy = new_config['proxy'] if new_config['proxy']
    end

    def providers
      perform 'providers', {}, is_deep: true
    end

    def providers_body
      perform 'providers/body'
    end

    def providers_mobile(date)
      perform "providers/mobile/#{date}"
    end

    def providers_mobile_body(date)
      perform "providers/mobile/body/#{date}"
    end

    def banks
      perform 'banks', {}, is_deep: true
    end

    def categories(type=nil) # debit || credit
      path = 'categories'
      path << "/#{type}" if type
      perform path, {}, is_deep: true
    end

    def static
      perform 'static'
    end

    def admin
      perform 'admin'
    end

    private

    def default_options
      options = {}
      options = { proxy: config.proxy } if config.proxy
      options
    end

    def perform(path, params={}, options={ is_deep: false })
      url = File.join([config.endpoint, path])
      @request = Typhoeus::Request.new(url, default_options.merge(params))
      get_response(options[:is_deep])
    end

    def get_response(is_deep=false)
      @response = @request.run
      if @response.code == 200
        content_type = @response.headers['Content-Type'] || ''
        case content_type.split('; ')[0]
        when 'application/json'
          JSON.parse @response.body
        when 'text/xml'
          parse_response(is_deep)
        when 'application/xml'
          parse_response(is_deep)
        else
          @response.code
        end
      else
        @response.code
      end
    end

    def parse_response(is_deep)
      result = Hash.from_xml(@response.body).first.last
      if is_deep
        results = result[result.keys.last]
        if results.is_a?(String)
          []
        else
          results = [results] unless results.is_a? Array
          to_objects(results)
        end
      else
        result
      end
    end

    def to_objects(entries)
      entries.map do |entry|
        OpenStruct.new entry
      end
    end
  end

  class Configuration
    attr_accessor :protocol, :domain, :proxy

    def initialize
      @protocol = 'https'
    end

    def endpoint
      "#{protocol}://#{domain}"
    end
  end

  class Client
    attr_reader :config, :user_id, :request, :response

    def initialize(user_id, options={})
      @user_id = user_id
      @config = Fiduceo.config.dup
    end

    # PUT
    def create_user
      result = perform "user", method: :put, body: '<?xml version="1.0"?><user/>'
      @user_id = result['id'] if result.is_a? Hash
      result
    end

    # GET || DELETE
    def user(method=:get, id=nil)
      path = "user"
      path << "/#{id}" if id
      perform path, method: method
    end

    # GET || PUT
    # params must have user_preferences_id
    def user_preferences(params={})
      options = {}
      if params.present?
        options = {
          method: :put,
          body: Fiduceo::XML::Builder.user_preferences(params.merge(id: user_preferences_id))
        }
      end
      perform 'userpreferences', options
    end

    def user_preferences_id
      if @user_preferences_id
        @user_preferences_id
      else
        result = user_preferences
        @user_preferences_id = (@response.code == 200) ? result['id'] : nil
      end
    end

    def user_imports
      perform 'userimports'
    end

    # GET || DELETE
    def user_import(id, method=:get)
      perform "userimport/#{id}", method: method
    end

    def user_import(params)
      perform 'userimport', method: :put,
                            body: Fiduceo::XML::Builder.user_import(params)
    end

    def retrievers
      perform 'retrievers', {}, is_deep: true
    end

    # GET || DELETE || POST || PUT
    def retriever(id=nil, method=:get, params={})
      options = { method: method }
      options.merge!({ body: Fiduceo::XML::Builder.retriever(params) }) if params.present?
      path = 'retriever'
      path << "/#{id}" if id
      perform path, options
    end

    def retriever_bankaccounts(id)
      perform "retriever/#{id}/bankaccounts"
    end

    def transaction(id)
      perform "transaction/#{id}"
    end

    def put_transaction(id, params)
      perform "transaction/#{id}", method: :put,
                                   body: Fiduceo::XML::Builder.transaction(params)
    end

    def alerts
      perform 'alerts'
    end

    # GET || DELETE
    def alert(id, method=:get)
      perform "alert/#{id}", method: method
    end

    def put_alert(params)
      perform 'alert', method: :put,
                       body: Fiduceo::XML::Builder.alert(params)
    end

    def banks
      perform 'banks', {}, is_deep: true
    end

    def banks_mobile(date)
      perform "banks/mobile/#{date}"
    end

    def bank_accounts
      perform 'bankaccounts', {}, is_deep: true
    end

    # GET || DELETE
    def bank_account(id, method=:get)
      perform "bankaccount/#{id}", method: method
    end

    def bank_account_balances(id, type, history_count, previ_count)
      perform "bankaccount/#{id}/balances/#{type}/#{history_count}/#{previ_count}", {}, is_deep: true
    end

    def put_bank_account(params)
      perform 'bankaccount', method: :put,
                             body: Fiduceo::XML::Builder.bank_account(params)
    end

    def categories(type=nil) # debit || credit
      path = 'categories'
      path << "/#{type}" if type
      perform path
    end

    def delete_doc_op_asso(id)
      perform "docopasso/#{id}", method: :delete
    end

    def put_doc_op_asso(params)
      perform 'docopasso', method: :put,
                           body: Fiduceo::XML::Builder.doc_to_op(params)
    end

    def delete_doc_proj_asso(id)
      perform "docprojasso/#{id}", method: :delete
    end

    def put_doc_proj_asso(params)
      perform 'docprojasso', method: :put,
                             body: Fiduceo::XML::Builder.doc_to_proj(params)
    end

    def documents(page=1, per_page=50, params={})
      options = {}
      unless params.empty?
        options.merge!({ method: :post, body: Fiduceo::XML::Builder.document_filter(params) })
      end
      perform "documents/#{page}/#{per_page}", options
    end

    # GET || DELETE
    def document(id, method=:get)
      perform "document/#{id}", method: method
    end

    # GET || DELETE
    def document_thumb(id, method=:get)
      perform "document/#{id}/thumb", method: method
    end

    def put_document(params)
      perform 'document', method: :put,
                          body: Fiduceo::XML::Builder.document(params)
    end

    def operations(page=1, per_page=50, params={})
      options = {}
      unless params.empty?
        options.merge!({ method: :post, body: Fiduceo::XML::Builder.operation_filter(params) })
      end
      perform "operations/#{page}/#{per_page}", options, is_deep: true
    end

    def put_operations(params)
      perform 'operations', method: :put,
                            body: Fiduceo::XML::Builder.operations(params)
    end

    def operations_sum_by_cat(category_id, days_ago)
      perform "operations/sum/#{category_id}/#{days_ago}"
    end

    # GET || DELETE
    def operation(id, method=:get)
      perform "operation/#{id}", method: method
    end

    def post_operation(id, params)
      perform "operation/#{id}", method: :post,
                                 body: Fiduceo::XML::Builder.operation_cuts(params)
    end

    def put_operation(options)
      perform 'operation', method: :put,
                           body: Fiduceo::XML::Builder.operation(options)
    end

    def mouvements(options)
      perform 'mouvements', method: :put,
                            body: Fiduceo::XML::Builder.mouvements(options)
    end

    def projects
      perform 'projects'
    end

    # GET || DELETE
    def project(id, method=:get)
      perform "project/#{id}", method: method
    end

    def put_project(params)
      perform 'project', method: :put,
                         body: Fiduceo::XML::Builder.project(params)
    end

    def tags
      perform 'tags'
    end

    # GET || POST
    def batch_community_export(method=:get)
      perform 'batch/communityexport', method: method
    end

    def expense_target_history(size, cat_id=nil)
      path = "expensetargethistory/#{size}"
      path << "/#{cat_id}" if cat_id
      perform path
    end

    def expense_targets
      perform 'expensetargets'
    end

    # GET || DELETE
    def expense_target(id, method=:get)
      perform "expensetarget/#{id}", method: method
    end

    def put_expense_target(params)
      perform 'expensetarget', method: :put,
                               body: Fiduceo::XML::Builder.expense_target(params)
    end

    # GET || DELETE
    def operation_future(id, method=:get)
      perform "operationfuture/{id}", method: method
    end

    def put_operation_future(params)
      perform 'operationfuture', method: :put,
                                 body: Fiduceo::XML::Builder.operation_future(params)
    end

    def operation_futures
      perform 'operationfutures'
    end

    def operation_future_confirm_all
      perform 'operationfuture/confirm/all'
    end

    def operation_future_confirm(id)
      perform "operationfuture/confirm/#{id}"
    end

    # GET || DELETE
    def operation_future_factory(id, method=:get)
      perform "operationfuturefactory/#{id}", method: method
    end

    def put_operation_future_factory(params)
      perform 'operationfuturefactory', method: :put,
                                        body: Fiduceo::XML::Builder.operation_future_factory(params)
    end

    def operation_future_fatories
      perform 'operationfuturefactories'
    end

    private

    def userpwd
      "#{@user_id}:" if @user_id
    end

    def default_options
      options = {}
      options = { proxy: @config.proxy } if @config.proxy
      options.merge!({ userpwd: userpwd }) if userpwd
      options
    end

    def perform(path, params={}, options={ is_deep: false })
      _params = default_options.merge(params)
      _params.merge!({ headers: { 'Content-Type' => 'text/xml' } }) if _params[:body].present?
      url = File.join(@config.endpoint, path)
      @request = Typhoeus::Request.new(url, _params)
      get_response(options[:is_deep])
    end

    def get_response(is_deep=false)
      @response = @request.run
      if @response.code == 200
        content_type = @response.headers['Content-Type'] || ''
        case content_type.split('; ')[0]
        when 'application/json'
          JSON.parse @response.body
        when 'text/xml'
          parse_response(is_deep)
        when 'application/xml'
          parse_response(is_deep)
        else
          @response.code
        end
      else
        @response.code
      end
    end

    def parse_response(is_deep)
      result = Hash.from_xml(@response.body).first.last
      if is_deep
        results = result[result.keys.last]
        if results.is_a?(String)
          [0, []]
        else
          results = [results] unless results.is_a? Array
          count = result['count'].try(:to_i)
          count = results.size unless count
          [count, to_objects(results)]
        end
      else
        result
      end
    end

    def to_objects(entries)
      entries.map do |entry|
        _entry = {}
        entry.each_pair do |k,v|
          _entry[k.underscore] = v
        end
        OpenStruct.new _entry
      end
    end
  end
end
