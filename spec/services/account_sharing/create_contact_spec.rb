require 'spec_helper'

describe AccountSharing::CreateContact do
  before(:each) do
    DatabaseCleaner.start
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  it 'creates a contact successfully' do
    organization = create :organization
    params = {
      email:      'john.doe@test.com',
      company:    'iDocus',
      first_name: 'John',
      last_name:  'Doe'
    }

    user = AccountSharing::CreateContact.new(params, organization).execute

    expect(user).to be_valid
    expect(user).to be_persisted
    expect(user.code).to be_present
  end

  it 'fails to create a contact' do
    organization = create :organization
    params = {
      email:      'john.doe@test.com',
      company:    nil,
      first_name: 'John',
      last_name:  'Doe'
    }

    user = AccountSharing::CreateContact.new(params, organization).execute

    expect(user).not_to be_persisted
    expect(user.errors.messages).to eq({ company: ['est vide'] })
  end
end
