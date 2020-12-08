# -*- encoding : UTF-8 -*-
class PreseizureExport::GeneratePreAssignment
  def initialize(preseizures, export_type = nil)
    @export_type = export_type
    @all_preseizures = Array(preseizures)
  end

  def valid_ibiza?
    @report.user.uses?(:ibiza) && @report.user.try(:ibiza).try(:auto_deliver?) && @report.organization.try(:ibiza).try(:configured?) && @report.user.try(:ibiza).try(:ibiza_id?)
  end

  def valid_coala?
    @report.user.uses?(:coala) && @report.user.try(:coala).try(:auto_deliver?)
  end

  def valid_cegid?
    @report.user.uses?(:cegid) && @report.user.try(:cegid).try(:auto_deliver?)
  end

  def valid_fec_agiris?
    @report.user.uses?(:fec_agiris) && @report.user.try(:fec_agiris).try(:auto_deliver?)
  end

  def valid_quadratus?
    @report.user.uses?(:quadratus) && @report.user.try(:quadratus).try(:auto_deliver?)
  end

  def valid_csv_descriptor?
    @report.user.uses?(:csv_descriptor) && @report.user.try(:csv_descriptor).try(:auto_deliver?)
  end

  def execute
    group = @all_preseizures.group_by { |p| p.report }
    group.each do |g|
      @report = g.first
      @preseizures = Array(g.last)
      @is_notified = false

      ### ibiza not used for now
      # if valid_ibiza?
      #   create_pre_assignment_export_for('ibiza')
      #   generate_ibiza_export
      # end

      if valid_coala?
        create_pre_assignment_export_for('coala')
        generate_coala_export(true, true)
      end

      if valid_cegid?
        create_pre_assignment_export_for('cegid')
        generate_cegid_export
      end

      if valid_fec_agiris?
        create_pre_assignment_export_for('fec_agiris')
        generate_fec_agiris_export
      end

      if valid_quadratus?
        create_pre_assignment_export_for('quadratus')
        generate_quadratus_export(true)
      end

      if valid_csv_descriptor?
        create_pre_assignment_export_for('csv_descriptor')
        generate_csv_descriptor_export
      end
    end
  end

  def generate_on_demand
    @report = @all_preseizures.first.report
    @preseizures = @all_preseizures
    @is_notified = true

    case @export_type
    when 'csv'
      create_pre_assignment_export_for('csv_descriptor')

      generate_csv_descriptor_export(false)
    when 'xml_ibiza'
      create_pre_assignment_export_for('ibiza')

      generate_ibiza_export
    when 'txt_quadratus'
      create_pre_assignment_export_for('quadratus')

      generate_quadratus_export
    when 'zip_quadratus'
      create_pre_assignment_export_for('quadratus')

      generate_quadratus_export(true)
    when 'zip_coala'
      create_pre_assignment_export_for('coala')

      generate_coala_export(true)
    when 'xls_coala'
      create_pre_assignment_export_for('coala')

      generate_coala_export
    when 'txt_fec_agiris'
      create_pre_assignment_export_for('fec_agiris')

      generate_fec_agiris_export(false)
    when 'csv_cegid'
      create_pre_assignment_export_for('cegid')

      generate_cegid_export(false)
    when 'tra_cegid'
      create_pre_assignment_export_for('cegid')

      generate_cegid_tra_export(false)
    end

    @export
  end

