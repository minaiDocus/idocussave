require 'spec_helper'

describe 'Account Profile' do
  login_user

  it 'should visit successfully' do
    visit '/account/profile'
    expect(current_path).to eq(account_profile_path)
  end

  it 'should have content \'Changer mon mot de passe\'' do
    visit '/account/profile'
    expect(page).to have_content('Changer mon mot de passe')
  end
end
