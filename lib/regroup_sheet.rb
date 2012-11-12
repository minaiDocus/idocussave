module RegroupSheet
  def self.infos
    Dir.entries(RegroupSheet::INFOS_PATH).
        select { |e| e.match(/^\d{8}\.xml$/) }
  end

  def self.processed_infos
    Dir.entries(RegroupSheet::INFOS_PATH).
        select { |e| e.match(/^\d{8}\.txt$/) }.
        map { |e| e.sub('txt','xml') }
  end

  def self.not_processed_infos
    infos - processed_infos
  end

  def self.process
    filesname = []
    not_processed_infos.each do |filename|
      # assemble
      output_path = Pack::FETCHING_PATH
      file = File.open(File.join(RegroupSheet::INFOS_PATH,filename))
      doc = Nokogiri::XML(file)
      doc.css('lot').each do |lot|
        lot.css('piece').each do |piece|
          filespath = piece.css('feuilles').map do |e|
            filename = "#{lot['name']}_%0.3d.pdf" % e.content.to_i
            File.join([RegroupSheet::CACHED_FILES_PATH,filename])
          end
          new_filename = "#{lot['name']}_#{'%0.3d' % piece['number']}.pdf"
          filesname << new_filename
          filepath = File.join([output_path,new_filename])
          `pdftk #{filespath.join(' ')} cat output #{filepath}`
          filespath.each do |f|
            File.delete(f)
          end
        end
      end
      File.new(File.join(RegroupSheet::INFOS_PATH,filename.sub('.xml','.txt')))
    end
    filesname
  end
end
