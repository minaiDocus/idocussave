module FileDelivery::RemoteReport
  def get_remote_files(receiver, service_name, force = false)
    if type != 'NDF'
      not_delivered = not_delivered_preseizures(receiver, service_name, force)

      if !not_delivered.empty?
        remote_file = ::RemoteFile.new

        remote_file.receiver     = receiver
        remote_file.remotable    = self
        remote_file.pack         = pack
        remote_file.service_name = service_name
        remote_file.temp_path    = generate_csv_files(receiver, service_name, not_delivered)
        remote_file.preseizures  = not_delivered

        remote_file.save

        [remote_file]
      else
        []
      end
    else
      []
    end
  end


  def not_delivered_preseizures(receiver, service_name, force = false)
    not_delivered = []

    if force
      not_delivered = preseizures.by_position
    else
      delivered_preseizure_ids = remote_files.of(receiver, service_name)
                                             .where(temp_path: /\.csv/)
                                             .distinct(:preseizure_ids)
                                             .flatten
                                             .uniq

      not_delivered = preseizures.where.not(id: delivered_preseizure_ids).by_position
    end

    not_delivered
  end


  def csv_delivery_number(receiver, service_name)
    pack.remote_files.of(receiver, service_name).where(temp_path: /\.csv/).size + 1
  end


  def generate_csv_files(receiver, service_name, pres = preseizures)
    number = csv_delivery_number(receiver, service_name)

    data = PreseizuresToCsv.new(user, pres).execute

    basename = "#{name.tr(' ', '_')}-L#{number}"

    dir = Dir.mktmpdir("#{basename}__")

    file_path = File.join(dir, "#{basename}.csv")

    File.write(file_path, data)

    file_path
  end
end