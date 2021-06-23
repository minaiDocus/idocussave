class PreseizureExport::Software::FecAcd
  def initialize(preseizures)
    @preseizures = preseizures
  end


  def execute
    base_name = @preseizures.first.report.name.tr(' %', '__')
    file_path = ''

    CustomUtils.mktmpdir('fec_acd_export', nil, false) do |dir|
      PreseizureExport::Software::FecAcd.delay_for(6.hours).remove_temp_dir(dir)

      data = PreseizureExport::PreseizureToTxt.new(@preseizures).execute("fec_acd") # Generate a txt with preseizures

      File.open("#{dir}/#{base_name}.txt", 'w') do |f|
        f.write(data)
      end

      file_path = "#{dir}/#{base_name}.txt"

      Dir.chdir dir
    end

    file_path
  end


  def self.remove_temp_dir(dir)
    FileUtils.remove_entry dir if File.exist? dir
  end
end