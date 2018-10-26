class DocumentsExtentisExport
  DATELIMIT = '20181031'.freeze

  class << self
    def execute
      organizations = ['FBC', 'FIDA', 'FIDC']
      organizations.each do |org|
        new(Organization.find_by_code(org)).execute
      end
    end
  end

  def initialize(organization)
    @organization = organization
    @customers = organization.customers
  end

  def execute
    logger.info "--------------------------------------------------------------------------------------"
    logger.info "Processing #{@organization.name} at #{Time.now} => customers_count: #{@customers.size}"

    total_packs = total_pieces = total_pieces_not_found = total_mixed_doc_not_found = 0

    @customers.each do |customer|
      packs = customer.packs.where("DATE_FORMAT(created_at, '%Y%m%d') <= '#{DATELIMIT}'")

      logger.info " #{Time.now} Start #{customer.code} | packs_count : #{packs.size}"

      total_packs += packs.size

      packs.each do |pack|
        create_destination_path_of pack

        total_mixed_doc_not_found += 1 unless archive_mixed_document_of(pack)

        pieces = pack.pieces.where("DATE_FORMAT(created_at, '%Y%m%d') <= '#{DATELIMIT}'")

        logger.info "#{Time.now} >> Archiving pieces | #{pack.name} : pieces_count: #{pieces.count}"

        total_pieces += pieces.size

        pieces.each do |piece|
          total_pieces_not_found += 1 unless archive(piece)
        end
      end

      logger.info "#{Time.now} >> End #{customer.code}"
    end

    logger.info "Processing end #{@organization.name} > total_packs: #{total_packs} | total_pieces: #{total_pieces} | total_pieces_not_found: #{total_pieces_not_found} | total_mixed_doc_not_found: #{total_mixed_doc_not_found}"
  end


  private

  def base_path
    Pathname.new "/data/extentis_archives/#{@organization.code}"
  end

  def create_destination_path_of(pack)
    @current_pack_path = base_path.join pack.owner.code, period_of(pack), journal_of(pack)
    POSIX::Spawn.system("mkdir -p #{@current_pack_path}") unless File.exists? @current_pack_path
  end

  def journal_of(pack)
    pack.name.split[1]
  end

  def period_of(pack)
    pack.name.split[2]
  end

  def archive(piece)
    piece_path = piece.content.path
    if piece_path && File.exist?(piece_path)
      POSIX::Spawn.system("cp #{piece_path} #{@current_pack_path}")
      true
    else
      logger.info "Piece: #{piece.name} - #{piece.id}: piece pdf not found"
      false
    end
  end

  def archive_mixed_document_of(pack)
    original_path = pack.documents.mixed.first.try(:content).try(:path)
    if original_path && File.exist?(original_path)
      POSIX::Spawn.system("cp #{original_path} #{@current_pack_path}")
      true
    else
      logger.info "Pack: #{pack.name} - #{pack.id} : mixed document not found"
      false
    end
  end

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_extentis_processing.log")
  end
end
