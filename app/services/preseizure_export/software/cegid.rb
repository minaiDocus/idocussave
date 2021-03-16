# -*- encoding : UTF-8 -*-
class PreseizureExport::Software::Cegid
  def initialize(preseizures, software_type, user=nil)
    @preseizures   = preseizures
    @user          = user
    @software_type = software_type
  end

  def execute
    @base_name = @preseizures.first.report.name.tr(' ', '_').tr('%', '_')
    file_path  = ''

    CustomUtils.mktmpdir('cegid_export', nil, false) do |dir|
      @dir      = dir
      PreseizureExport::Software::Cegid.delay_for(6.hours).remove_temp_dir(@dir)

      file_path = @software_type == 'csv_cegid' ? cegid : cegid_tra
    end

     file_path
  end

  class << self
    def remove_temp_dir(dir)
      FileUtils.remove_entry dir if File.exist? dir
    end
  end

  private

  def cegid
    data = PreseizureExport::PreseizuresToCsv.new(@user, @preseizures, 'cegid').execute
    file = File.open("#{@dir}/#{@base_name}.csv", 'w')
    file.write(data)
    file_path = file.path
    file.close

    file_path
  end

  def cegid_tra
    data = PreseizureExport::PreseizureToTxt.new(@preseizures).execute("cegid_tra") # Generate a txt with preseizures

    File.open("#{@dir}/#{@base_name}.tra", 'w') do |f|
      f.write(data)
    end

    # Copy pieces to temp directory
    @preseizures.each do |preseizure|
      @piece = preseizure.piece
      FileUtils.cp @piece.cloud_content_object.path, File.join(@dir, preseizure.piece.name.tr(' ', '_').tr('%', '_') + '.pdf') if preseizure.piece
    end

    file_path = File.join(@dir, @base_name + '.zip')

    Dir.chdir @dir

    # Finaly zip the temp @dir
    POSIX::Spawn.system "zip #{file_path} *"

    file_path
  end
end
