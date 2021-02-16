# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PreAssignment::Builder::ExactOnline do
  def delivery_exact_online
    allow_any_instance_of(PreAssignment::CreateDelivery).to receive(:valid_exact_online?).and_return(true)
    allow_any_instance_of(User).to receive_message_chain('options.pre_assignment_date_computed?').and_return(false)
    allow(Settings).to receive_message_chain(:first, :notify_errors_to).and_return('test@idocus.com')

    preseizure   = FactoryBot.create :preseizure, user: @user, organization: @organization, report_id: @report.id, piece: @piece

    accounts = Pack::Report::Preseizure::Account.create([
                                                          { type: 1, number: '0000001', preseizure_id: preseizure.id },
                                                          { type: 2, number: '101000', preseizure_id: preseizure.id },
                                                          { type: 3, number: 'AR', preseizure_id: preseizure.id },
                                                        ])
    entries  = Pack::Report::Preseizure::Entry.create([
                                                        { type: 1, number: '1', amount: 1213.48, preseizure_id: preseizure.id, account_id: accounts[0].id },
                                                        { type: 2, number: '1', amount: 1011.23, preseizure_id: preseizure.id, account_id: accounts[1].id },
                                                        { type: 2, number: '1', amount: 202.25, preseizure_id: preseizure.id, account_id: accounts[2].id },
                                                      ])

    PreAssignment::CreateDelivery.new(preseizure, ['exact_online']).execute.first
  end

  def exercices
    exercises = [3].map do |it|
      exercise = OpenStruct.new
      exercise.end_date   = it.day.ago.to_date
      exercise.is_closed  = it.to_i == 2
      exercise.start_date = it.day.after.to_date

      exercise
    end


    exercises.each do |exercise|
      exercise.prev = exercises.select { |e| e.end_date == exercise.start_date - 1.day }.first
      exercise.next = exercises.select { |e| e.start_date == exercise.end_date + 1.day }.first
    end

    exercises
  end

  before(:all) do
    DatabaseCleaner.start
    Timecop.freeze(Time.local(2018,12,19))

    analytic = AnalyticReference.create(
                                          a1_name:"CASH",
                                          a1_references: '[{"ventilation":"100","axis1":"AACE","axis2":"ABCD","axis3":null},{"ventilation":"0","axis1":null,"axis2":null,"axis3":null},{"ventilation":"0","axis1":null,"axis2":null,"axis3":null}]',
                                          a2_name:"SAISON",
                                          a2_references: '[{"ventilation":"50","axis1":"AH11","axis2":null,"axis3":null},{"ventilation":"50","axis1":"PE09","axis2":null,"axis3":null},{"ventilation":"0","axis1":null,"axis2":null,"axis3":null}]'
                                        )

    @organization = FactoryBot.create :organization, code: 'IDO'
    @user         = FactoryBot.create :user, code: 'IDO%LEAD', organization_id: @organization.id, ibiza_id: '{595450CA-6F48-4E88-91F0-C225A95F5F16}'
    @report       = FactoryBot.create :report, user: @user, organization: @organization, name: 'AC0003 AC 201812'
    pack          = FactoryBot.create :pack, owner: @user, organization: @organization , name: (@report.name + ' all')
    @piece        = FactoryBot.create :piece, pack: pack, user: @user, organization: @organization, name: (@report.name + ' 001'), analytic_reference: analytic
    @piece_2      = FactoryBot.create :piece, pack: pack, user: @user, organization: @organization, name: (@report.name + ' 002')

    exact_online = Software::ExactOnline.create(
                                                user_name: "support.idocus",
                                                full_name: "Support idocus",
                                                email: "mina@idocus.com",
                                                state: "configured",
                                                encrypted_access_token: "QEVuQwBAEADf9SRYPeCkRyvPBJxFla9Z5YZQ8JQLjgMnoZRDz5/qmwbqx6Mn6OihvLqu/tFjy6+pd7iJfCkU87VD9tnXip6DPTDuBcyoOAU5sceQE4X4PjegcA/jwfbPkKkIqH23irQnhzSGlEPR5CITGX961S2zEHNWHppszgErMtIr7OozN63z9XDpev6SvAPnFCW4CrMQAI3KV8wEuBGckL3lmERe/i5xF3B1aLdz410YoP/i7ReOki5LIdoSKzVeAjW1F6wMVg7mMSlK2XhgcTNychYlYA6LhN3W2n4BgagOZMmjhAnh3PZdeOFc2rrBJ6XPueBNG59O5GzAgfar7lvIOQesn+EUoi+fIFUVO68HLzka+RMKdAOOPpbzmd7290L0y816xNN/vCF+1NcgUYR1FRWmdLIBrNerwvqZwpX0lcLKuW6uZS2AZ1Ivt7xeVXFRTeKWeas9m9XIkei9Ek0pYUwai0Rzmnw7RImq8IXyPIVp64C0A5pI0r5IvSf9IONEk0b/tXCTkzIvJjPvVRhWTjW92UHKLus0AOCXL8ajJo4mso+32WtGPCrBqQfbL4WYRhGbwLkhY9E1cDk4VDCQXLdmG+Z0oWn7oETQO/Si/Q0JXgsk5k1/yPQ3UzWVcVZ/C3B78WpC13jR2cIIOUVepqAzGElMdAgq2sR9gmgEgy8oaGZso9YNUCVTRWzVYeReI5TLDHcsmGiT6QWY2jm9uKek5Qh197+ppR+05axiNHiIUClmp/al1kICkUxZ4O1TiNkLPtzVgKUUcYr/YhwkHyY2JvE9N/jtfsXMcC1aaWcvaIqlIpK+wi4ILKRf6pMtduOD8D4e6qYMyemhANo2EJmfxN3Xf1G7CFh9u3h/8iIiDWNAKuPp/y82We/x1AN4YAnQZI9KnrHIH0/MIB2z3RYc",
                                                encrypted_refresh_token: "QEVuQwBAEABZ8sxaCQ4WblFVpBeelBJuGLQNudXIklhkxCI8Z9iwWCV4PxRerXkLMMg7tsYWqsjIzNP/nMQ5IdnH6QYtYJUV6VmENhT6ye0vCXht+bYBWQvnUmbjfEa2q5hxWZeGNNiKdWF+Qr+OLpPoc/iaFwuyAyL08LNbtLl9XvIPkbphYVMo3WXBL4zKGov7qUJHfAOWrneACIDQ9Pi9Ni/8SsMVfSYFI43xhjtP9PzLAEWD00jfkctI0virUSbN8MCAcRCgt87jrFYE43uoauqERedb90j9nsIWAZ4AGXG3paFY1bx7TWnQMdTD2Up/UeujSJcLjfDyav/kjnILKtIYLIN88FIh153k9gj0+7WAjji2CDWGuQMjrq4tpXEZT4n6lOyKH+l4JxcoHvqEG+btuZGkjAuSWMnMt2RLjMMdf8bEdBLGTw0BmqRjwV7TrcT0ZFw/kGTBBWcy74+kvZuiPgMKyRCN7ij/CTVJwosBfnq6Q7Hm7cEL4/BhspAJZbyE4fQ69w92cnwddbqg7pgr89JHY8GOShsBNf1R0ziDh13cuZo6mu1o3afqzTR/tA/fT3o=",
                                                encrypted_client_id: "QEVuQwBAEABuY7oFvWkfnvJ/Ct7qxgvsbcV+1flF9yEdlqiLo8LoZsOmBBVGcE+B5xH3wAOSCfgdbS0CxBKpVKRja+0stbO6",
                                                encrypted_client_secret: "QEVuQwBAEADa742TVShQZRXO41HR8OvTTLbKpBBWtP6ynQl+HpZ14A==",
                                                token_expires_at: 6.hours.ago,
                                                is_used: true,
                                                auto_deliver: 1,
                                                owner_type: 'User',
                                                owner_id: @user.id
                                              )
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe "Build pre assignment data", :data_builder do
    context "Exact Online", :exact_online_builder do
      it "create successfull txt data" do
        allow_any_instance_of(Pack::Report::Preseizure).to receive(:journal_name).and_return('60')
        delivery = delivery_exact_online

        result = VCR.use_cassette('pre_assignment/exact_online_delivery_data_building') do
          PreAssignment::Builder::ExactOnline.new(delivery).run
        end

        delivery.reload
        expect(delivery.state).to eq 'data_built'
        expect(delivery.data_to_deliver).to be nil
        expect(delivery.error_message).to eq ""

        expect(delivery.cloud_content).to be_attached

        expect(delivery.cloud_content_object.path).to match /tmp\/PreAssignmentDelivery\/20181219\/([0-9]+)\/AC0003_AC_201812_([0-9]+)\.txt/
        expect(File.exist?(delivery.cloud_content_object.path)).to be true
        expect(delivery.cloud_content_object.filename).to match /AC0003_AC_201812_([0-9]+)\.txt/
      end

      it "Building data error with undefined journal" do
        allow_any_instance_of(Pack::Report::Preseizure).to receive(:journal_name).and_return(nil)
        delivery = delivery_exact_online

        result = VCR.use_cassette('pre_assignment/exact_online_delivery_data_building') do
          PreAssignment::Builder::ExactOnline.new(delivery).run
        end

        delivery.reload
        expect(delivery.state).to eq 'error'
        expect(delivery.data_to_deliver).not_to be_present

        expect(delivery.cloud_content).not_to be_attached
        expect(delivery.cloud_content_object.path).to be nil
        expect(delivery.error_message).to eq 'Journal Exact Online introuvable'
      end
    end
  end
end