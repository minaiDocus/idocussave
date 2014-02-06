require 'spec_helper'

describe Organization do
  before(:all) do
    DatabaseCleaner.start
    @user = FactoryGirl.create :prescriber
    @organization = Organization.new
    @organization.leader = @user
    @organization.name = 'TEST'
    @organization.description = 'Test organization'
    @organization.code = 'TS'
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  it 'should be valid' do
    expect(@organization).to be_valid
  end

  it 'should be valid' do
    @organization.file_naming_policy = 'customerCode journal period position thirdParty date - _'
    expect(@organization).to be_valid
  end

  it 'should be valid' do
    @organization.file_naming_policy = 'customerCode - journal - period - position'
    expect(@organization).to be_valid
  end

  it 'should be valid' do
    @organization.file_naming_policy = 'customerCode-journal-period-position'
    expect(@organization).to be_valid
  end

  it 'should be valid' do
    @organization.file_naming_policy = 'customerCode_journal_period_position'
    expect(@organization).to be_valid
  end

  it 'should be valid' do
    @organization.file_naming_policy = 'customerCode-journal_period-position'
    expect(@organization).to be_valid
  end

  it 'should be invalid' do
    @organization.file_naming_policy = 'test'
    expect(@organization).to be_invalid
  end

  it 'should be invalid' do
    @organization.file_naming_policy = 'customerCodejournal'
    expect(@organization).to be_invalid
  end
end
