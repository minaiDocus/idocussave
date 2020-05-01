require 'spec_helper'

describe Pack do
  before(:each) do
    DatabaseCleaner.start

    @organization = FactoryBot.create :organization, code: 'IDO'
    @user         = FactoryBot.create :user, code: 'IDO%LEAD', organization_id: @organization.id

    @pack         = FactoryBot.create :pack, owner: @user, organization: @organization , name: 'AC0003 AC 201812 all'
    @piece        = FactoryBot.create :piece, pack: @pack, user: @user, organization: @organization, name: 'AC0003 AC 201812 001'

    @piece.cloud_content_object.attach(File.open("#{Rails.root}/spec/support/files/2019090001.pdf"), 'AC0003_AC_201812_001.pdf')
    @piece.save
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  it 'add to archive', :add_to_archive do
    @pack.save_archive_to_storage

    expect(@pack.cloud_archive).to be_attached
    expect(@pack.cloud_archive_object.path).to match /tmp\/Pack\/20200430\/[0-9]\/AC0003_AC_201812_all\.zip/
    expect(File.exist?(@pack.cloud_archive_object.path)).to be true

    expect(@pack.cloud_archive_object.filename).to eq 'AC0003_AC_201812_all.zip'
  end
end