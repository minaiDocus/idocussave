require 'spec_helper'

describe Account::AccountController do
  render_views

  describe '#index' do
    context 'when logged in' do
      before(:each) do
        organization = create :organization
        user = create :user
        user.create_options
        organization.customers << user

        page.driver.post user_session_path, user: { email: user.email, password: user.password }
      end

      it 'shows the home page' do
        visit '/'

        expect(response).to have_http_status(200)
        expect(page).to have_current_path(root_path)
        expect(page).to have_content 'Connecté avec succès'
      end
    end

    context 'when logged off' do
      it 'redirects to login page' do
        visit '/'

        expect(response).to have_http_status(200)
        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content 'Vous devez vous connecter'
      end
    end
  end
end
