# -*- encoding : UTF-8 -*-
# This module is very useful to handle static lists (like enumerations).
#
# The problem:
#
# In your application you may want to handle things in your User model like sex (female, male) or other static lists.
# You want these lists to be handled using 'textual keys' in your application but stored in your database using codes in an integer column.
# You don't want to join other tables to display these information.
# You want these lists to be easily ordered, localized and translated using Rails i18n. You want view helpers to display these lists localized and
# validations helpers to validate the values in the 'receiving' model.
#
# Example :
# (I want to store the hair color of the user...)
#
# (hair_color.rb)
# class HairColor
#   include StaticList::Model
#  
#   static_list [[:white, 1], [:blond, 2], [:red, 3], [:light_brown, 4], [:brown, 5], [:black, 6], [:colored, 7], [:bald, 8]]
# end
#
# (user.rb)
# class User < ActiveRecord::Base
#   ...
#   include StaticList::Validate
#   
#   validates_static_list_value :hair_color, HairColor, :allow_blank => true
#   ...
# end
#
# (application_helper.rb)
# module ApplicationHelper
#   ...
#   include StaticList::Helpers
#   ...
# end
#
# (_form.html.erb)
# ...
# <%= f.select :hair_color, static_list_select_options(HairColor) %>
# ...
# 
# (show.html.erb)
# ...
# <%= t_static_list(@user.hair_color, HairColor) %>
# ...
#
# (en.yml)
# ...
# hair_color:
#   white: white
#   blond: blond
#   red: red
# ...
#
# (fr.yml)
# ...
# hair_color:
#   white: blancs
#   blond: blonds
#   red: rouges
# ...
#
# Copyright (c) 2010 Novelys. Written by Nicolas Blanco.
#
#
module StaticList
  module Validate
    extend ActiveSupport::Concern
    
    module ClassMethods
      # Method to validate in the receiving model that the value received is included in the static list model.
      # For example :
      # with_options(:allow_blank => true) do |options|
      #   options.validate_static_list_value :hair_color,          HairColor
      #   options.validate_static_list_value :ethnicity,           Ethnicity
      #   options.validate_static_list_value :sex,                 Sex
      # end
      def validates_static_list_value(attribute, model, options = {})
        options.merge!(:in => model.static_list_codes.map { |el| el[1] })
        validates_inclusion_of attribute, options
      end
    end
  end
  
  module Model
    extend ActiveSupport::Concern

    included do
      cattr_accessor :static_list_codes
    end
    
    module ClassMethods
      # Method to declare the static list in the static list model.
      def static_list(list)
        self.static_list_codes = list
      end
      
      # Returns the symbol associated with the code in parameter.
      #
      # For example : HairColor.static_list_code_to_sym(0) # => :white
      #
      def static_list_code_to_sym(code)
        static_list_codes.find { |el| el[1] == code }[0]
      end
      
      def t_symbol(code)
        "#{self.to_s.demodulize.underscore}.#{self.static_list_code_to_sym(code)}"
      end
      
      def to_code(sym)
        static_list_codes.find { |el| el[0] == sym }[1]
      end
      
      def static_codes
        static_list_codes.map{ |e| e[0] }
      end
      
      def static_keys
        static_list_codes.map{ |e| e[1] }
      end

      #some shortcuts
      def keys
        self.static_keys
      end

      def to_key(sym)
        static_list_codes.find { |el| el[0] == sym }[1]
      end

      def symbols
        self.static_codes
      end

      def to_symbol(key)
        self.static_list_code_to_sym(key)
      end


    end
  end
  
  module Helpers
    # Localizes a static code
    # For example :
    # t_static_list(@user.hair_color, HairColor)
    #
    # will read the key hair_color.white
    #
    def t_static_list(code, static_object)
      return unless code
      t "#{static_object.to_s.demodulize.underscore}.#{static_object.static_list_code_to_sym(code)}"
    end

    # Localizes all the static codes for select options helper
    #
    # Example :
    # f.select :hair_color, static_list_select_options(HairColor)
    #
    def static_list_select_options(static_object)
      static_object.static_list_codes.map { |code| [t_static_list(code[1], static_object), code[1]] }
    end
  end
end
