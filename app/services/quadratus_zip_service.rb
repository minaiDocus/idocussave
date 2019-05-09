# -*- encoding : UTF-8 -*-
# Generates a ZIP to import in quadratus
class QuadratusZipService
  def initialize(preseizures)
    @preseizures = preseizures
  end


  def execute
    base_name = @preseizures.first.report.name.tr(' ', '_').tr('%', '_')

    # Initialize a temp directory
    dir = Dir.mktmpdir(nil, "#{Rails.root}/tmp")
    FileUtils.chmod(0755, dir)

    QuadratusZipService.delay_for(6.hours).remove_temp_dir(dir)

    data = PreseizureToTxtService.new(@preseizures).execute # Generate a txt with preseizures

    File.open("#{dir}/#{base_name}.txt", 'w') do |f|
      f.write(data)
    end

    # Copy pieces to temp directory
    @preseizures.each do |preseizure|
      @piece = preseizure.piece
      FileUtils.cp @piece.content.path, File.join(dir, preseizure.piece.position.to_s + '.pdf') if preseizure.piece.try(:content).try(:path)
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
