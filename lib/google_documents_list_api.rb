require 'oauth'
require 'rexml/document'
require 'uri'

module GoogleDocumentsList
  module API
    class Service
      attr_accessor :token, :secret, :consumer, :request_token, :access_token
      
      def initialize(token=nil,secret=nil)
        if token and secret
          @access_token = OAuth::AccessToken.new(consumer)
          @token = @access_token.token = token
          @secret = @access_token.secret = secret
          @access_token
        else
          @token = @secret = ""
        end
      end
      
      def consumer
        @consumer ||= OAuth::Consumer.new( GoogleDocumentsList::API::CONSUMER_KEY, GoogleDocumentsList::API::CONSUMER_SECRET, GoogleDocumentsList::API::SETTINGS )
      end
      
      def get_request_token(callback="")
        if @request_token
          @request_token
        else
          if !token.empty? and !secret.empty?
            @request_token = OAuth::RequestToken.new(consumer)
            @request_token.token = @token
            @request_token.secret = @secret
          else
            @request_token = consumer.get_request_token( { :oauth_callback => callback }, :scope => GoogleDocumentsList::API::SCOPE_URL )
            @token = request_token.token
            @secret = request_token.secret
          end
          @request_token
        end
      end
      
      def get_authorize_url(callback="")
        get_request_token(callback).authorize_url
      end
      
      def get_access_token(verifier)
        @access_token = get_request_token.get_access_token :oauth_verifier => verifier
        @token = access_token.token
        @secret = access_token.secret
        @access_token
      end
      
      def make_col(name, resourceID=nil)
        url = "https://docs.google.com/feeds/default/private/full"
        url += "/#{resourceID}/contents" if !resourceID.nil?
        entry = <<-EOF
<?xml version='1.0' encoding='UTF-8'?>
<entry xmlns="http://www.w3.org/2005/Atom">
  <category scheme="http://schemas.google.com/g/2005#kind" term="http://schemas.google.com/docs/2007#folder"/>
  <title>#{name}</title>
</entry>
EOF
        @access_token.post url, entry, "Content-type" => "application/atom+xml", "GData-Version" => "3.0"
        if is_response_ok?
          feed = REXML::Document.new(@access_token.response.body)
          parse_data(feed).first
        else
          nil
        end
      end
      
      def delete(resourceID)
        @access_token.delete("#{DEFAULT_URL}/#{resourceID}?delete=true")
        is_response_ok?
      end
      
      def upload_file(filepath, colID=nil, contentType="text/plain")
        raw_file = open(filepath,"rb")
        filename = File.basename(filepath)
        url = colID.nil? ? DOCUMENT_URL : "#{FOLDER_URL}/#{colID}"
        @access_token.post(url, raw_file, 'Content-type' => contentType, "Slug" => filename)
        is_response_ok?
      end
      
      def list_col
        @access_token.get("#{DOCUMENT_URL}/-/folder?showfolders=true")
        parsed_response
      end
      
      def find_or_create_colID(path)
        result = find_or_create_col(path)
        if result
          result[:id].split("/")[-1]
        end
      end
      
      def find_or_create_col(path)
        resourceID = nil
        result = nil
        path.split("/").each do |name|
          result = find_col(name,resourceID)
          result = make_col(name,resourceID) if !result
          resourceID = result[:id].split("/")[-1]
        end
        result
      end
      
      def find_col(name, resourceID=nil)
        encoded_name = URI.escape(name)
        url = DEFAULT_URL
        url += "/#{resourceID}/contents" if !resourceID.nil?
        @access_token.get("#{url}?title=#{encoded_name}&title-exact=true&showfolders=true", "Content-type" => "application/atom+xml", "GData-Version" => "3.0")
        parsed_response.first
      end
      
      def parsed_response
        if is_response_ok?
          feed = REXML::Document.new(@access_token.response.body).root
          parse_data(feed)
        end
      end
      
      def parse_data(feed)
        results = []
        feed.elements.each('entry') do |entry|
          result = {}
          result[:title] = entry.elements['title'].text
          result[:type] = entry.elements['category'].attribute('label').value
          result[:updated] = entry.elements['updated'].text
          result[:id] = entry.elements['id'].text
          entry.elements.each('link') do |link|
            result[link.attribute('rel').value] = link.attribute('href').value
          end
          results << result
        end
        results
      end
      
      def is_response_ok?
        ["200","201"].include? @access_token.response.code
      end
      
    end
  end
end
