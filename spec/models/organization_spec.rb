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
    @organization.file_naming_policy = ':customerCode :journal :period :position :thirdParty :date - _'
    expect(@organization).to be_valid
  end

  it 'should be valid' do
    @organization.file_naming_policy = ':customerCode - :journal - :period - :position'
    expect(@organization).to be_valid
  end

  it 'should be valid' do
    @organization.file_naming_policy = ':customerCode-:journal-:period-:position'
    expect(@organization).to be_valid
  end

  it 'should be valid' do
    @organization.file_naming_policy = ':customerCode_:journal_:period_:position'
    expect(@organization).to be_valid
  end

  it 'should be valid' do
    @organization.file_naming_policy = ':customerCode-:journal_:period-:position'
    expect(@organization).to be_valid
  end

  it 'should be valid' do
    @organization.file_naming_policy = ':customerCode:journal:period:position'
    expect(@organization).to be_valid
  end

  it 'should be invalid' do
    @organization.file_naming_policy = 'test :test'
    expect(@organization).to be_invalid
  end
end
