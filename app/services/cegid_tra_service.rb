class CegidTraService
  def initialize(preseizures)
    @preseizures = preseizures
  end


  def execute
    base_name = @preseizures.first.report.name.tr(' ', '_').tr('%', '_')

    # Initialize a temp directory
    dir = Dir.mktmpdir(nil, "#{Rails.root}/tmp")
    FileUtils.chmod(0755, dir)

    CegidTraService.delay_for(6.hours).remove_temp_dir(dir)

    data = PreseizureToTxtService.new(@preseizures).execute("cegid_tra") # Generate a txt with preseizures

    File.open("#{dir}/#{base_name}.tra", 'w') do |f|
      f.write(data)
    end

    # Copy pieces to temp directory
    @preseizures.each do |preseizure|
      @piece = preseizure.piece
      FileUtils.cp @piece.cloud_content_object.path, File.join(dir, preseizure.piece.name.tr(' ', '_').tr('%', '_') + '.pdf') if preseizure.piece
    end

    file_path = File.join(dir, base_name + '.zip')

    Dir.chdir dir

    # Finaly zip the temp dir
    POSIX::Spawn.system "zip #{file_path} *"

    file_path
  end


  def self.remove_temp_dir(dir)
    FileUtils.remove_dir dir if File.exist? dir
  end
end