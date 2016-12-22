# -*- encoding : UTF-8 -*-
require 'nori'

#              WashOut Patch. Unable to document it.
#
#                  TAKE CARE WHEN MODIFYING THIS
#

module WashOut
  # This class is a Rack middleware used to route SOAP requests to a proper
  # action of a given SOAP controller.
  class Router
    def initialize(controller_name)
      @controller_name = "#{controller_name}_controller".camelize
    end

    def soap_body(env)
      env['rack.input'].rewind
      env['rack.input'].read
    end

    def call(env)
      controller = @controller_name.constantize

      soap_action = env['HTTP_SOAPACTION']
      if soap_action.present? && soap_action != '""'
        # RUBY18 1.8 does not have force_encoding.
        soap_action.force_encoding('UTF-8') if soap_action.respond_to? :force_encoding

        if WashOut::Engine.namespace
          namespace = Regexp.escape WashOut::Engine.namespace.to_s
          soap_action.gsub!(/\A\"(#{namespace}\/?)?(.*)\"\z/, '\2')
        else
          soap_action = soap_action[1...-1]
        end

        env['wash_out.soap_action'] = soap_action
      else
        soap_action = begin
                        env['action_dispatch.request.request_parameters']['Envelope']['Body'].keys.first
                      rescue
                        nil
                      end

        if soap_action.nil?
          doc = Nokogiri::Slop(env['rack.input'].gets)
          doc.remove_namespaces!
          soap_action = begin
                          doc.Envelope.Body.elements.first.name
                        rescue
                          nil
                        end
        end

        env['wash_out.soap_action'] = soap_action unless soap_action.nil?
      end

      action_spec = controller.soap_actions[soap_action]
      action = if action_spec
                 action_spec[:to]
               else
                 '_invalid_action'
               end

      controller.action(action).call(env)
    end
  end

  class Param
    def initialize(name, type, multiplied = false)
      type ||= {}

      @name       = name.to_s
      @raw_name   = name.to_s
      @map        = {}
      @multiplied = multiplied

      if name.is_a? Symbol
        if WashOut::Engine.camelize_wsdl.to_s == 'lower'
          @name = @name.camelize(:lower)
        elsif WashOut::Engine.camelize_wsdl
          @name = @name.camelize
        end
      end

      if type.is_a?(Symbol)
        @type = type.to_s
      elsif type.is_a?(Class)
        @type         = 'struct'
        #@map          = self.class.parse_def(type.wash_out_param_map)
        @source_class = type
      else
        @type = 'struct'
        #@map  = self.class.parse_def(type)
      end
    end
  end

  module Dispatcher
    def _parse_soap_parameters
      parser = Nori.new(
        parser: WashOut::Engine.parser,
        strip_namespaces: true,
        advanced_typecasting: true,
        convert_tags_to: (WashOut::Engine.snakecase_input ? ->(tag) { tag.snakecase.to_sym } \
                                : ->(tag) { tag.to_sym }))

      request.body.rewind
      @_params = parser.parse(request.body.read)
      request.body.rewind
      references = WashOut::Dispatcher.deep_select(@_params) { |_k, v| v.is_a?(Hash) && v.key?(:@id) }

      unless references.blank?
        replaces = {}; references.each { |r| replaces['#' + r[:@id]] = r }
        @_params = WashOut::Dispatcher.deep_replace_href(@_params, replaces)
      end
    end
  end

  module ActionDispatch::Routing
    class Mapper
      # Adds the routes for a SOAP endpoint at +controller+.
      def wash_out(controller_name, options={})
        options.each_with_index { |key, value|  @scope[key] = value } if @scope
        controller_class_name = [options[:module], controller_name].compact.join("/")

        match "#{controller_name}/wsdl"   => "#{controller_name}#_generate_wsdl", :via => :get, :format => false
        match "#{controller_name}/action" => WashOut::Router.new(controller_class_name), :via => [:get, :post], :defaults => { :controller => controller_class_name, :action => '_action' }, :format => false
      end
    end
  end
end
