# -*- encoding : UTF-8 -*-
class GoogleDriveSyncService
  attr_reader :client, :session

  def initialize(google_doc)
    @google_doc = google_doc
    @client = GoogleDrive::Client.new
  end

  def init_session
    begin
      if @google_doc.token.present? && @google_doc.token_expires_at && @google_doc.token_expires_at > 10.minutes.from_now
        @session = @client.load_session(@google_doc.token)
      elsif @google_doc.refresh_token.present?
        @session = @client.new_session(@google_doc.refresh_token)
        @google_doc.update(
          token: @client.access_token.token,
          token_expires_at: Time.at(@client.access_token.expires_at)
        )
      else
        @session = nil
      end
      @session.files if @session
    rescue Google::APIClient::AuthorizationError => e
      @session = nil
      @error = e
      case e.result.response.status
      when 401
        @google_doc.update(token: '', token_expires_at: nil)
        init_session
      when 403
        @google_doc.reset
      end
    end
    @session
  end

  def sync(remote_files)
    session = init_session
    if session
      remote_files.each_with_index do |remote_file, index|
        remote_path ||= ExternalFileStorage::delivery_path(remote_files.first, @google_doc.path)
        begin
          collection = session.root_collection.find_or_create_subcollections(remote_path)
        rescue => e
          remote_file.not_synced!("[#{e.class}] #{e.message}")
        end
        send_file(collection, remote_file, remote_path, index) if collection
      end
    else
      remote_files.each do |remote_file|
        if @error
          if @error.result.response.status.in?([401, 403])
            remote_file.not_synced!("#{@error.result.response.status}: Invalid Credentials.")
          else
            remote_file.not_synced!("#{@error.result.response.status}: #{@error.result.body}")
          end
        else
          remote_file.not_synced!("No credentials configured.")
        end
      end
    end
  end

  def send_file(collection, remote_file, remote_path, index)
    tries = 0
    begin
      basename = File.basename remote_file.local_path
      remote_filepath = File.join(remote_path, remote_file.name)
      remote_file.sending!(remote_filepath)
      print "\t[#{'%0.3d' % (index+1)}] #{remote_filepath} sending..."
      mimetype = DocumentTools.mimetype(basename)
      collection.upload_from_file(remote_file.local_path, basename, { content_type: mimetype })
      remote_file.synced!
      print "done\n"
    rescue => e
      tries += 1
      print " failed : [#{e.class}] #{e.message}\n"
      if tries < 3
        retry
      else
        puts "\t[#{'%0.3d' % (index+1)}] Retrying later"
        remote_file.not_synced!("[#{e.class}] #{e.message}")
      end
    end
  end
end
