# -*- encoding : UTF-8 -*-
require 'spec_helper'
require 'spec_module'

describe EmailedDocument do
  describe '.new' do
    before(:all) do
      DatabaseCleaner.start
      Timecop.freeze(Time.local(2014,1,1))

      @user = FactoryBot.create(:user, code: 'TS0001')

      @journal = @user.account_book_types.create(name: 'TS', description: 'TEST')
      @journal.save
    end

    after(:all) do
      Timecop.return
      DatabaseCleaner.clean
    end

    after(:each) do
      Email.destroy_all
      TempPack.destroy_all
    end

    context 'for monthly' do
      it 'with fake code should be invalid' do
        mail = Mail.new do
          from    'customer@example.com'
          to      '5678@fw.idocus.com'
          subject 'TS'
        end
        emailed_document = EmailedDocument.new mail

        expect(emailed_document.user).to be_blank
        expect(emailed_document).to be_invalid
      end

      it 'with fake journal should be invalid' do
        code = @user.email_code
        mail = Mail.new do
          from    'customer@example.com'
          to      "#{code}@fw.idocus.com"
          subject 'ST'
        end
        emailed_document = EmailedDocument.new mail

        expect(emailed_document.journal).to be_nil
        expect(emailed_document).to be_invalid
      end

      it 'with invalid period should be invalid' do
        code = @user.email_code
        mail = Mail.new do
          from    'customer@example.com'
          to      "#{code}@fw.idocus.com"
          subject 'TS 201311'
        end
        emailed_document = EmailedDocument.new mail

        expect(emailed_document.period).to be_nil
        expect(emailed_document).to be_invalid
      end

      it '#period should equal 201312' do
        code = @user.email_code
        mail = Mail.new do
          from    'customer@example.com'
          to      "#{code}@fw.idocus.com"
          subject 'TS 201312'
        end
        emailed_document = EmailedDocument.new mail

        expect(emailed_document.period).to eql('201312')
      end

      it 'without attachment should be invalid' do
        code = @user.email_code
        mail = Mail.new do
          from    'customer@example.com'
          to      "#{code}@fw.idocus.com"
          subject 'TS'
        end
        emailed_document = EmailedDocument.new mail

        expect(emailed_document).to be_invalid
      end

      it '1 attachment file size > 5 Mo, attachments should be invalid but emailed document valid' do
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'doc.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
        end
        allow_any_instance_of(EmailedDocument::Attachment).to receive(:size) { 5.megabytes+1 }
        emailed_document = EmailedDocument.new mail

        expect(emailed_document).to be_valid
      end

      it 'with 2 attachments, if 1 file got errors, attachments should be invalid but emailed document valid' do
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'doc.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
          add_file filename: 'doc2.pdf', content: File.read(Rails.root.join('spec/support/files/corrupted.pdf'))
        end

        emailed_document = EmailedDocument.new mail
        expect(emailed_document).to be_valid
        expect(emailed_document.attachments.size).to eq 2
        expect(emailed_document.temp_documents.size).to eq 1
      end

      it 'with total file sizes > 10 Mo should be invalid' do
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'doc1.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
          add_file filename: 'doc2.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
          add_file filename: 'doc3.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
          add_file filename: 'doc4.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
          add_file filename: 'doc5.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
        end

        allow_any_instance_of(EmailedDocument::Attachment).to receive(:size) { 2.2.megabytes }
        allow_any_instance_of(EmailedDocument::Attachment).to receive(:pages_number) { 2 }

        emailed_document = EmailedDocument.new mail
        expect(emailed_document.attachments[0]).to be_valid
        expect(emailed_document.attachments[1]).to be_valid
        expect(emailed_document.attachments[2]).to be_valid
        expect(emailed_document.attachments[3]).to be_valid
        expect(emailed_document.attachments[4]).to be_valid
        expect(emailed_document).to be_invalid
      end

      it 'with pages number > 100 should be valid but has invalid attachments' do
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'doc1.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
        end

        allow_any_instance_of(EmailedDocument::Attachment).to receive(:pages_number) { 110 }

        emailed_document = EmailedDocument.new mail
        expect(emailed_document.attachments.first).not_to be_valid
        expect(emailed_document).to be_valid
        expect(emailed_document.errors).to eq([['doc1.pdf', :pages_number]])
      end

      it 'with corrupted file should be valid but has invalid attachments' do
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'corrupted.pdf', content: File.read(Rails.root.join('spec/support/files/corrupted.pdf'))
        end

        emailed_document = EmailedDocument.new mail
        expect(emailed_document.attachments.first.valid_content?).to eq(false)
        expect(emailed_document).to be_valid
      end

      it 'with protected file should be valid but has invalid attachments' do
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'protected.pdf', content: File.read(Rails.root.join('spec/support/files/protected.pdf'))
        end

        emailed_document = EmailedDocument.new mail
        expect(emailed_document.attachments.first.valid_content?).to eq(false)
        expect(emailed_document).to be_valid
      end

      it 'with printable file should be valid' do
        file_path = Rails.root.join('spec/support/files/printable.pdf').to_s
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'printable.pdf', content: File.read(file_path)
        end

        expect(DocumentTools.is_printable_only?(file_path)).to be true
        emailed_document = EmailedDocument.new mail
        expect(emailed_document.attachments.first).to be_valid_content
        expect(emailed_document).to be_valid
        expect(DocumentTools.is_printable_only?(emailed_document.temp_documents.first.cloud_content_object.path)).to eq(false)
      end

      it 'should be valid' do
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'doc.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
        end
        emailed_document = EmailedDocument.new mail

        expect(emailed_document.user).to be_present
        expect(emailed_document.journal).to be_present
        expect(emailed_document).to be_valid
        expect(emailed_document.temp_documents.count).to eq(1)
        document = emailed_document.temp_documents.first
        expect(document.cloud_content_object.filename).to eq("TS0001_TS_201401.pdf")
        expect(File.exist?(document.cloud_content_object.path)).to be true
      end

      it 'with 2 attachments should be valid' do
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'doc.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
          add_file filename: 'doc2.pdf', content: File.read(Rails.root.join('spec/support/files/5pages.pdf'))
        end
        emailed_document = EmailedDocument.new mail

        expect(emailed_document.user).to be_present
        expect(emailed_document.journal).to be_present
        expect(emailed_document).to be_valid
        expect(emailed_document.temp_documents.count).to eq(2)

        document = emailed_document.temp_documents[0]
        expect(document.cloud_content_object.filename).to eq("TS0001_TS_201401.pdf")
        expect(File.exist?(document.cloud_content_object.path)).to be true

        document2 = emailed_document.temp_documents[1]
        expect(document2.cloud_content_object.filename).to eq("TS0001_TS_201401.pdf")
        expect(File.exist?(document2.cloud_content_object.path)).to be true

        expect(document.cloud_content_object.size).not_to eq document2.cloud_content_object.size
      end

      context 'given the file already exist' do
        before(:all) do
          @temp_pack = TempPack.find_or_create_by_name "#{@user.code} TS #{Time.now.strftime('%Y%m')} all"
          @temp_pack.user = @user
          @temp_pack.save

          temp_document = TempDocument.new
          temp_document.user                = @user
          # temp_document.content             = File.open(File.join(Rails.root, 'spec/support/files/2pages.pdf'))
          temp_document.position            = 1
          temp_document.temp_pack           = @temp_pack
          temp_document.original_file_name  = '2pages.pdf'
          temp_document.delivered_by        = 'Tester'
          temp_document.delivery_type       = 'upload'
          file_path = File.join(Rails.root, 'spec/support/files/2pages.pdf')
          temp_document.cloud_content.attach(io: File.open(file_path), filename: File.basename(file_path)) if temp_document.save
        end

        it 'does not create another file' do
          code = @user.email_code
          mail = Mail.new do
            from     'customer@example.com'
            to       "#{code}@fw.idocus.com"
            subject  'TS'
            add_file filename: '2pages.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
          end

          emailed_document = EmailedDocument.new mail
          expect(emailed_document.errors).to eq([["2pages.pdf", :already_exist]])
          expect(emailed_document).to be_valid
          expect(@temp_pack.temp_documents.count).to eq 1
        end
      end
    end

    context 'for yearly' do
      before(:all) do
        subscription = Subscription.create(user_id: @user.id, period_duration: 12)
        Billing::UpdatePeriod.new(subscription.current_period).execute
      end

      it 'should be valid' do
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'doc.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
        end
        emailed_document = EmailedDocument.new mail

        expect(emailed_document.user).to be_present
        expect(emailed_document.journal).to be_present
        expect(emailed_document).to be_valid
        expect(emailed_document.temp_documents.count).to eq(1)
        document = emailed_document.temp_documents.first
        expect(document.cloud_content_object.filename).to eq("TS0001_TS_2014.pdf")
        expect(File.exist?(document.cloud_content_object.path)).to be true
      end

      after(:all) do
        Subscription.destroy_all
        Period.destroy_all
      end
    end

    context 'with image attachments : ' do
      it 'unsupported files should be ignored' do
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'image.tiff', content: File.read(Rails.root.join('spec/support/files/upload.tiff'))
          add_file filename: 'doc.pdf', content: File.read(Rails.root.join('spec/support/files/upload.pdf'))
          add_file filename: 'ido2.txt', content: File.read(Rails.root.join('spec/support/files/hello.txt'))
        end
        emailed_document = EmailedDocument.new mail
        expect(emailed_document.attachments.map(&:name)).to include 'image.tiff'
        expect(emailed_document.attachments.map(&:name)).to include 'doc.pdf'
        expect(emailed_document.attachments.map(&:name)).not_to include 'ido2.txt'
        expect(emailed_document.attachments.size).to eq(2)
      end

      it 'files should be converted to pdf' do
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'ido1.tiff', content: File.read(Rails.root.join('spec/support/files/upload.tiff'))
        end
        attachment = EmailedDocument::Attachment.new(mail.attachments.first, 'converted.pdf')
        expect(DocumentTools.completed?(attachment.processed_file_path, false)).to be_truthy
        attachment.clean_dir
      end

      it 'large files should be resized' do
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'ido1.png', content: File.read(Rails.root.join('spec/support/files/large_file.png'))
        end
        attachment = EmailedDocument::Attachment.new(mail.attachments.first, 'converted.pdf')
        image = Paperclip::Geometry.from_file attachment.file_path
        resized_pdf = Paperclip::Geometry.from_file attachment.processed_file_path
        expect(image.width).to eq 3200
        expect(image.height).to eq 1800
        expect(resized_pdf.width).to eq 2000
        expect(resized_pdf.height).to eq 1125
        attachment.clean_dir
      end

      it 'should be valid' do
        code = @user.email_code
        mail = Mail.new do
          from     'customer@example.com'
          to       "#{code}@fw.idocus.com"
          subject  'TS'
          add_file filename: 'ido1.png', content: File.read(Rails.root.join('spec/support/files/large_file.png'))
          add_file filename: 'ido2.tiff', content: File.read(Rails.root.join('spec/support/files/upload.tiff'))
        end
        emailed_document = EmailedDocument.new mail

        expect(emailed_document.user).to be_present
        expect(emailed_document.journal).to be_present
        expect(emailed_document).to be_valid
        expect(emailed_document.temp_documents.count).to eq(2)

        document = emailed_document.temp_documents[0]
        expect(document.cloud_content_object.filename).to eq("TS0001_TS_201401.pdf")
        expect(document.original_file_name).to eq("ido1.png")
        expect(File.exist?(document.cloud_content_object.path)).to be true

        document2 = emailed_document.temp_documents[1]
        expect(document2.cloud_content_object.filename).to eq("TS0001_TS_201401.pdf")
        expect(document2.original_file_name).to eq("ido2.tiff")
        expect(File.exist?(document2.cloud_content_object.path)).to be true

      end
    end
  end

  describe '.receive' do
    before(:all) do
      DatabaseCleaner.start
      Timecop.freeze(Time.local(2014,1,1))

      @user = FactoryBot.create(:user, code: 'TS0001')
      @user.create_options is_upload_authorized: true
      @user.create_notify

      @journal = @user.account_book_types.create(name: 'TS', description: 'TEST')
      @journal.save
    end

    after(:all) do
      Timecop.return
      DatabaseCleaner.clean
    end

    after(:each) do
      Email.destroy_all
      TempPack.destroy_all
    end

    it 'should create email with state unprocessable' do
      code = @user.email_code
      mail = Mail.new do
        from    'customer@example.com'
        to      "#{code}@fw.idocus.com"
        subject 'TS'
      end
      emailed_document, email = EmailedDocument.receive(mail)

      expect(emailed_document).to be_invalid
      expect(email.state).to eql('unprocessable')
    end

    it 'with invalid code should create email with state rejected' do
      mail = Mail.new do
        from    'customer@example.com'
        to      "abc@fw.idocus.com"
        subject 'TS'
      end
      email = EmailedDocument.receive(mail)

      expect(email.state).to eql('rejected')
    end

    it 'with upload unauthorized should create email with state rejected' do
      allow_any_instance_of(UserOptions).to receive(:is_upload_authorized).and_return(false)
      code = @user.email_code
      mail = Mail.new do
        from    'customer@example.com'
        to      "#{code}@fw.idocus.com"
        subject 'TS'
      end
      email = EmailedDocument.receive(mail)

      expect(email.state).to eql('rejected')
    end

    it 'should be valid but create email with some invalid content' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'doc.pdf',       content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
        add_file filename: 'corrupted.pdf', content: File.read(Rails.root.join('spec/support/files/corrupted.pdf'))
      end
      emailed_document, email = EmailedDocument.receive(mail, false)

      expect(emailed_document).to be_valid
      expect(email).to be_valid
      expect(email.state).to eql('processed')
      expect(email.errors_list).to eq([["corrupted.pdf", :content]])
    end

    it 'should create email with state processed' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'doc1.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
      end
      emailed_document, email = EmailedDocument.receive(mail)

      expect(emailed_document).to be_valid
      expect(email).to be_valid
      expect(email.state).to eql('processed')
      expect(email.to).to eql("#{code}@fw.idocus.com")
      expect(email.from).to eql('customer@example.com')
      expect(email.subject).to eql('TS')
      expect(email.attachment_names).to eql(['doc1.pdf'])
      expect(email.size).to eql(File.size(Rails.root.join('spec/support/files/2pages.pdf')))
      expect(email.to_user).to eql(@user)
      expect(email.from_user).to be_nil
    end

    it 'with space in the name should create email with state processed' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'doc with space in name.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
      end
      emailed_document, email = EmailedDocument.receive(mail)

      expect(emailed_document).to be_valid
      expect(email).to be_valid
      expect(email.state).to eql('processed')
      expect(email.to).to eql("#{code}@fw.idocus.com")
      expect(email.from).to eql('customer@example.com')
      expect(email.subject).to eql('TS')
      expect(email.attachment_names).to eql(['doc with space in name.pdf'])
      expect(email.size).to eql(File.size(Rails.root.join('spec/support/files/2pages.pdf')))
      expect(email.to_user).to eql(@user)
      expect(email.from_user).to be_nil
    end

    it 'with image attachment should create email with state processed' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'ido1.tiff', content: File.read(Rails.root.join('spec/support/files/upload.tiff'))
      end
      emailed_document, email = EmailedDocument.receive(mail)

      expect(emailed_document).to be_valid
      expect(email).to be_valid
      expect(email.state).to eql('processed')
      expect(email.to).to eql("#{code}@fw.idocus.com")
      expect(email.from).to eql('customer@example.com')
      expect(email.subject).to eql('TS')
      expect(email.attachment_names).to eql(['ido1.tiff'])
      expect(email.to_user).to eql(@user)
      expect(email.from_user).to be_nil
    end

    context 'for processed file with pdfintegrator', :pdf_integrator do
      it 'make new file pdf' do
        test_email_path = File.join(Rails.root, 'spec/support/files/test_mail.eml')
        organization = FactoryBot.create(:organization)

        mail = Mail.new File.read(test_email_path)

        allow(Settings).to receive_message_chain('first.notify_errors_to').and_return('no')
        allow_any_instance_of(Mail).to receive(:subject).and_return('AC 202004')
        allow_any_instance_of(Email).to receive(:from_user).and_return(@user)
        allow_any_instance_of(Email).to receive(:to_user).and_return(@user)

        allow_any_instance_of(EmailedDocument).to receive(:user).and_return(@user)
        allow_any_instance_of(EmailedDocument).to receive(:journal).and_return('VT')
        allow_any_instance_of(EmailedDocument).to receive(:period).and_return('202004')

        allow(User).to receive(:find_by_email).with(any_args).and_return(@user)
        allow(DocumentTools).to receive(:need_ocr).with(any_args).and_return(false)
        allow_any_instance_of(TempPack).to receive(:organization) { organization }

        EmailedDocument.receive(mail)

        expect(TempDocument.last.user.id).to eq @user.id
        expect(TempDocument.last.api_name).to eq 'email'
        expect(TempDocument.last.delivery_type).to eq 'upload'
        expect(TempDocument.last.cloud_content.attached?).to be true
        expect(TempDocument.last.delivered_by).to eq @user.code
      end
    end
  end
end
