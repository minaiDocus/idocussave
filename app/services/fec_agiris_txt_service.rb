# -*- encoding : UTF-8 -*-
class FecAgirisTxtService
  def initialize(preseizures)
    @preseizures = preseizures
  end


  def execute
    base_name = @preseizures.first.report.name.tr(' %', '__')

    # Initialize a temp directory
    dir = Dir.mktmpdir(nil, "#{Rails.root}/tmp")
    FileUtils.chmod(0755, dir)

    FecAgirisTxtService.delay_for(6.hours).remove_temp_dir(dir)

    data = PreseizureToTxtService.new(@preseizures).execute("fec_agiris") # Generate a txt with preseizures

    File.open("#{dir}/#{base_name}.txt", 'w') do |f|
      f.write(data)
    end

    file_path = "#{dir}/#{base_name}.txt"

    Dir.chdir dir

    file_path
  end


  def self.remove_temp_dir(dir)
    FileUtils.remove_dir dir if File.exist? dir
  end
end