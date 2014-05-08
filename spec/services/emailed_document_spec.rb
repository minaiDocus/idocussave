# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe EmailedDocument do
  before(:all) do
    Timecop.freeze(Time.local(2014,1,1))

    @user = FactoryGirl.create(:user, code: 'TS0001')

    @journal = AccountBookType.new name: 'TS', description: 'Test'
    @journal.clients << @user
    @journal.requested_clients << @user
    @journal.save
  end

  after(:all) do
    Timecop.return
  end

  after(:each) do
    Email.destroy_all
    TempPack.destroy_all
  end

  describe '.new' do
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

      expect(emailed_document.valid_attachments?).to be_false
      expect(emailed_document).to be_invalid
    end

    it 'with file size > 5 Mo should be invalid' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'doc.pdf', content: File.read('spec/support/files/2pages.pdf')
      end
      EmailedDocument::Attachment.any_instance.stub(:size) { 5.megabytes+1 }
      emailed_document = EmailedDocument.new mail

      expect(emailed_document.valid_attachments?).to be_false
      expect(emailed_document).to be_invalid
    end

    it 'with total file sizes > 20 Mo should be invalid' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'doc1.pdf', content: File.read('spec/support/files/2pages.pdf')
        add_file filename: 'doc2.pdf', content: File.read('spec/support/files/2pages.pdf')
        add_file filename: 'doc3.pdf', content: File.read('spec/support/files/2pages.pdf')
        add_file filename: 'doc4.pdf', content: File.read('spec/support/files/2pages.pdf')
        add_file filename: 'doc5.pdf', content: File.read('spec/support/files/2pages.pdf')
      end

      EmailedDocument::Attachment.any_instance.stub(:size) { 5.megabytes }

      emailed_document = EmailedDocument.new mail
      expect(emailed_document.attachments[0]).to be_valid
      expect(emailed_document.attachments[1]).to be_valid
      expect(emailed_document.attachments[2]).to be_valid
      expect(emailed_document.attachments[3]).to be_valid
      expect(emailed_document.attachments[4]).to be_valid
      expect(emailed_document.valid_attachments?).to be_false
      expect(emailed_document).to be_invalid
    end

    it 'with corrupted file should have valid rights' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'corrupted.pdf', content: File.read('spec/support/files/corrupted.pdf')
      end

      EmailedDocument::Attachment.any_instance.stub(:size) { 5.megabytes }

      emailed_document = EmailedDocument.new mail
      expect(emailed_document).not_to be_valid_attachment_integrities
      expect(emailed_document).to be_valid_attachment_rights
    end

    it 'should be valid' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'doc.pdf', content: File.read('spec/support/files/2pages.pdf')
      end
      emailed_document = EmailedDocument.new mail

      expect(emailed_document.user).to be_present
      expect(emailed_document.journal).to be_present
      expect(emailed_document.valid_attachments?).to be_true
      expect(emailed_document).to be_valid
      expect(emailed_document.temp_documents.count).to eq(1)
      document = emailed_document.temp_documents.first
      expect(document.content_file_name).to eq("TS0001_TS_201401_001.pdf")
      expect(File.exist?(document.content.path)).to be_true
    end
  end

  describe '.receive' do
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

    it 'should create email with integrity error' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'doc.pdf',       content: File.read('spec/support/files/2pages.pdf')
        add_file filename: 'corrupted.pdf', content: File.read('spec/support/files/corrupted.pdf')
      end
      emailed_document, email = EmailedDocument.receive(mail)

      expect(emailed_document).to be_invalid
      expect(email.state).to eql('unprocessable')
      expect(email.errors_list).to eq([["corrupted.pdf", :integrity]])
    end

    it 'should create email with rights error' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'doc.pdf',       content: File.read('spec/support/files/2pages.pdf')
        add_file filename: 'protected.pdf', content: File.read('spec/support/files/protected.pdf')
      end
      emailed_document, email = EmailedDocument.receive(mail)

      expect(emailed_document).to be_invalid
      expect(email.state).to eql('unprocessable')
      expect(email.errors_list).to eq([["protected.pdf", :rights]])
    end

    it 'should create email with state processed' do
      code = @user.email_code
      mail = Mail.new do
        from     'customer@example.com'
        to       "#{code}@fw.idocus.com"
        subject  'TS'
        add_file filename: 'doc1.pdf', content: File.read('spec/support/files/2pages.pdf')
      end
      emailed_document, email = EmailedDocument.receive(mail)

      expect(emailed_document).to be_valid
      expect(email).to be_valid
      expect(email.state).to eql('processed')
      expect(email.to).to eql("#{code}@fw.idocus.com")
      expect(email.from).to eql('customer@example.com')
      expect(email.subject).to eql('TS')
      expect(email.attachment_names).to eql(['doc1.pdf'])
      expect(email.size).to eql(File.size('spec/support/files/2pages.pdf'))
      expect(email.to_user).to eql(@user)
      expect(email.from_user).to be_nil
    end
  end
end
