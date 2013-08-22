# -*- encoding : UTF-8 -*-
require 'nori'

module WashOut
  # This class is a Rack middleware used to route SOAP requests to a proper
  # action of a given SOAP controller.
  class Router
    def initialize(controller_name)
      @controller_name = "#{controller_name.to_s}_controller".camelize
    end

    def call(env)
      controller = @controller_name.constantize

      soap_action = env['HTTP_SOAPACTION']
      if soap_action.present? && soap_action != "\"\""
        # RUBY18 1.8 does not have force_encoding.
        soap_action.force_encoding('UTF-8') if soap_action.respond_to? :force_encoding

        if WashOut::Engine.namespace
          namespace = Regexp.escape WashOut::Engine.namespace.to_s
          soap_action.gsub!(/^\"(#{namespace}\/?)?(.*)\"$/, '\2')
        else
          soap_action = soap_action[1...-1]
        end

        env['wash_out.soap_action'] = soap_action
      else
        soap_action = env['action_dispatch.request.request_parameters']['Envelope']['Body'].keys.first rescue nil
        if soap_action.nil? && env['rack.input'].size > 0
          env['rack.input'].rewind
          body = env['rack.input'].read;
          env['rack.input'].rewind
          doc  = Nokogiri::Slop(body)
          doc.remove_namespaces!
          soap_action = doc.Envelope.Body.elements.first.name rescue nil
        end

        env['wash_out.soap_action'] = soap_action unless soap_action.nil?
      end

      action_spec = controller.soap_actions[soap_action]
      if action_spec
        action = action_spec[:to]
      else
        action = '_invalid_action'
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
        @map          = self.class.parse_def(type.wash_out_param_map)
        @source_class = type
      else
        @type = 'struct'
        @map  = self.class.parse_def(type)
      end
    end
  end

  module Dispatcher
    def _parse_soap_parameters
      parser = Nori.new(
        :parser => WashOut::Engine.parser,
        :strip_namespaces => true,
        :advanced_typecasting => true,
        :convert_tags_to => ( WashOut::Engine.snakecase_input ? lambda { |tag| tag.snakecase.to_sym } \
                                : lambda { |tag| tag.to_sym } ))

      request.body.rewind
      @_params = parser.parse(request.body.read)
      request.body.rewind
      references = WashOut::Dispatcher.deep_select(@_params){|k,v| v.is_a?(Hash) && v.has_key?(:@id)}

      unless references.blank?
        replaces = {}; references.each{|r| replaces['#'+r[:@id]] = r}
        @_params = WashOut::Dispatcher.deep_replace_href(@_params, replaces)
      end
    end
  end
end
