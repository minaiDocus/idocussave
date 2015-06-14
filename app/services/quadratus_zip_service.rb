# -*- encoding : UTF-8 -*-
class QuadratusZipService
  def initialize(preseizures)
    @preseizures = preseizures
  end

  def execute
    base_name = @preseizures.first.report.name.gsub(' ', '_')
    dir = Dir.mktmpdir
    QuadratusZipService.remove_temp_dir(dir)
    data = PreseizureToTxtService.new(@preseizures).execute
    File.open("#{dir}/#{base_name}.txt", 'w') do |f|
      f.write(data)
    end
    @preseizures.each do |preseizure|
      FileUtils.cp preseizure.piece.content.path, File.join(dir, preseizure.piece.number.to_s + '.pdf') if preseizure.piece.try(:content).try(:path)
    end
    file_path = File.join(dir, base_name + '.zip')
    Dir.chdir dir
    POSIX::Spawn::system "zip #{file_path} *"
    file_path
  end

  class << self
    def remove_temp_dir(dir)
      FileUtils.remove_dir dir if File.exist? dir
    end
    handle_asynchronously :remove_temp_dir, queue: 'remove temp dir', priority: 10, :run_at => Proc.new { 6.hours.from_now }
  end
end
