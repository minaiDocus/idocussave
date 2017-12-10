require 'spec_helper'

describe DetectPreseizureDuplicate do
  before(:each) do
    DatabaseCleaner.start
    @organization = FactoryGirl.create :organization, code: 'IDOC'
    @user = FactoryGirl.create :user, code: 'IDOC%001'
    @user.create_notify
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  it 'does not detect a duplicate' do
    preseizure = Pack::Report::Preseizure.new
    preseizure.user         = @user
    preseizure.organization = @organization
    preseizure.amount       = 10.0
    preseizure.third_party  = 'Google'
    preseizure.date         = Time.local(2017, 12, 15)
    preseizure.save

    result = DetectPreseizureDuplicate.new(preseizure).execute

    expect(result).to eq false
    expect(preseizure.is_blocked_for_duplication).to eq false
    expect(preseizure.duplicate_detected_at).to be_nil
    expect(preseizure.similar_preseizure).to be_nil
  end

  context 'given an invalid preseizure' do
    before(:each) do
      preseizure = Pack::Report::Preseizure.new
      preseizure.user         = @user
      preseizure.organization = @organization
      preseizure.amount       = 10.0
      preseizure.third_party  = 'Google'
      preseizure.date         = nil
      preseizure.save
    end

    it 'ignores an invalid preseizure' do
      preseizure = Pack::Report::Preseizure.new
      preseizure.user         = @user
      preseizure.organization = @organization
      preseizure.amount       = 10.0
      preseizure.third_party  = 'Google'
      preseizure.date         = nil
      preseizure.save

      result = DetectPreseizureDuplicate.new(preseizure).execute

      expect(result).to eq false
      expect(preseizure.is_blocked_for_duplication).to eq false
      expect(preseizure.duplicate_detected_at).to be_nil
      expect(preseizure.similar_preseizure).to be_nil
    end
  end

  context 'given a preseizure' do
    before(:each) do
      @preseizure = Pack::Report::Preseizure.new
      @preseizure.user         = @user
      @preseizure.organization = @organization
      @preseizure.amount       = 10.0
      @preseizure.third_party  = 'Google'
      @preseizure.date         = Time.local(2017, 12, 15)
      @preseizure.save
    end

    it 'detects a duplicate' do
      preseizure = Pack::Report::Preseizure.new
      preseizure.user         = @user
      preseizure.organization = @organization
      preseizure.amount       = 10.0
      preseizure.third_party  = 'Google'
      preseizure.date         = Time.local(2017, 12, 15)
      preseizure.save

      result = DetectPreseizureDuplicate.new(preseizure).execute

      expect(result).to eq true
      expect(preseizure.is_blocked_for_duplication).to eq true
      expect(preseizure.duplicate_detected_at).to be_present
      expect(preseizure.similar_preseizure).to eq @preseizure
    end

    context 'given duplicate blocker has been deactivated' do
      before(:each) do
        @organization.update(is_duplicate_blocker_activated: false)
      end

      it 'detects a duplicate but does not block it' do
        preseizure = Pack::Report::Preseizure.new
        preseizure.user         = @user
        preseizure.organization = @organization
        preseizure.amount       = 10.0
        preseizure.third_party  = 'Google'
        preseizure.date         = Time.local(2017, 12, 15)
        preseizure.save

        result = DetectPreseizureDuplicate.new(preseizure).execute

        expect(result).to eq false
        expect(preseizure.is_blocked_for_duplication).to eq false
        expect(preseizure.duplicate_detected_at).to be_present
        expect(preseizure.similar_preseizure).to eq @preseizure
      end
    end
  end
end
