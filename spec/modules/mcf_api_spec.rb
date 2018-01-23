require 'spec_helper'

describe McfApi do
  let(:client) { McfApi::Client.new('fbaeb20da31c4967946dc72af2131216cd38b7eb605648df') }

  describe '#renew_access_token' do
    it 'returns a new access_token' do
      result = VCR.use_cassette('mcf/renew_access_token') do
        client.renew_access_token 'd16c23253f54437db6cab93255ab1933'
      end

      expect(result.keys).to eq [:access_token, :expires_at]
    end
  end

  describe '#accounts' do
    it 'returns the list of writable accounts' do
      accounts = VCR.use_cassette('mcf/accounts') do
        client.accounts
      end

      expect(accounts).to eq ['John Doe']
    end
  end

  describe '#upload' do
    it 'uploads a file successfully' do
      result = VCR.use_cassette('mcf/upload') do
        client.upload(Rails.root.join('spec/support/files/2pages.pdf'), 'John Doe/TEST/2pages.pdf')
      end

      expect(result['CodeError']).to eq 600
    end
  end

  describe '#verify_files' do
    it 'returns only the existing one' do
      result = VCR.use_cassette('mcf/verify_files') do
        client.verify_files(['John Doe/TEST/2pages.pdf', 'John Doe/TEST/missing.pdf'])
      end

      expect(result).to eq [{ path: 'John Doe/TEST/2pages.pdf', md5: '97F90EAC0D07FE5ADE8F60A0FA54CDFC' }]
    end
  end
end
