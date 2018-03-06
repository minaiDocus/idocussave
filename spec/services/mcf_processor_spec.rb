# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe McfProcessor do
    before(:each) do
      @mcf_document =  McfDocument.create({
                                            code:               'IDO%ABC',
                                            journal:            'AC',
                                            file64:             'abcdefghijklmnopqrst',
                                            original_file_name: 'test.txt',
                                            access_token:       '123'
                                          })
    end

    context 'After receiving file' do
      #skip process_file operation
      before(:each) do
        @process_return = double
        allow(UploadedDocument).to receive(:new).and_return(@process_return)
      end

      it 'Generates a temp file if file 64 is present', :file_generation_succed do
        allow(@process_return).to receive(:valid?).and_return(true)
        McfProcessor.new(@mcf_document).execute_process

        expect(@mcf_document.is_generated).to be true
      end

      it 'Requests a new file to MCF if file64 is nil', :request_resend_file do
        @mcf_document.update(file64: nil)
        @mcf_document.reload

        McfProcessor.new(@mcf_document).execute_process

        expect(@mcf_document.state).to eq 'needs_retake'
        expect(@mcf_document.retake_at).not_to be nil
      end

      it 'Catch error when file is not generated', :file_generation_fails do
        allow(File).to receive(:write).and_throw(Exception)
        allow(Settings).to receive_message_chain("first.notify_errors_to").and_return(["test@idocus.com"])
        
        allow(NotificationMailer).to receive(:notify) do |addresses, subject, content|
          # p "Mail to : #{addresses} - #{subject}
          #   #{content}
          #   "
        end

        McfProcessor.new(@mcf_document).execute_process

        expect(@mcf_document.state).to eq 'not_processable'
        expect(@mcf_document.is_generated).to be false
      end

      it 'Mark files as "needs_retake" when file is corrupted' do
        allow(@process_return).to receive(:valid?).and_return(false)
        allow(@process_return).to receive(:already_exist?).and_return(false)
        allow(@process_return).to receive(:errors).and_return([[:file_is_corrupted_or_protected, nil]])
        allow(@process_return).to receive(:full_error_messages).and_return(nil)

        McfProcessor.new(@mcf_document).execute_process

        expect(@mcf_document.is_generated).to be true
        expect(@mcf_document.state).to eq 'needs_retake'
        expect(@mcf_document.error_message).to be nil
      end

      it 'Mark files as unprocessable when errors occure' do
        allow(@process_return).to receive(:valid?).and_return(false)
        allow(@process_return).to receive(:already_exist?).and_return(false)
        allow(@process_return).to receive(:errors).and_return([[:journal_unknown, journal: "TST"]])
        allow(@process_return).to receive(:full_error_messages).and_return("journal TST introuvable")

        McfProcessor.new(@mcf_document).execute_process

        expect(@mcf_document.is_generated).to be true
        expect(@mcf_document.state).to eq 'not_processable'
        expect(@mcf_document.error_message).to eq 'journal TST introuvable'
      end

      it 'Mark files as processed if everything is ok' do
        allow(@process_return).to receive(:valid?).and_return(true)

        McfProcessor.new(@mcf_document).execute_process

        expect(@mcf_document.is_generated).to be true
        expect(@mcf_document.state).to eq 'processed'
      end    
    end

    context 'Processing files which need retake' do
      it 'Sends request resend to MCF if a file needs retake', :process_retake_success do
        @mcf_document.update(state: 'needs_retake', retake_at: Time.now)
        @mcf_document.reload

        retake = @mcf_document.retake_retry

        McfProcessor.new(@mcf_document).execute_retake

        expect(WebMock).to have_requested(:post, 'https://uploadservice-preprod.mycompanyfiles.fr/api/idocus/resendobject')
        expect(WebMock).to have_requested(:any, /.*/).times(1)

        expect(@mcf_document.retake_retry).to eq (retake + 1)
      end

      it 'Returns error if a file can not make a retake', :process_retake_failed do
        @mcf_document.update(state: 'needs_retake', retake_at: Time.now, retake_retry: 4)
        @mcf_document.reload

        McfProcessor.new(@mcf_document).execute_retake

        expect(@mcf_document.state).to eq "not_delivered"
      end

      it 'Sends notification for undelivered files', :notify_undelivered_files do
        @mcf_document.update(state: 'not_delivered', is_notified: false)
        @mcf_document.reload

        allow(Settings).to receive_message_chain("first.notify_mcf_errors_to").and_return(["test@idocus.com"])

        allow(NotificationMailer).to receive(:notify) do |addresses, subject, content|
          # p "Mail to : #{addresses} - #{subject}
          #   #{content}
          #   "
        end

        McfProcessor.notify_undelivered_files [@mcf_document]

        expect(@mcf_document.is_notified).to be true
      end
    end

    context 'Processing files which need remove' do
      it 'Sends request remove to MCF if a file needs remove', :process_remove_success do
        @mcf_document.update(state: 'processed', is_moved: false)
        @mcf_document.reload

        result = VCR.use_cassette('mcf/move_object') do
          McfProcessor.new(@mcf_document).execute_remove
        end
        
        expect(WebMock).to have_requested(:post, 'https://uploadservice-preprod.mycompanyfiles.fr/api/idocus/moveobject')
        expect(WebMock).to have_requested(:any, /.*/).times(1)

        expect(@mcf_document.is_moved).to be true
      end
    end
end