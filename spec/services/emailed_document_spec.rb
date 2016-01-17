# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe EmailedDocument do
  describe '.new for monthly' do
    before(:all) do
      Timecop.freeze(Time.local(2014,1,1))

      @user = FactoryGirl.create(:user, code: 'TS0001')

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

      expect(emailed_document.valid_attachments?).to be false
      expect(emailed_document).to be_invalid
    end

    it 'with file size > 5 Mo should be invalid' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'doc.pdf', content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
      end
      allow_any_instance_of(EmailedDocument::Attachment).to receive(:size) { 5.megabytes+1 }
      emailed_document = EmailedDocument.new mail

      expect(emailed_document.valid_attachments?).to be false
      expect(emailed_document).to be_invalid
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
      expect(emailed_document.valid_attachments?).to be false
      expect(emailed_document).to be_invalid
    end

    it 'with pages number > 100 should be invalid' do
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
      expect(emailed_document.valid_attachments?).to be false
      expect(emailed_document).to be_invalid
      expect(emailed_document.errors).to eq([['doc1.pdf', :pages_number]])
    end

    it 'with corrupted file should be invalid' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'corrupted.pdf', content: File.read(Rails.root.join('spec/support/files/corrupted.pdf'))
      end

      emailed_document = EmailedDocument.new mail
      expect(emailed_document.attachments.first.valid_content?).to eq(false)
      expect(emailed_document).to be_invalid
    end

    it 'with protected file should be invalid' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'protected.pdf', content: File.read(Rails.root.join('spec/support/files/protected.pdf'))
      end

      emailed_document = EmailedDocument.new mail
      expect(emailed_document.attachments.first.valid_content?).to eq(false)
      expect(emailed_document).to be_invalid
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
      expect(DocumentTools.is_printable_only?(emailed_document.temp_documents.first.content.path)).to eq(false)
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
      expect(emailed_document.valid_attachments?).to be true
      expect(emailed_document).to be_valid
      expect(emailed_document.temp_documents.count).to eq(1)
      document = emailed_document.temp_documents.first
      expect(document.content_file_name).to eq("TS0001_TS_201401.pdf")
      expect(File.exist?(document.content.path)).to be true
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
      expect(emailed_document.valid_attachments?).to be true
      expect(emailed_document).to be_valid
      expect(emailed_document.temp_documents.count).to eq(2)

      document = emailed_document.temp_documents[0]
      expect(document.content_file_name).to eq("TS0001_TS_201401.pdf")
      expect(File.exist?(document.content.path)).to be true

      document2 = emailed_document.temp_documents[1]
      expect(document2.content_file_name).to eq("TS0001_TS_201401.pdf")
      expect(File.exist?(document2.content.path)).to be true

      expect(document.content_file_size).not_to eq document2.content_file_size
    end
  end

  describe '.new for yearly' do
    before(:all) do
      Timecop.freeze(Time.local(2014,1,1))

      @user = FactoryGirl.create(:user, code: 'TS0001')
      subscription = Subscription.create(user_id: @user.id, period_duration: 12)
      UpdatePeriod.new(subscription.current_period).execute
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
      expect(emailed_document.valid_attachments?).to be true
      expect(emailed_document).to be_valid
      expect(emailed_document.temp_documents.count).to eq(1)
      document = emailed_document.temp_documents.first
      expect(document.content_file_name).to eq("TS0001_TS_2014.pdf")
      expect(File.exist?(document.content.path)).to be true
    end
  end

  describe '.receive' do
    before(:all) do
      Timecop.freeze(Time.local(2014,1,1))

      @user = FactoryGirl.create(:user, code: 'TS0001')
      @user.options = UserOptions.new(is_upload_authorized: true)
      @user.options.save

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

    it 'should create email with invalid content' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'doc.pdf',       content: File.read(Rails.root.join('spec/support/files/2pages.pdf'))
        add_file filename: 'corrupted.pdf', content: File.read(Rails.root.join('spec/support/files/corrupted.pdf'))
      end
      emailed_document, email = EmailedDocument.receive(mail, false)

      expect(emailed_document).to be_invalid
      expect(email.state).to eql('unprocessable')
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

    it 'should create email with state processed' do
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
  end
end
