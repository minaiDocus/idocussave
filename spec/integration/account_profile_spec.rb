require 'spec_helper'

describe 'Account Profile' do
  login_user

  it 'should visit successfully' do
    visit '/account/profile'
    current_path.should eq(account_profile_path)
  end

  it 'should have content \'Changer mon mot de passe\'' do
    visit '/account/profile'
    page.should have_content('Changer mon mot de passe')
  end
end
