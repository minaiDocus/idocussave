module Pack::Utils
  def infos
    Dir.entries(Pack::Utils::INFOS_PATH).
        select { |e| e.match(/^\d{8}\.xml$/) }
  end

  def processed_infos
    Dir.entries(Pack::Utils::INFOS_PATH).
        select { |e| e.match(/_retour/) }.
        map { |e| e.sub('_retour','') }
  end

  def not_processed_infos
    infos - processed_infos
  end

  def regroup_files
    not_processed_infos.each do |filename|
      pack_infos = []
      # assemble
      output_path = "#{Rails.root}/tmp/input_pdf_auto"
      file = File.open(File.join(Pack::Utils::FILES_PATH,filename))
      doc = Nokogiri::XML(file)
      doc.css('lot').each do |lot|
        name = lot['name'].gsub('_',' ') + ' all'
        pack = Pack.find_by_name(name)
        if pack
          lot.css('piece').each do |piece|
            filespath = piece.css('sheet').map do |e|
              File.join([Pack::Utils::CACHED_FILES_PATH,e.content])
            end.join(' ')
            new_filename = "#{lot['name']}_#{'%0.3d' % piece['number']}.pdf"
            filepath = File.join([output_path,new_filename])
            `pdftk #{filespath} cat output #{filepath}`
          end
          pack_infos << [lot['name'],pack.divisions.pieces.by_position.last.position + 1]
        end
      end
      # return related number
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.assemble {
          pack_infos.each do |info|
            xml.lot(info[1], name: info[0])
          end
        }
      end
      filepath = File.join(Pack::Utils::FILES_PATH,filename.sub('.pdf','_retour.pdf'))
      File.open(filepath,'w') do |f|
        f.write builder.to_xml
      end
    end
  end
end