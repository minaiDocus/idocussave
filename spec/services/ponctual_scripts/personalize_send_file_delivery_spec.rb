# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PonctualScripts::PersonalizeSendFileDelivery do
  before(:each) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2020,05,1))
  end

  after(:each) do
    Timecop.retur n
    DatabaseCleaner.clean
    DatabaseCleaner.clean_with(:truncation)
  end

  before(:each) do
    #@organization = FactoryBot.create :organization, code: 'FOO'
    #@user = FactoryBot.create :user, code: 'FOO%0366', organization_id: @organization.id
    organization = FactoryBot.create :organization, code: 'FOO'
    @user = FactoryBot.create :user, code: 'FOO%0366', organization_id: organization.id
    @user.create_options
    @user.create_notify
    @user.external_file_storage = ExternalFileStorage.create(user_id: @user.id)

    dropbox = @user.external_file_storage.dropbox_basic
    dropbox.access_token = 'K4z7I_InsgsAAAAAAAAAkZ76RjGf_qZVQ6y72HOjmCJ1FWGFufHC9ZGbfuqO3fQO'
    dropbox.save
    dropbox.enable

    pack = Pack.new
    pack.owner = @user
    pack.organization = organization
    pack.name = 'FOO%0366 AC 202005 all'
    pack.save
  end

  it 'delivers 1 file successfully' do    
    options = { users: [@user], type: FileDelivery::RemoteFile::ALL, force: true, delay: false }
    PonctualScripts::PersonalizeSendFileDelivery.execute(options)

    # expect(a_request(:post, "https://api.dropboxapi.com/2/files/list_folder"))
    # expect(a_request(:post, "https://content.dropboxapi.com/2/files/upload").with(headers: { 'Dropbox-Api-Arg' => { mode: { '.tag' => 'overwrite' }, path: "/FOO%0366/202005/AC/2pages.pdf" }.to_json }))
    # expect(a_request(:any, /.*/)).to have_been_made.times(4)

    remote = RemoteFile.last
    external_file_storage = ExternalFileStorage.last
    dropbox_basic = DropboxBasic.last

    expect(remote.remotable_type).to eq "Pack"
    expect(remote.service_name).to eq "Dropbox"
    expect(remote.state).to eq "waiting"
    expect(remote.receiver).to eq @user
    expect(dropbox_basic.external_file_storage).to eq external_file_storage
    expect(dropbox_basic.user).to eq @user

  end
end