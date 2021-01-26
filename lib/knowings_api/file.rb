class KnowingsApi::File
  EXTENSION = '.kzip'.freeze


  attr_accessor :filepath, :file_name, :pole_name, :data


  def initialize(filepath, options)
    @data      = options[:data]
    @filepath  = filepath
    @file_name = ::File.basename filepath
    @pole_name = options[:pole_name].presence || 'Pièces'
  end


  # Generates a kzip formated package with the document and meta informations as XML
  def create
    output_path = ''

    CustomUtils.mktmpdir('knowings_api_file', "/nfs/tmp/knowings/") do |dir|
      metapath    = create_meta(dir)
      basename    = ::File.basename(@file_name, '.pdf')
      output_path = ::File.join(dir, "#{basename}#{EXTENSION}")

      POSIX::Spawn.system "zip -j #{output_path} #{metapath} #{@filepath}"
    end

    output_path
  end


  def self.create(filepath, data)
    file = new(filepath, data)
    file.create
  end


  def meta
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.documents do
        @data.each do |options|
          xml.document do
            xml.properties do
              if options[:file_name].present?
                xml.name options[:file_name]
              else
                xml.name @file_name
              end

              xml.file @file_name
              xml.property KnowingsApi.visibility(options[:visibility]), name: 'pgec:etat', resolve: 'true'
              xml.property 'Pièces', create: 'false', name: 'pgec:documentType', resolve: 'true'
              xml.property options[:user_code], name: 'pgec:codeClient', transient: 'true'
              xml.property options[:user_company], create: 'true', name: 'pgec:clientTitle' if options[:user_company].present?
              xml.property @pole_name, create: 'true', name: 'pgec:poleName'

              if options[:exercise]
                xml.property 'Exercice', name: 'pgec:folderType'
                xml.property "#{options[:start_time].strftime('%Y-%m-%d')}T00:00:00+0#{options[:start_time].dst? ? 2 : 1}:00", name: 'pgec:from'
                xml.property "#{options[:end_time].strftime('%Y-%m-%d')}T00:00:00+0#{options[:end_time].dst? ? 2 : 1}:00", name: 'pgec:to'
              else
                xml.property 'Permanent', name: 'pgec:folderType'
              end

              xml.property "#{options[:date].strftime('%Y-%m')}-01T00:00:00+0#{options[:date].dst? ? 2 : 1}:00", name: 'pgec:mois' if options[:date].present?
              xml.property options[:domain], label: 'Domaine', resolve: 'true' if options[:domain].present?
              xml.property options[:nature], label: 'Nature', resolve: 'true' if options[:nature].present?
              xml.property options[:tiers], name: 'pgec:docTiers', resolve: 'true' if options[:tiers].present?
              xml.property (options[:is_pre_assigned] ? 'Oui' : 'Non'), name: 'pgec:choix6', resolve: 'true', create: 'true' unless options[:is_pre_assigned].nil?
            end
          end
        end
      end
    end

    builder.to_xml
  end


  def create_meta(dir)
    meta_path = ::File.join(dir, 'meta.xml')

    ::File.open(meta_path, 'w') do |f|
      f.puts meta
    end

    meta_path
  end
end
