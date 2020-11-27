# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PreAssignment::Builder::MyUnisoft do
  def delivery_my_unisoft
    allow_any_instance_of(CreatePreAssignmentDeliveryService).to receive(:valid_my_unisoft?).and_return(true)
    allow_any_instance_of(User).to receive_message_chain('options.pre_assignment_date_computed?').and_return(false)
    allow(Settings).to receive_message_chain(:first, :notify_errors_to).and_return('test@idocus.com')

    preseizure   = FactoryBot.create :preseizure, user: @user, organization: @organization, report_id: @report.id, piece: @piece

    accounts = Pack::Report::Preseizure::Account.create([
                                                          { type: 1, number: 'A7 AUTO PIECES', preseizure_id: preseizure.id },
                                                          { type: 2, number: 'ABSOLUTE', preseizure_id: preseizure.id },
                                                          { type: 3, number: 'ACMS', preseizure_id: preseizure.id },
                                                        ])
    entries  = Pack::Report::Preseizure::Entry.create([
                                                        { type: 1, number: 'ACTION', amount: 1213.48, preseizure_id: preseizure.id, account_id: accounts[0].id },
                                                        { type: 2, number: 'AERO', amount: 1011.23, preseizure_id: preseizure.id, account_id: accounts[1].id },
                                                        { type: 2, number: 'ALLBATTERIES', amount: 202.25, preseizure_id: preseizure.id, account_id: accounts[2].id },
                                                      ])

    CreatePreAssignmentDeliveryService.new(preseizure, ['my_unisoft']).execute.first
  end

  before(:all) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2020,11,24))

    @organization = FactoryBot.create :organization, code: 'IDO'
    @user         = FactoryBot.create :user, code: 'IDO%LEAD', organization_id: @organization.id
    @report       = FactoryBot.create :report, user: @user, organization: @organization, name: 'AC0003 AC 202011'
    pack          = FactoryBot.create :pack, owner: @user, organization: @organization , name: (@report.name + ' all')
    @piece        = FactoryBot.create :piece, pack: pack, user: @user, organization: @organization, name: (@report.name + ' 001')
    @piece_2      = FactoryBot.create :piece, pack: pack, user: @user, organization: @organization, name: (@report.name + ' 002')

    AccountBookType.create(user_id: @user.id, name: 'AC', description: '( Achat )', pseudonym: "20")

    my_unisoft    = Software::MyUnisoft.create( encrypted_api_token: "QEVuQwBAEAByOREAFhHULN2CJGaf125G4YhHmu/s35ujaoOnwQc65t/n8HeJfIfBhI2aU0wt73fJCiLh51pa9bkB79K61o7Xvru4rIX2v4q+SAkGZrwM04HpoBLNzCaYTQwOKSlkgpbltj3kwv9uJsv+Ug2jGGD5LIxCHqS9MnBILfAmW2aJyUaoJxyAG+sAspfSHkJMHO1YN6+1i9lGqXTbQNWjx8wU0YcOJiemBlx3I1L/WVrRxg==", society_id: 3, organization_id: 7, user_id: @user.id, customer_auto_deliver: 1, organization_used: true, user_used: true, auto_update_accounting_plan: true)
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe "Build pre assignment data", :data_builder do
    context "My Unisoft", :my_unisoft_builder do
      it "create successfull txt data" do
        allow_any_instance_of(Pack::Report::Preseizure).to receive(:journal_name).and_return('AC')        
        allow_any_instance_of(Pack::Piece).to receive_message_chain('cloud_content_object.path').and_return("#{Rails.root}/spec/support/files/2019100001.pdf")
        allow(Base64).to receive(:encode64).with(any_args).and_return('JVBERi0xLjQKJeLjz9MKMSAwIG9iaiAKPDwKL0Zvcm1UeXBlIDEKL1N1YnR5\ncGUgL0Zvcm0KL1Jlc291cmNlcyAKPDwKL0ZvbnQgCjw8Ci9GMS4wIDIgMCBS\nCj4+Ci9Qcm9jU2V0IFsvUERGIC9UZXh0IC9JbWFnZUIgL0ltYWdlQyAvSW1h\nZ2VJXQo+PgovVHlwZSAvWE9iamVj==')
        delivery = delivery_my_unisoft

        result = VCR.use_cassette('pre_assignment/my_unisoft_delivery_data_building') do
          PreAssignment::Builder::MyUnisoft.new(delivery).run
        end

        delivery.reload
        expect(delivery.state).to eq 'data_built'
        expect(delivery.data_to_deliver).to be nil
        expect(delivery.error_message).to eq ""

        expect(delivery.cloud_content).to be_attached

        expect(delivery.cloud_content_object.path).to match /tmp\/PreAssignmentDelivery\/20201124\/([0-9]+)\/AC0003_AC_202011_([0-9]+)\.txt/
        expect(File.exist?(delivery.cloud_content_object.path)).to be true
        expect(delivery.cloud_content_object.filename).to match /AC0003_AC_202011_([0-9]+)\.txt/
      end

      it "Building data error with undefined journal" do
        allow_any_instance_of(Pack::Report::Preseizure).to receive(:journal_name).and_return(nil)
        delivery = delivery_my_unisoft

        result = VCR.use_cassette('pre_assignment/my_unisoft_delivery_data_building') do
          PreAssignment::Builder::MyUnisoft.new(delivery).run
        end

        delivery.reload
        expect(delivery.state).to eq 'error'
        expect(delivery.data_to_deliver).not_to be_present

        expect(delivery.cloud_content).not_to be_attached
        expect(delivery.cloud_content_object.path).to be nil
        expect(delivery.error_message).to match /Aucune correspondance de journal/
      end

      it 'Building data error with unknown account' do
        allow_any_instance_of(Pack::Report::Preseizure).to receive(:journal_name).and_return('AC')
        allow_any_instance_of(Pack::Report::Preseizure::Entry).to receive(:number).and_return('ASCM')
        delivery = delivery_my_unisoft

        result = VCR.use_cassette('pre_assignment/my_unisoft_delivery_data_building') do
          PreAssignment::Builder::MyUnisoft.new(delivery).run
        end

        delivery.reload
        expect(delivery.state).to eq 'error'
        expect(delivery.data_to_deliver).not_to be_present

        expect(delivery.cloud_content).not_to be_attached
        expect(delivery.cloud_content_object.path).to be nil
        expect(delivery.error_message).to match /Aucune correspondance du compte/
      end
    end
  end
end