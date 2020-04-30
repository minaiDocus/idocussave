require 'spec_helper'

describe Pack do
  before(:each) do
    Pack.destroy_all
    AnalyticReference.destroy_all
    User.destroy_all
    Organization.destroy_all
    Pack::Piece.destroy_all

    analytic = AnalyticReference.create(
                                          a1_name:"CASH",
                                          a1_references: '[{"ventilation":"100","axis1":"AACE","axis2":"ABCD","axis3":null},{"ventilation":"0","axis1":null,"axis2":null,"axis3":null},{"ventilation":"0","axis1":null,"axis2":null,"axis3":null}]',
                                          a2_name:"SAISON",
                                          a2_references: '[{"ventilation":"50","axis1":"AH11","axis2":null,"axis3":null},{"ventilation":"50","axis1":"PE09","axis2":null,"axis3":null},{"ventilation":"0","axis1":null,"axis2":null,"axis3":null}]'
                                        )

    @organization = FactoryBot.create :organization, code: 'IDO'
    @user         = FactoryBot.create :user, code: 'IDO%LEAD', organization_id: @organization.id, ibiza_id: '{595450CA-6F48-4E88-91F0-C225A95F5F16}'
    @report       = FactoryBot.create :report, user: @user, organization: @organization, name: 'AC0003 AC 201812'
    @pack         = FactoryBot.create :pack, owner: @user, organization: @organization , name: (@report.name + ' all')
    @piece        = FactoryBot.create :piece, pack: @pack, user: @user, organization: @organization, name: (@report.name + ' 001'), analytic_reference: analytic
    @piece.cloud_content.attach(Rack::Test::UploadedFile.new("#{Rails.root}/spec/support/files/2019090001.pdf"))
    @piece.save
  end
  

  it 'add to archive', :add_to_archive do
    @pack.reload
    @pack.add_to_archive

    expect(@pack.cloud_archive).to be_attached
    expect(@pack.cloud_archive_object.path).to match /tmp\/Pack\/20200430\/[0-9]\/AC0003_AC_201812_all\.zip/
    expect(File.exist?(@pack.cloud_archive_object.path)).to be true

    expect(@pack.cloud_archive_object.filename).to eq 'AC0003_AC_201812_all.zip'
  end
end