private

  def generate_coala_export(to_zip = false, unzip_result = false)
    begin
      file = PreseizureExport::Software::Coala.new(@report.user, @preseizures, {preseizures_only: !to_zip, to_xls: true}).execute

      if to_zip
        if unzip_result
          POSIX::Spawn.system("unzip -o #{file} -d #{file_path}")
          rename_export 'coala'
          @export.got_success "#{file_real_name}.xls"
        else
          final_file_name = "#{file_real_name}.zip"
          FileUtils.mv file, "#{file_path}/#{final_file_name}"
          @export.got_success "#{final_file_name}"
        end
      else
        final_file_name = "#{file_real_name}.xls"
        FileUtils.mv file, "#{file_path}/#{final_file_name}"
        @export.got_success "#{final_file_name}"
      end
    rescue => e
      @export.got_error e
    end
  end

  def generate_cegid_export(with_file = true)
    begin
      file_csv = PreseizureExport::Software::Cegid.new(@preseizures, 'csv_cegid', @report.user).execute
      final_file_name = "#{file_real_name}.csv"
      FileUtils.mv file_csv, "#{file_path}/#{final_file_name}"

      if with_file
        @preseizures.each do |preseizure|
          FileUtils.cp preseizure.piece.cloud_content_object.path, "#{file_path}/#{preseizure.piece.position.to_s}.pdf" if preseizure.piece
        end
      end

      @export.got_success "#{final_file_name}"
    rescue => e
      @export.got_error e
    end
  end


  # NO TIMESTAMPS FOR CEGID TRA
  def generate_cegid_tra_export(with_file = true)
    begin
      file_zip = PreseizureExport::Software::Cegid.new(@preseizures, 'tra_cegid').execute

      final_file_name = "#{file_previous_name}.zip"

      FileUtils.mv file_zip, "#{file_path}/#{final_file_name}"

      @export.got_success "#{file_previous_name}.zip"
    rescue => e
      @export.got_error e
    end
  end

  def generate_fec_agiris_export(with_file = true)
    begin
      file_txt = PreseizureExport::Software::FecAgiris.new(@preseizures).execute
      final_file_name = "#{file_real_name}.txt"
      FileUtils.mv file_txt, "#{file_path}/#{final_file_name}"

      if with_file
        @preseizures.each do |preseizure|
          FileUtils.cp preseizure.piece.cloud_content_object.path, "#{file_path}/#{preseizure.piece.position.to_s}.pdf" if preseizure.piece
        end
      end

      @export.got_success "#{final_file_name}"
    rescue => e
      @export.got_error e
    end
  end

  def generate_quadratus_export(to_zip=false)
    begin
      file_zip = PreseizureExport::Software::Quadratus.new(@preseizures).execute
      if to_zip
        final_file_name = "#{file_real_name}.zip"
        FileUtils.mv file_zip, "#{file_path}/#{final_file_name}"
        @export.got_success "#{final_file_name}"
      else
        POSIX::Spawn.system("unzip -o #{file_zip} -d #{file_path}")
        rename_export 'quadratus'
        @export.got_success "#{file_real_name}.txt"
      end
    rescue => e
      @export.got_error e
    end
  end

  def generate_csv_descriptor_export(with_file = true)
    begin
      data = PreseizureExport::PreseizuresToCsv.new(@report.user, @preseizures).execute
      File.open("#{file_path}/#{file_real_name}.csv", 'w') { |file| file.write(data) }

      if with_file
        @preseizures.each do |preseizure|
          FileUtils.cp preseizure.piece.cloud_content_object.path, "#{file_path}/#{preseizure.piece.position.to_s}.pdf" if preseizure.piece
        end
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

      exercise = IbizaLib::ExerciseFinder.new(@report.user, date, ibiza).execute
      if exercise
        data = IbizaLib::Api::Utils.to_import_xml(exercise, @preseizures, ibiza)
        File.open("#{file_path}/#{file_real_name}.xml", 'w') { |file| file.write(data[:data_built]) }
        @export.got_success "#{file_real_name}.xml"
      else
        @export.got_error "Exercise ibiza not found", false
      end
    rescue => e
      @export.got_error e
    end
  end

  def file_previous_name
    @report.name.tr(' ', '_').tr('%', '_')
  end

  def file_real_name
    return @real_name if @real_name.present?
    @real_name = "#{file_previous_name}_#{Time.now.strftime('%d%m%y_%H%M%S')}"
  end

  def file_path
    FileUtils.mkdir_p @export.path unless File.exists? @export.path

    CustomUtils.add_chmod_access_into(@export.path)

    @export.path
  end

  def rename_export(software)
    if software == 'quadratus'
      File.rename("#{file_path}/#{file_previous_name}.txt", "#{file_path}/#{file_real_name}.txt")
    elsif software == 'coala'
      File.rename("#{file_path}/#{file_previous_name}.xls", "#{file_path}/#{file_real_name}.xls")
    elsif software == 'cegid_tra'
      File.rename("#{file_path}/#{file_previous_name}.zip", "#{file_path}/#{file_real_name}.zip")
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
    @export.is_notified    = @is_notified
    @export.save
  end
end
