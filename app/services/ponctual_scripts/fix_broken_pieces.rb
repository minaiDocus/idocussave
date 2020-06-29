class PonctualScripts::FixBrokenPieces < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    pieces_name.each do |piece_name|
      @piece = Pack::Piece.find_by_name piece_name
      temp_document = @piece.temp_document

      if temp_document && File.exist?(file_path)
        temp_document.cloud_content_object.attach( File.open(file_path), file_name )
        temp_document.cloud_content_object.reload.path

        @piece.recreate_pdf
        @piece.cloud_content_object.reload.path
        Pack::Piece.generate_thumbs(@piece.id)

        logger_infos "[BrokenPieces] - Piece_path: #{@piece.cloud_content_object.path.to_s} - done"
      else
        logger_infos "[BrokenPieces] - Piece: #{@piece.id.to_s} - No temp document found - File found : #{File.exist?(file_path).to_s}"
      end
    end
  end

  def file_path
    Rails.root.join('spec', 'support', 'files', 'ponctual_scripts', file_name)
  end

  def file_name
    "#{@piece.name.gsub(' ', '_').gsub('%', '_')}.pdf"
  end

  def pieces_name
    [ 'GMBA%LDT AC 202005 005',
      'GMBA%LDT AC 202005 006',
      'GMBA%LDT AC 202005 013',
      'GMBA%LDT AC 202005 014',
      'GMBA%LDT AC 202005 015',
      'GMBA%LDT AC 202005 016',
      'GMBA%LDT AC 202005 024',
      'GMBA%LDT AC 202005 025',
      'GMBA%LDT AC 202005 026',
      'GMBA%LDT AC 202005 027',
      'GMBA%LDT AC 202005 029' ]
  end
end

