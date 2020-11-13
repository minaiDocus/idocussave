require 'spec_helper'

describe McfLib::Api::Mcf do
  let(:client) { McfLib::Api::Mcf::Client.new('64b01bda571f47aea8814cb7a29a7dc356310755ce01404f') }
  
  context 'Receiving files from MCF', :system_in do  
    describe '#move_uploaded_file', :move_uploaded_file do
      it 'sends request to remove file token to mcf' do
        result = VCR.use_cassette('mcf/move_object') do
          client.move_uploaded_file
        end

        expect(result["Status"]).to eq 600
      end
    end

    describe '#ask_to_resend_file', :resend_file do
      it 'sends request to resend non porocessable file to mcf' do
        result = VCR.use_cassette('mcf/resend_object') do
          client.ask_to_resend_file
        end

        expect(result["Status"]).to eq 600
      end
    end
  end 

  context 'Linking and uploading files to MCF', :system_out do
    describe '#renew_access_token', :renew_access_token do
      it 'returns a new access_token' do
        result = VCR.use_cassette('mcf/renew_access_token') do
          client.renew_access_token 'd16c23253f54437db6cab93255ab1933'
        end

        expect(result.keys).to eq [:access_token, :expires_at]
      end
    end

    describe '#accounts', :list_of_accounts do
      it 'returns the list of writable accounts' do
        accounts = VCR.use_cassette('mcf/accounts') do
          client.accounts
        end

        expect(accounts).to be_an Array
        expect(accounts).to include "John Doe"
      end
    end

    describe '#upload', :upload_file do
      it 'uploads a file successfully' do
        result = VCR.use_cassette('mcf/upload') do
          client.upload(Rails.root.join('spec/support/files/2pages.pdf'), 'John Doe/TEST/2pages.pdf')
        end

        expect(result['Status']).to eq 600
      end
    end

    describe '#verify_files', :verify_files do
      it 'returns only the existing one' do
        result = VCR.use_cassette('mcf/verify_files') do
          client.verify_files(['John Doe/TEST/2pages.pdf', 'John Doe/TEST/missing.pdf'])
        end

        expect(result).to eq [{ path: 'John Doe/TEST/2pages.pdf', md5: '97F90EAC0D07FE5ADE8F60A0FA54CDFC' }]
      end
    end
  end
end
