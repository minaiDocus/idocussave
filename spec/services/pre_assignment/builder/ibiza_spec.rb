# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe PreAssignment::Builder::Ibiza do
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

  def delivery_ibiza
    allow_any_instance_of(PreAssignment::CreateDelivery).to receive(:valid_ibiza?).and_return(true)
    allow_any_instance_of(User).to receive_message_chain('options.pre_assignment_date_computed?').and_return(false)
    allow(Settings).to receive_message_chain(:first, :notify_on_ibiza_delivery).and_return('no')

    preseizures = []
    pieces      = [@piece, @piece_2]

    pieces.each do |piece|
      preseizure = FactoryBot.create :preseizure, user: @user, organization: @organization, report_id: @report.id, piece: piece
      accounts  = Pack::Report::Preseizure::Account.create([
                                                            { type: 1, number: '601109', preseizure_id: preseizure.id },
                                                            { type: 2, number: '471000', preseizure_id: preseizure.id },
                                                            { type: 3, number: '471001', preseizure_id: preseizure.id },
                                                          ])
      entries  = Pack::Report::Preseizure::Entry.create([
                                                          { type: 1, number: '1', amount: 1213.48, preseizure_id: preseizure.id, account_id: accounts[0].id },
                                                          { type: 2, number: '1', amount: 1011.23, preseizure_id: preseizure.id, account_id: accounts[1].id },
                                                          { type: 2, number: '1', amount: 202.25, preseizure_id: preseizure.id, account_id: accounts[2].id },
                                                        ])

      preseizures << preseizure
    end

    PreAssignment::CreateDelivery.new(preseizures, ['ibiza']).execute.first
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
    @user         = FactoryBot.create :user, code: 'IDO%LEAD', organization_id: @organization.id
    @report       = FactoryBot.create :report, user: @user, organization: @organization, name: 'AC0003 AC 201812'
    pack          = FactoryBot.create :pack, owner: @user, organization: @organization , name: (@report.name + ' all')
    @piece        = FactoryBot.create :piece, pack: pack, user: @user, organization: @organization, name: (@report.name + ' 001'), analytic_reference: analytic
    @piece_2      = FactoryBot.create :piece, pack: pack, user: @user, organization: @organization, name: (@report.name + ' 002')

    client_ibiza =  Software::Ibiza.create(
                                        state: 'valid',
                                        state_2: 'none',
                                        owner_type: 'User',
                                        owner_id: @user.id,
                                        ibiza_id: '{595450CA-6F48-4E88-91F0-C225A95F5F16}',
                                        is_analysis_activated: 1,
                                        voucher_ref_target: 'piece_name',
                                        auto_deliver: 1,
                                        is_auto_updating_accounting_plan: 1,
                                        is_used: true,
                                      )

    org_ibiza = Software::Ibiza.create(
                                        state: 'valid',
                                        state_2: 'none',
                                        description: JSON.parse('{"operation_label":{"is_used":"1", "position":"1"}, "date":{"is_used":"1", "position":"1"}, "third_party":{"is_used":"1", "position":"1"}, "amount":{"is_used":"1", "position":"1"}, "currency":{"is_used":"1", "position":"1"}, "conversion_rate":{"is_used":"1", "position":"1"}, "observation":{"is_used":"1", "position":"1"}, "journal":{"is_used":"1", "position":"1"}, "piece_name":{"is_used":"1", "position":"1"}, "piece_number":{"position":"1"}}'),
                                        description_separator: ' - ',
                                        piece_name_format: JSON.parse('{"code":{"position":"1"}, "code_wp":{"position":"1"}, "journal":{"position":"1"}, "period":{"position":"1"}, "number":{"position":"1"}}'),
                                        piece_name_format_sep: ' ',
                                        owner_type: 'Organization',
                                        owner_id: @organization.id,
                                        encrypted_access_token: "QEVuQwBAEAAFaLtTv1HNQw8upA22aJCPDGe4xq6/kup2Tak02HH27rM+nqSgsBms4CpT1KSMLWMwZilQOuAZK6ZPddXrki6NcddOn/uDw+7DzyBp17G5wYfiIMXHCdZuBGWVj2/g/4f0hWOh4e4jeUK3Qzyl3Qe5RMTPmQpeeUD2h2ae2gXmmZ+CwBs88lJk6KW+/3QUhFUHZ4uZWKV1CUUrwocjM51UFph6PiUDw0yV+ChxSfYWKyW3evhOLitespiY+QmU0qNJDWJwD6exuhNaXndjXSPfvp4FlSZx9kuG156idChMVFCk+Iy1thDQTU5ktK2t0riU+X1GYljQ9DRJBtg0H53cppTAYIAbnCmNR37bI99cYQaEbb+yO9arQ46G0a1kzGy0lw8Fj5BzKtV/mi5PpqE3Y5queXpWEvCpN2NltMOBk/Ej3lRPA4u2DeORI2PMoETCkPOmrr1H8Gi/dpIdMoc2rlnUR7OS/nyvgRswicy0IA/0RNUBZTi0ilWjGe+N8pabrWIEOE8KHJgg6rwF+C2QbtueCqZgHdWzADVK9mQO/gQ2AzKcXop7Eb2NrRejpd8lTAvVH5gvibmKdgtrgeqaeF28+4KVy4CrRH2t5mmWzP9QMwkxVamHiARcfihbaM/vH++TNAZ95mKkiH7+TJmq+e36L2eTX2HtZ8a3vYwRAw==",
                                        encrypted_access_token_2: nil,
                                        is_analysis_activated: 1,
                                        voucher_ref_target: 'piece_number',
                                        auto_deliver: 1,
                                        is_auto_updating_accounting_plan: 1,
                                        is_used: true,
                                      )
    org_ibiza.update(state: 'valid')
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  describe "Build pre assignment data", :data_builder do
    context "Ibiza", :ibiza_builder do
      it "create successfull xml data", :one_test do
        allow(IbizaLib::ExerciseFinder).to receive(:ibiza_exercises).and_return(exercices)
        delivery = delivery_ibiza

        VCR.use_cassette('pre_assignment/ibiza_builder') do
          PreAssignment::Builder::Ibiza.new(delivery).run
        end

        delivery.reload
        p delivery.error_message
        expect(delivery.state).to eq 'data_built'
        expect(delivery.data_to_deliver).to be nil
        expect(delivery.error_message).to eq ""
        expect(delivery.cloud_content).to be_attached
        expect(delivery.cloud_content_object.path).to match /tmp\/PreAssignmentDelivery\/20181219\/([0-9]+)\/AC0003_AC_201812_([0-9]+)\.xml/
        expect(File.exist?(delivery.cloud_content_object.path)).to be true

        expect(delivery.preseizures.size).to eq 2
        expect(delivery.cloud_content_object.filename).to match /AC0003_AC_201812_([0-9]+)\.xml/
      end

      it 'Building data error with already sent preseizures', :two_test do
        allow(IbizaLib::ExerciseFinder).to receive(:ibiza_exercises).and_return(exercices)
        allow(IbizaLib::PreseizureFinder).to receive(:is_delivered?).and_return(true)
        delivery = delivery_ibiza

        VCR.use_cassette('pre_assignment/ibiza_builder') do
          PreAssignment::Builder::Ibiza.new(delivery).run
        end
        delivery.reload

        expect(delivery.state).to eq 'error'
        expect(delivery.data_to_deliver).to be nil
        expect(delivery.cloud_content).not_to be_attached
        expect(delivery.error_message).to eq 'No preseizure to send'
      end

      it 'Building data error with only one already sent preseizure', :three_test do
        allow(IbizaLib::ExerciseFinder).to receive(:ibiza_exercises).and_return(exercices)
        allow(IbizaLib::PreseizureFinder).to receive(:is_delivered?).and_return(true, false)
        delivery = delivery_ibiza

        VCR.use_cassette('pre_assignment/ibiza_builder') do
          PreAssignment::Builder::Ibiza.new(delivery).run
        end
        delivery.reload

        expect(delivery.state).to eq 'data_built'
        expect(delivery.data_to_deliver).to be nil

        expect(delivery.cloud_content).to be_attached
        expect(delivery.cloud_content_object.path).to match /tmp\/PreAssignmentDelivery\/20181219\/([0-9]+)\/AC0003_AC_201812_([0-9]+)\.xml/

        expect(delivery.preseizures.size).to eq 2
        expect(delivery.preseizures.first.get_delivery_message_of('ibiza')).to eq 'already sent'
        expect(delivery.preseizures.second.get_delivery_message_of('ibiza')).to eq ''
        expect(delivery.error_message).to eq '1 preseizure(s) already sent'
      end

      it "Building data error with undefined exercices", :four_test do
        allow_any_instance_of(IbizaLib::ExerciseFinder).to receive(:ibiza_exercise).and_return(nil)
        allow_any_instance_of(PreAssignment::Builder::Ibiza).to receive(:is_ibiza_exercises_present?).and_return(true)
        delivery = delivery_ibiza

        VCR.use_cassette('pre_assignment/ibiza_builder_error') do
          PreAssignment::Builder::Ibiza.new(delivery).run
        end
        delivery.reload

        expect(delivery.state).to eq 'error'
        expect(delivery.data_to_deliver).not_to be_present

        expect(delivery.cloud_content).not_to be_attached
        expect(delivery.cloud_content_object.path).to be nil
        expect(delivery.error_message).to match /exercice correspondant n'est pas défini/
      end
    end
  end
end