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
      
      def find_or_create_collection(path)
        colID = nil
        result = nil
        path.split("/").
        reject { |e| e.empty? }.
        each do |name|
          result = find_collection(name,colID)
          result = create_collection(name,colID) unless result
          colID = result["id"].split("/")[-1] rescue nil
        end
        result
      end
      
      def create_collection(name, colID=nil)
        url = "https://docs.google.com/feeds/default/private/full"
        url += "/#{colID}/contents" if !colID.nil?
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
      
      def update_or_create_file(filepath, colID, content_type, collection=nil)
        document = find_document(File.basename(filepath,".*"), colID)
        if document
          id = document["id"].split("/")[-1]
          etag = document["etag"]
          update(filepath, id, etag, content_type)
        else
          create(filepath, content_type, colID, collection)
        end
      end
      
      def collections(colID=nil)
        results = find_ressource colID
        results.select { |entry| entry["id"].match("folder") }
      end
      
      def documents(colID=nil)
        results = find_ressource(colID, nil, false)
        results.select { |entry| !entry["id"].match("folder") }
      end
      
      def find_collection(name, colID=nil)
        find_ressource(colID, name).
        select { |entry| entry["id"].match("folder") }.
        first
      end
      
      def find_document(name, colID=nil)
        find_ressource(colID, name, false).
        select { |entry| !entry["id"].match("folder") }.
        first
      end
      
      def find_ressource(colID=nil, name=nil, view_collection=true)
        url = DEFAULT_URL
        url += "/#{colID}/contents" unless colID.nil?
        url += "?" if name or view_collection
        url += "title=#{URI.escape(name)}&title-exact=true" if name
        url += "&" if name and view_collection
        url += "showfolders=true" if view_collection
        @access_token.get(url, "GData-Version" => "3.0")
        parsed_response
      end
      
      def parsed_response
        if is_response_ok?
          feed = REXML::Document.new(@access_token.response.body).root
          parse_data(feed)
        else
          []
        end
      end
      
      def parse_data(feed)
        results = []
        feed.elements.each('entry') do |entry|
          result = {}
          result["title"] = entry.elements['title'].text
          result["type"] = entry.elements['category'].attribute('label').value
          result["updated"] = entry.elements['updated'].text
          result["id"] = entry.elements['id'].text
          result["etag"] = entry.attributes['gd:etag']
          entry.elements.each('link') do |link|
            name = link.attribute('rel').value
            if name.match("#")
              name = name.split("#")[1]
            end
            result[name] = link.attribute('href').value
          end
          results << result
        end
        results
      end
      
      def is_response_ok?
        ["200","201","308"].include? @access_token.response.code
      end
      
      def is_ok?
        @access_token.response.code == "200"
      end
      
      def is_created?
        @access_token.response.code == "201"
      end
      
      def is_resume_incomplete?
        @access_token.response.code == "308"
      end
      
      # POST
      def create(filepath, content_type, colID=nil, collection=nil)
        id = colID.nil? ? "" : "/" + colID
        url = ""
        if collection
          url = collection["resumable-create-media"] + "?convert=false"
        else
          url = "https://docs.google.com/feeds/upload/create-session/default/private/full/#{id}?convert=false"
        end
        name = File.basename(filepath, '.*')
        @access_token.post(url, '', 'X-Upload-Content-Type' => content_type, 'X-Upload-Content-Length' => File.size(filepath).to_s, 'Slug' => name, 'GData-Version' => '3.0')
        if is_response_ok?
          location = @access_token.response.header["Location"]
          upload filepath, location, content_type
        else
          false
        end
      end
      
      # PUT
      def update(filepath, id, etag, content_type)
        name = File.basename(filepath, '.*')
        url = "https://docs.google.com/feeds/upload/create-session/default/private/full/#{id}"
        options = { 'If-Match' => etag, 'Content-Length' => '0', 'X-Upload-Content-Type' => content_type, 'X-Upload-Content-Length' => File.size(filepath).to_s, 'GData-Version' => '3.0' }
        @access_token.put(url, '', options)
        if is_response_ok?
          location = @access_token.response.header["Location"]
          upload filepath, location, content_type, etag
        else
          false
        end
      end
      
      # PUT
      def upload(filepath, location, content_type, etag=nil)
        url = location
        size = File.size(filepath)
        raw_file = File.open(filepath,"rb").readlines.join("")
        chunk = size / 524288 + ( size % 524288 > 0 ? 1 : 0 )
        chunk = 1 if chunk < 1
        nb = 0
        failed = false
        while chunk > nb and !failed
          chunk_size = 524288
          chunk_size = size if size < chunk_size
          bytes_start = chunk_size * nb
          bytes_end = chunk_size * (nb + 1) - 1
          bytes_end = size - 1 if bytes_end >= size
          bytes = raw_file[bytes_start..bytes_end]
          send_count = 0
          sending = true
          while send_count < 2 and sending
            content_length = (bytes_end - bytes_start + 1).to_s
            options = { 'Content-Length' => content_length, 'Content-Type' => content_type, 'Content-Range' => "bytes #{bytes_start}-#{bytes_end}/#{size}", 'GData-Version' => '3.0' }
            @access_token.put(url, bytes, options)
            if is_response_ok?
              sending = false
              url = @access_token.response.header["Location"] || url
            end
            send_count += 1
          end
          failed = true if sending
          nb += 1
        end
        !failed
      end
    end
  end
end
