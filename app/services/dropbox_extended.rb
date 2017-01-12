# -*- encoding : UTF-8 -*-
module DropboxExtended
  def self.get_authorize_url
    @flow ||= DropboxOAuth2FlowNoRedirect.new(Dropbox::EXTENDED_APP_KEY, Dropbox::EXTENDED_APP_SECRET)

    @flow.start
  end


  def self.get_access_token(code)
    @flow ||= DropboxOAuth2FlowNoRedirect.new(Dropbox::EXTENDED_APP_KEY, Dropbox::EXTENDED_APP_SECRET)

    self.access_token, user_id = @flow.finish(code)

    reset_client

    access_token
  end


  def self.access_token
    Settings.first.dropbox_extended_access_token
  end


  def self.access_token=(token)
    Settings.first.dropbox_extended_access_token = token
  end


  def self.client
    @client ||= DropboxClient.new(access_token, Dropbox::EXTENDED_ACCESS_TYPE)
  end


  def self.reset_client
    @client = nil
  end


  def self.is_up_to_date(remote_filepath, filepath)
    path     = File.dirname(remote_filepath)
    filename = File.basename(remote_filepath)

    results = client.search(path, filename, 1)

    if results.any?
      size = results.first['bytes']

      if size == File.size(filepath)
        true
      else
        false
      end
    end
  end

  def self.is_not_up_to_date(remote_filepath, filepath)
    !is_up_to_date(remote_filepath, filepath)
  end

  def self.sync(remote_files)
    remote_files.each_with_index do |remote_file, index|
      tries           = 0
      remote_path     = ExternalFileStorage.delivery_path(remote_file, remote_file.receiver.dropbox_delivery_folder)
      remote_filepath = File.join(remote_path, remote_file.name)

      begin
        remote_file.sending!(remote_filepath)

        print "\t[#{'%0.3d' % (index + 1)}] \"#{remote_filepath}\" "

        if is_not_up_to_date(remote_filepath, remote_file.local_path)
          print 'sending...'

          client.put_file(remote_filepath.to_s, open(remote_file.local_path), true)

          print "done\n"
        else
          print "is up to date\n"
        end

        remote_file.synced!
      rescue => e
        tries += 1

        print "failed : [#{e.class}] #{e.message}\n"

        if tries < 3
          retry
        else
          puts "\t[#{'%0.3d' % (index + 1)}] Retrying later"
          remote_file.not_synced!("[#{e.class}] #{e.message}")
        end
      end
    end
  end
end
