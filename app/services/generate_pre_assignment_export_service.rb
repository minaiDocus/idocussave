# -*- encoding : UTF-8 -*-
class GeneratePreAssignmentExportService
  def initialize(preseizures)
    @all_preseizures = Array(preseizures)
  end

  def valid_ibiza?
    @report.user.uses_ibiza? && @report.user.try(:softwares).try(:ibiza_auto_deliver?) && @report.organization.try(:ibiza).try(:configured?) && @report.user.try(:ibiza_id).try(:present?)
  end

  def valid_coala?
    @report.user.uses_coala? && @report.user.try(:softwares).try(:coala_auto_deliver?)
  end

  def valid_quadratus?
    @report.user.uses_quadratus? && @report.user.try(:softwares).try(:quadratus_auto_deliver?)
  end

  def valid_csv_descriptor?
    @report.user.uses_csv_descriptor? && @report.user.try(:softwares).try(:csv_descriptor_auto_deliver?)
  end

  def execute
    group = @all_preseizures.group_by { |p| p.report }
    group.each do |g|
      @report = g.first
      @preseizures = Array(g.last)

      ### ibiza not used for now
      # if valid_ibiza?
      #   create_pre_assignment_export_for 'ibiza'
      #   generate_ibiza_export
      # end

      if valid_coala?
        create_pre_assignment_export_for 'coala'
        generate_coala_export
      end

      if valid_quadratus?
        create_pre_assignment_export_for 'quadratus'
        generate_quadratus_export
      end

      if valid_csv_descriptor?
        create_pre_assignment_export_for 'csv_descriptor'
        generate_csv_descriptor_export
      end
    end
  end

private

  def generate_coala_export
    begin
      file_zip = CoalaZipService.new(@report.user, @preseizures, {to_xls: true}).execute
      POSIX::Spawn.system("unzip -o #{file_zip} -d #{file_path}")
      rename_export 'coala'
      @export.got_success "#{file_real_name}.xls"
    rescue => e
      @export.got_error e
    end
  end

  def generate_quadratus_export
    begin
      file_zip = QuadratusZipService.new(@preseizures).execute
      POSIX::Spawn.system("unzip -o #{file_zip} -d #{file_path}")
      rename_export 'quadratus'
      @export.got_success "#{file_real_name}.txt"
    rescue => e
      @export.got_error e
    end
  end

  def generate_csv_descriptor_export
    begin
      data = PreseizuresToCsv.new(@report.user, @preseizures).execute
      File.open("#{file_path}/#{file_real_name}.csv", 'w') { |file| file.write(data) }
      @preseizures.each do |preseizure|
        FileUtils.cp preseizure.piece.content.path, "#{file_path}/#{preseizure.piece.position.to_s}.pdf" if preseizure.piece.try(:content).try(:path)
      end
      @export.got_success "#{file_real_name}.csv"
    rescue => e
      @export.got_error e
    end
  end

  def generate_ibiza_export
    begin
      ibiza = @report.organization.ibiza
      date = DocumentTools.to_period(@report.name)

      exercise = IbizaExerciseFinder.new(@report.user, date, ibiza).execute
      if exercise
        data = IbizaAPI::Utils.to_import_xml(exercise, @preseizures, ibiza.description, ibiza.description_separator, ibiza.piece_name_format, ibiza.piece_name_format_sep)
        File.open("#{file_path}/#{file_real_name}.xml", 'w') { |file| file.write(data) }
        @export.got_success "#{file_path}.xml"
      else
        @export.got_error "Exercise ibiza not found", false
      end
    rescue => e
      @export.got_error e
    end
  end

  def file_previous_name
    @report.name.tr(' ', '_')
  end

  def file_real_name
    "#{file_previous_name}_#{Time.now.strftime('%d%m%y_%H%M%S')}"
  end

  def file_path
    FileUtils.mkdir_p @export.path unless File.exists? @export.path

    ##TO DO: desabled for now
    #generate .htaccess file after path creation
    # unless File.exist? @export.base_path.join('.htaccess')
    #   File.open(@export.base_path.join('.htaccess'), 'w') do |f|
    #     f.write("Require group #{@report.user.code.gsub(/[%]/, '_')}")
    #   end
    # end

    @export.path
  end

  def rename_export(software)
    if software == 'quadratus'
      File.rename("#{file_path}/#{file_previous_name}.txt", "#{file_path}/#{file_real_name}.txt")
    elsif software == 'coala'
      File.rename("#{file_path}/#{file_previous_name}.xls", "#{file_path}/#{file_real_name}.xls")
    else
      File.rename("#{file_path}/#{file_previous_name}.csv", "#{file_path}/#{file_real_name}.csv")
    end
  end

  def create_pre_assignment_export_for(software)
    @software = software
    @export                = PreAssignmentExport.new
    @export.report         = @report
    @export.for            = @software
    @export.user           = @report.user
    @export.organization   = @report.organization
    @export.pack_name      = @report.name
    @export.total_item     = @preseizures.size
    @export.preseizures    = @preseizures
    @export.save
  end
end
