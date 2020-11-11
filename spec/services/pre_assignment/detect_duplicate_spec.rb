require 'spec_helper'

describe PreAssignment::DetectDuplicate do
  def create_preseizure(options={})
    preseizure = Pack::Report::Preseizure.new
    preseizure.report        = @report
    preseizure.user          = options[:user].presence || @user
    preseizure.organization  = options[:organization].presence || @organization
    preseizure.cached_amount = options[:amount] || 10.0
    preseizure.third_party   = options[:third_party] || 'Google'
    preseizure.piece_number  = options[:piece_number] || 'G001'
    preseizure.date          = Time.now
    preseizure.save

    preseizure
  end

  before(:each) do
    allow_any_instance_of(Notifications::PreAssignments).to receive(:notify_detected_preseizure_duplication).and_return(true)
    DatabaseCleaner.start
    @organization = FactoryBot.create :organization, code: 'IDOC'
    @user = FactoryBot.create :user, code: 'IDOC%001'
    @report = Pack::Report.create(user: @user, name: 'IDOC%001 AC 202010')
    @user.create_notify
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  context 'given an invalid preseizure', :invalid do
    it 'ignores an invalid preseizure' do
      create_preseizure
      preseizure = create_preseizure
      preseizure.piece_number = nil
      preseizure.save

      service = PreAssignment::DetectDuplicate.new(preseizure.reload)

      expect(service).to receive(:get_highest_match).exactly(0).times
      expect(service).to receive(:get_scored_match).exactly(0).times

      expect(service.execute).to eq false
      expect(preseizure.is_blocked_for_duplication).to eq false
      expect(preseizure.duplicate_detected_at).to be_nil
      expect(preseizure.similar_preseizure).to be_nil
    end

    it 'ignores fetching preseizures with undefined third_party or piece_number' do
      preseizure1 = create_preseizure
      preseizure1.third_party = ''
      preseizure1.save

      preseizure2 = create_preseizure
      preseizure2.piece_number = nil
      preseizure2.save

      preseizure  = create_preseizure

      service = PreAssignment::DetectDuplicate.new(preseizure.reload)

      expect(service).to receive(:get_highest_match).with([]).and_call_original
      expect(service).to receive(:get_scored_match).with([]).and_call_original

      expect(service.execute).to eq false
      expect(preseizure.is_blocked_for_duplication).to eq false
      expect(preseizure.duplicate_detected_at).to be_nil
      expect(preseizure.similar_preseizure).to be_nil
    end
  end

  context 'given a preseizure', :valid do
    before(:each) do
      @preseizure1 = create_preseizure({ third_party: 'Google', piece_number: 'G001' })
      @preseizure2 = create_preseizure({ third_party: 'Googletest', piece_number: 'G001-003' })
      @preseizure3 = create_preseizure({ third_party: 'Google test', piece_number: 'G001 001 19' })
    end

    it 'detects a simple duplication - get highest match' do
      preseizure = create_preseizure({ third_party: 'google', piece_number: 'G001' })

      service = PreAssignment::DetectDuplicate.new(preseizure.reload)

      expect(service).to receive(:get_highest_match).exactly(:once).and_call_original
      expect(service).to receive(:get_scored_match).exactly(0).times.and_call_original

      expect(service.execute).to eq true
      expect(preseizure.is_blocked_for_duplication).to eq true
      expect(preseizure.duplicate_detected_at).to be_present
      expect(preseizure.similar_preseizure).to eq @preseizure1
    end

    it 'detects a complex duplication - get best scored match from preseizures' do
      preseizure = create_preseizure({ third_party: 'google TEST', piece_number: 'G001' })

      result = PreAssignment::DetectDuplicate.new(preseizure.reload).execute

      expect(result).to eq true
      expect(preseizure.is_blocked_for_duplication).to eq true
      expect(preseizure.duplicate_detected_at).to be_present
      expect(preseizure.similar_preseizure).to eq @preseizure3
    end

    it "undetects a complex duplication - similar words in thirds party and piece number don't match completely" do
      preseizure = create_preseizure({ third_party: 'googletest api test', piece_number: 'G001 001 20' })

      result = PreAssignment::DetectDuplicate.new(preseizure.reload).execute

      expect(result).to eq false
      expect(preseizure.is_blocked_for_duplication).to eq false
      expect(preseizure.duplicate_detected_at).to be_nil
      expect(preseizure.similar_preseizure).to be_nil
    end
  end
end
