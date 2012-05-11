require "rexml/document"

module GoogleDocs
  class Service
    attr_accessor :token
    
    def initialize token
      @token = token
    end

    def make_folder name
      entry = <<-EOF
  <?xml version='1.0' encoding='UTF-8'?>
  <atom:entry xmlns:atom='http://www.w3.org/2005/Atom'>
    <atom:title>#{name}</atom:title>
    <atom:category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/docs/2007#folder' label='folder'/>
  </atom:entry>
  EOF
      
      @token.post ROOT_URL, entry, "Content-type" => "application/atom+xml", "GData-Version" => "1.0"
      is_response_ok?
    end
    
    def delete_resource resourceID
      @token.delete("#{ROOT_URL}/#{resourceID}")
      is_response_ok?
    end
    
    def upload_file file_path, folder_id=nil
      raw_file = open(file_path,"rb")
      filename = File.basename(file_path)
      
      url = ROOT_URL
      unless folder_id.nil?
        url += "/-/#{folder_id}"
      end
    
      @token.post url, raw_file, 'Content-type' => 'text/html', "slug" => filename
      is_response_ok?
    end
    
    def list_folder
      folders = []
      @token.get "#{ROOT_URL}/-/folder?showfolders=true"
      feed = REXML::Document.new(@token.response.body).root
      feed.elements.each('entry') do |entry|
        folder = {}
        folder[:title] = entry.elements['title'].text
        folder[:type] = entry.elements['category'].attribute('label').value
        folder[:updated] = entry.elements['updated'].text
        folder[:id] = entry.elements['id'].text
        entry.elements.each('link') do |link|
          folder[link.attribute('rel').value] = link.attribute('href').value
        end
        folders << folder
      end
      folders
    end
    
    def is_response_ok?
      if ["200","201"].include? @token.response.code
        true
      else
        false
      end
    end
  
  end
  
end