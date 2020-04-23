# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PreAssignmentDelivery do
  def delivery_exact_online
    allow_any_instance_of(CreatePreAssignmentDeliveryService).to receive(:valid_exact_online?).and_return(true)
    allow_any_instance_of(User).to receive_message_chain('options.pre_assignment_date_computed?').and_return(false)
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
    CreatePreAssignmentDeliveryService.new(preseizure, ['exact_online']).execute.first
  end

  def delivery_ibiza
    allow_any_instance_of(CreatePreAssignmentDeliveryService).to receive(:valid_ibiza?).and_return(true)
    allow_any_instance_of(User).to receive_message_chain('options.pre_assignment_date_computed?').and_return(false)
    preseizure   = FactoryBot.create :preseizure, user: @user, organization: @organization, report_id: @report.id, piece: @piece
    accounts = Pack::Report::Preseizure::Account.create([
                                                          { type: 1, number: '601109', preseizure_id: preseizure.id },
                                                          { type: 2, number: '471000', preseizure_id: preseizure.id },
                                                          { type: 3, number: '471001', preseizure_id: preseizure.id },
                                                        ])
    entries  = Pack::Report::Preseizure::Entry.create([
                                                        { type: 1, number: '1', amount: 1213.48, preseizure_id: preseizure.id, account_id: accounts[0].id },
                                                        { type: 2, number: '1', amount: 1011.23, preseizure_id: preseizure.id, account_id: accounts[1].id },
                                                        { type: 2, number: '1', amount: 202.25, preseizure_id: preseizure.id, account_id: accounts[2].id },
                                                      ])
    CreatePreAssignmentDeliveryService.new(preseizure, ['ibiza']).execute.first
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
    # pack = Pack.new
    # pack.owner = @user
    # pack.name = @report.name + ' all'
    # pack.save
    # @piece = Pack::Piece.new
    # @piece.pack = pack
    # @piece.name = @report.name + ' 001'
    # @piece.origin = 'upload'
    # @piece.position = 1
    # @piece.analytic_reference = nil
    # @piece.save

    ibiza = Ibiza.create(
                          state: 'valid',
                          state_2: 'none',
                          is_auto_deliver: true,
                          description: JSON.parse('{"operation_label":{"is_used":"1", "position":"1"}, "date":{"is_used":"1", "position":"1"}, "third_party":{"is_used":"1", "position":"1"}, "amount":{"is_used":"1", "position":"1"}, "currency":{"is_used":"1", "position":"1"}, "conversion_rate":{"is_used":"1", "position":"1"}, "observation":{"is_used":"1", "position":"1"}, "journal":{"is_used":"1", "position":"1"}, "piece_name":{"is_used":"1", "position":"1"}, "piece_number":{"position":"1"}}'),
                          description_separator: ' - ',
                          piece_name_format: JSON.parse('{"code":{"position":"1"}, "code_wp":{"position":"1"}, "journal":{"position":"1"}, "period":{"position":"1"}, "number":{"position":"1"}}'),
                          piece_name_format_sep: ' ',
                          organization_id: @organization.id,
                          encrypted_access_token: "QEVuQwBAEAAFaLtTv1HNQw8upA22aJCPDGe4xq6/kup2Tak02HH27rM+nqSgsBms4CpT1KSMLWMwZilQOuAZK6ZPddXrki6NcddOn/uDw+7DzyBp17G5wYfiIMXHCdZuBGWVj2/g/4f0hWOh4e4jeUK3Qzyl3Qe5RMTPmQpeeUD2h2ae2gXmmZ+CwBs88lJk6KW+/3QUhFUHZ4uZWKV1CUUrwocjM51UFph6PiUDw0yV+ChxSfYWKyW3evhOLitespiY+QmU0qNJDWJwD6exuhNaXndjXSPfvp4FlSZx9kuG156idChMVFCk+Iy1thDQTU5ktK2t0riU+X1GYljQ9DRJBtg0H53cppTAYIAbnCmNR37bI99cYQaEbb+yO9arQ46G0a1kzGy0lw8Fj5BzKtV/mi5PpqE3Y5queXpWEvCpN2NltMOBk/Ej3lRPA4u2DeORI2PMoETCkPOmrr1H8Gi/dpIdMoc2rlnUR7OS/nyvgRswicy0IA/0RNUBZTi0ilWjGe+N8pabrWIEOE8KHJgg6rwF+C2QbtueCqZgHdWzADVK9mQO/gQ2AzKcXop7Eb2NrRejpd8lTAvVH5gvibmKdgtrgeqaeF28+4KVy4CrRH2t5mmWzP9QMwkxVamHiARcfihbaM/vH++TNAZ95mKkiH7+TJmq+e36L2eTX2HtZ8a3vYwRAw==",
                          encrypted_access_token_2: nil,
                          is_analysis_activated: true
                        )
    ibiza.update(state: 'valid')


    exact_online = ExactOnline.create(
                                      user_name: "support.idocus",
                                      full_name: "Support idocus",
                                      email: "mina@idocus.com",
                                      state: "configured",
                                      encrypted_access_token: "QEVuQwBAEADf9SRYPeCkRyvPBJxFla9Z5YZQ8JQLjgMnoZRDz5/qmwbqx6Mn6OihvLqu/tFjy6+pd7iJfCkU87VD9tnXip6DPTDuBcyoOAU5sceQE4X4PjegcA/jwfbPkKkIqH23irQnhzSGlEPR5CITGX961S2zEHNWHppszgErMtIr7OozN63z9XDpev6SvAPnFCW4CrMQAI3KV8wEuBGckL3lmERe/i5xF3B1aLdz410YoP/i7ReOki5LIdoSKzVeAjW1F6wMVg7mMSlK2XhgcTNychYlYA6LhN3W2n4BgagOZMmjhAnh3PZdeOFc2rrBJ6XPueBNG59O5GzAgfar7lvIOQesn+EUoi+fIFUVO68HLzka+RMKdAOOPpbzmd7290L0y816xNN/vCF+1NcgUYR1FRWmdLIBrNerwvqZwpX0lcLKuW6uZS2AZ1Ivt7xeVXFRTeKWeas9m9XIkei9Ek0pYUwai0Rzmnw7RImq8IXyPIVp64C0A5pI0r5IvSf9IONEk0b/tXCTkzIvJjPvVRhWTjW92UHKLus0AOCXL8ajJo4mso+32WtGPCrBqQfbL4WYRhGbwLkhY9E1cDk4VDCQXLdmG+Z0oWn7oETQO/Si/Q0JXgsk5k1/yPQ3UzWVcVZ/C3B78WpC13jR2cIIOUVepqAzGElMdAgq2sR9gmgEgy8oaGZso9YNUCVTRWzVYeReI5TLDHcsmGiT6QWY2jm9uKek5Qh197+ppR+05axiNHiIUClmp/al1kICkUxZ4O1TiNkLPtzVgKUUcYr/YhwkHyY2JvE9N/jtfsXMcC1aaWcvaIqlIpK+wi4ILKRf6pMtduOD8D4e6qYMyemhANo2EJmfxN3Xf1G7CFh9u3h/8iIiDWNAKuPp/y82We/x1AN4YAnQZI9KnrHIH0/MIB2z3RYc",
                                      encrypted_refresh_token: "QEVuQwBAEABZ8sxaCQ4WblFVpBeelBJuGLQNudXIklhkxCI8Z9iwWCV4PxRerXkLMMg7tsYWqsjIzNP/nMQ5IdnH6QYtYJUV6VmENhT6ye0vCXht+bYBWQvnUmbjfEa2q5hxWZeGNNiKdWF+Qr+OLpPoc/iaFwuyAyL08LNbtLl9XvIPkbphYVMo3WXBL4zKGov7qUJHfAOWrneACIDQ9Pi9Ni/8SsMVfSYFI43xhjtP9PzLAEWD00jfkctI0virUSbN8MCAcRCgt87jrFYE43uoauqERedb90j9nsIWAZ4AGXG3paFY1bx7TWnQMdTD2Up/UeujSJcLjfDyav/kjnILKtIYLIN88FIh153k9gj0+7WAjji2CDWGuQMjrq4tpXEZT4n6lOyKH+l4JxcoHvqEG+btuZGkjAuSWMnMt2RLjMMdf8bEdBLGTw0BmqRjwV7TrcT0ZFw/kGTBBWcy74+kvZuiPgMKyRCN7ij/CTVJwosBfnq6Q7Hm7cEL4/BhspAJZbyE4fQ69w92cnwddbqg7pgr89JHY8GOShsBNf1R0ziDh13cuZo6mu1o3afqzTR/tA/fT3o=",
                                      encrypted_client_id: "QEVuQwBAEABuY7oFvWkfnvJ/Ct7qxgvsbcV+1flF9yEdlqiLo8LoZsOmBBVGcE+B5xH3wAOSCfgdbS0CxBKpVKRja+0stbO6",
                                      encrypted_client_secret: "QEVuQwBAEADa742TVShQZRXO41HR8OvTTLbKpBBWtP6ynQl+HpZ14A==",
                                      token_expires_at: 6.hours.ago,
                                      user_id: @user.id
                                    )
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe "Build pre assignment data" do
    context "Ibiza", :ibiza_builder do
      it "create successfull xml data" do
        delivery = delivery_ibiza

        result = VCR.use_cassette('pre_assignment/ibiza_delivery_data_building') do
          PreAssignmentDeliveryXmlBuilder.new(delivery).execute
        end

        delivery.reload
        p delivery.error_message
        expect(delivery.state).to eq 'data_built'
        expect(delivery.data_to_deliver).to be nil
        expect(delivery.error_message).to be nil

        expect(delivery.cloud_content).to be_attached

        expect(delivery.cloud_content_object.path).to be_present

        expect(delivery.cloud_content_object.path).to eq '/home/infodrm/Projects/idocussave/tmp/PreAssignmentDelivery/20181219/1/AC0003_AC_201812_1.xml'

        expect(delivery.cloud_content.filename).to eq 'AC0003_AC_201812_1.xml'
      end

      it "Building data error with undefined exercices" do
        allow_any_instance_of(PreAssignmentDeliveryXmlBuilder).to receive(:ibiza_exercise).and_return(nil)
        allow_any_instance_of(PreAssignmentDeliveryXmlBuilder).to receive(:is_ibiza_exercises_present?).and_return(true)
        delivery = delivery_ibiza

        result = VCR.use_cassette('pre_assignment/ibiza_delivery_data_building') do
          PreAssignmentDeliveryXmlBuilder.new(delivery).execute
        end

        delivery.reload
        expect(delivery.state).to eq 'error'
        expect(delivery.data_to_deliver).not_to be_present
        expect(delivery.error_message).to match /exercice correspondant n'est pas défini/
      end
    end

    context "Exact Online", :exact_online_builder do
      it "create successfull txt data" do
        allow_any_instance_of(Pack::Report::Preseizure).to receive(:journal_name).and_return('60')
        delivery = delivery_exact_online

        result = VCR.use_cassette('pre_assignment/exact_online_delivery_data_building') do
          PreAssignmentDeliveryXmlBuilder.new(delivery).execute
        end

        delivery.reload
        expect(delivery.state).to eq 'data_built'
        expect(delivery.data_to_deliver).to be nil
        expect(delivery.error_message).to be nil

        expect(delivery.cloud_content).to be_attached

        expect(delivery.cloud_content_object.path).to be_present

        expect(delivery.cloud_content_object.path).to eq '/home/infodrm/Projects/idocussave/tmp/PreAssignmentDelivery/20181219/3/AC0003_AC_201812_3.txt'

        expect(delivery.cloud_content.filename).to eq 'AC0003_AC_201812_3.txt'
      end

      it "Building data error with undefined journal" do
        allow_any_instance_of(Pack::Report::Preseizure).to receive(:journal_name).and_return(nil)
        delivery = delivery_exact_online

        result = VCR.use_cassette('pre_assignment/exact_online_delivery_data_building') do
          PreAssignmentDeliveryXmlBuilder.new(delivery).execute
        end

        delivery.reload
        expect(delivery.state).to eq 'error'
        expect(delivery.data_to_deliver).not_to be_present
        expect(delivery.error_message).to eq 'Journal Exact Online introuvable'
      end
    end
  end

  describe "Deliver pre assignment" do
    context "Ibiza", :ibiza_delivery do
      it "send pre_assignment successfully" do
        allow(Settings).to receive_message_chain('first.notify_on_ibiza_delivery').and_return('no')
        delivery = delivery_ibiza

        result = VCR.use_cassette('pre_assignment/ibiza_delivery_data_building') do
          PreAssignmentDeliveryXmlBuilder.new(delivery).execute
        end

        result = VCR.use_cassette('pre_assignment/ibiza_send_delivery') do
          PreAssignmentDeliveryService.new(delivery.reload).execute
        end

        delivery.reload
        expect(delivery.state).to eq 'sent'
        expect(delivery.data_to_deliver).to be nil
        expect(delivery.cloud_content).to be_attached
        expect(delivery.cloud_content_object.path).to be_present
        expect(delivery.preseizures.first.is_delivered_to?('ibiza')).to be true
      end

      it "returns error sending" do
        allow(Settings).to receive_message_chain('first.notify_on_ibiza_delivery').and_return('no')
        allow_any_instance_of(Pack::Report::Preseizure).to receive(:journal_name).and_return('NotFound')
        delivery = delivery_ibiza

        result = VCR.use_cassette('pre_assignment/ibiza_delivery_data_building') do
          PreAssignmentDeliveryXmlBuilder.new(delivery).execute
        end

        result = VCR.use_cassette('pre_assignment/ibiza_send_delivery_with_error') do
          PreAssignmentDeliveryService.new(delivery.reload).execute
        end

        delivery.reload
        expect(delivery.state).to eq 'error'
        expect(delivery.data_to_deliver).to be nil
        expect(delivery.cloud_content).to be_attached
        expect(delivery.cloud_content_object.path).to be_present
        expect(delivery.error_message).to match /journal NotFound est inconnu/
        expect(delivery.preseizures.first.is_delivered_to?('ibiza')).to be false
      end
    end

    context "Exact Online", :exact_online_delivery do
      it "send pre_assignment successfully" do
        allow(Settings).to receive_message_chain('first.notify_on_ibiza_delivery').and_return('no')
        allow_any_instance_of(Pack::Report::Preseizure).to receive(:journal_name).and_return('60')
        delivery = delivery_exact_online

        result = VCR.use_cassette('pre_assignment/exact_online_delivery_data_building') do
          PreAssignmentDeliveryXmlBuilder.new(delivery).execute
        end

        result = VCR.use_cassette('pre_assignment/exact_online_send_delivery') do
          PreAssignmentDeliveryService.new(delivery.reload).execute
        end

        delivery.reload
        expect(delivery.state).to eq 'sent'
        expect(delivery.data_to_deliver).to be nil
        expect(delivery.cloud_content).to be_attached
        expect(delivery.cloud_content_object.path).to be_present
        expect(delivery.preseizures.first.is_delivered_to?('exact_online')).to be true
        expect(delivery.preseizures.first.exact_online_id).to be_present
      end

      it "returns error destination sending" do
        allow(Settings).to receive_message_chain('first.notify_on_ibiza_delivery').and_return('no')
        allow_any_instance_of(Pack::Report::Preseizure).to receive(:journal_name).and_return('60')
        delivery = delivery_exact_online

        result = VCR.use_cassette('pre_assignment/exact_online_delivery_data_building') do
          PreAssignmentDeliveryXmlBuilder.new(delivery).execute
        end

        delivery.reload
        delivery.update(data_to_deliver: nil)

        result = VCR.use_cassette('pre_assignment/exact_online_send_delivery_with_error') do
          PreAssignmentDeliveryService.new(delivery.reload).execute
        end

        delivery.reload
        expect(delivery.state).to eq 'error'
        expect(delivery.data_to_deliver).to be nil
        expect(delivery.cloud_content).to be_attached
        expect(delivery.cloud_content_object.path).to be_present
        expect(delivery.preseizures.first.is_delivered_to?('exact_online')).to be false
        expect(delivery.preseizures.first.exact_online_id).not_to be_present
      end
    end
  end
end