module RegroupSheet
  def self.infos
    Dir.entries(RegroupSheet::INFOS_PATH).
        select { |e| e.match(/^\d{8}\.xml$/) }
  end

  def self.processed_infos
    Dir.entries(RegroupSheet::INFOS_PATH).
        select { |e| e.match(/_retour/) }.
        map { |e| e.sub('_retour','') }
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
        name = lot['name'].gsub('_',' ') + ' all'
        pack = Pack.find_by_name(name)
        if pack
          lot.css('piece').each do |piece|
            filespath = piece.css('sheet').map do |e|
              filename = "#{lot['name']}_%0.3d.pdf" % e.content
              File.join([RegroupSheet::CACHED_FILES_PATH,filename])
            end.join(' ')
            new_filename = "#{lot['name']}_#{'%0.3d' % piece['number']}.pdf"
            filesname << new_filename
            filepath = File.join([output_path,new_filename])
            `pdftk #{filespath} cat output #{filepath}`
          end
        end
      end
    end
    filesname
  end
end
