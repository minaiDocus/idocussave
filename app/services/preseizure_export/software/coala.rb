# -*- encoding : UTF-8 -*-
class PreseizureExport::Software::Coala
  def initialize(user, preseizures, options={})
    @preseizures = preseizures
    @user = user
    @options =  {
                  preseizures_only: options[:preseizures_only] || false,
                  to_xls: options[:to_xls] || false
                }
  end

  def execute
    base_name = @preseizures.first.report.name.tr(' ', '_').tr('%', '_')
    file_path = ''

    CustomUtils.mktmpdir('coala_export', nil, false) do |dir|
      PreseizureExport::Software::Coala.delay_for(6.hours).remove_temp_dir(dir)
      data = PreseizureExport::PreseizuresToCsv.new(@user, @preseizures, 'coala').execute

      if @options[:to_xls]
        file = OpenStruct.new({path: "#{dir}/#{base_name}.xls", close: nil})
        data_array = data.split("\n")
        xls_data = []
        data_array.each do |d|
          xls = d.split(';')
          tmp_data = {}
          xls.each_with_index do |o, i|
            tmp_data["field_#{i.to_s}".to_sym] = o
          end
          xls_data << OpenStruct.new(tmp_data)
        end

        ToXls::Writer.new(xls_data, columns: [:field_0, :field_1, :field_2, :field_3, :field_4, :field_5, :field_6, :field_7], headers: false).write_io(file.path)
      else
        file = File.open("#{dir}/#{base_name}.csv", 'w')
        file.write(data)
      end

      if @options[:preseizures_only]
        file_path = file.path
        file.close
      else
        file.close
        @preseizures.each do |preseizure|
          entry = preseizure.entries.first
          file_name = preseizure.coala_piece_name + '.pdf'
          FileUtils.cp preseizure.piece.cloud_content_object.path, File.join(dir, file_name) if preseizure.type.nil? && File.exist?(preseizure.piece.cloud_content_object.try(:path).to_s)
        end
        file_path = File.join(dir, base_name + '.zip')
        Dir.chdir dir
        POSIX::Spawn::system "zip #{file_path} *"
      end
    end

    file_path
  end

  class << self
    def remove_temp_dir(dir)
      FileUtils.remove_entry dir if File.exist? dir
    end
  end
end
