# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe DataProcessor::TempPack do
  def prepare_temp_pack
    organization  = create :organization, code: 'ACC'
    user          = create :user, code: 'ACC%000', organization: organization
    @temp_pack    = create :temp_pack, user: user, organization: organization

    3.times do
      td   = create :temp_document, user: user, organization: organization, temp_pack: @temp_pack
      file = File.open("#{Rails.root}/spec/support/files/upload.pdf", "r")

      td.cloud_content_object.attach(file, 'test.pdf') if td.save
    end
  end

  def allow_parameters
    allow(Settings).to receive_message_chain('first.notify_errors_to').and_return(['error@idocus.com'])
    allow(Reporting).to receive(:update).and_return(true)
    allow(FileDelivery).to receive(:prepare).and_return(true)
    allow_any_instance_of(Pack::Piece).to receive(:sign_piece).and_return(true) #signing is not workin on local
  end

  before(:each) do
    DatabaseCleaner.start
    prepare_temp_pack
    allow_parameters
  end

  after(:each) do
    DatabaseCleaner.clean
    FileUtils.rm @original_document.to_s, force: true
  end

  it 'Process without errors', :default do
    allow_any_instance_of(DataProcessor::TempPack).to receive(:need_pre_assignment?).and_return(true)

    DataProcessor::TempPack.execute(@temp_pack)

    @temp_pack.reload
    pack = Pack.find_by_name @temp_pack.name
    piece = pack.pieces.first
    divider = pack.dividers.first
    @original_document = pack.cloud_content_object.path

    expect(@temp_pack.not_processed_count).to eq 0
    expect(@temp_pack.temp_documents.first.state).to eq 'processed'

    expect( pack.try(:pieces).try(:size) ).to eq 3
    expect( File.exist?(piece.cloud_content_object.path) ).to be true

    expect( pack.pieces.first.position ).to eq 1
    expect( pack.pieces.second.position ).to eq 2
    expect( pack.pieces.third.position ).to eq 3

    expect( piece.pre_assignment_state ).to eq 'supplier_recognition'

    expect(divider.pages_number).to eq piece.pages_number
    expect(divider.position).to eq piece.position
    expect(divider.name).to eq DocumentTools.file_name(piece.name).sub('.pdf', '')

    expect( pack.is_fully_processed ).to be true
    expect( pack.locked_at ).to eq nil

    expect( File.exist?(@original_document) ).to be true
    expect( DocumentTools.pages_number(@original_document) ).to eq 3
  end

  it 'Skip temp doc wich dont have a file', :failed_1 do
    td = @temp_pack.temp_documents.first
    td.cloud_content_object.send(:as_attached).purge

    DataProcessor::TempPack.execute(@temp_pack)

    @temp_pack.reload
    pack = Pack.find_by_name @temp_pack.name
    @original_document = pack.cloud_content_object.path

    expect(@temp_pack.not_processed_count).to eq 1
    expect(@temp_pack.temp_documents.first.state).to eq 'ready'
    expect(@temp_pack.temp_documents.second.state).to eq 'processed'

    expect( pack.try(:pieces).try(:size) ).to eq 2
    expect( pack.try(:dividers).try(:size) ).to eq 2
    expect( File.exist?(@original_document) ).to be true
    expect( DocumentTools.pages_number(@original_document) ).to eq 2
  end

  it 'Retry recreating bundled doc only once if merging failed', :failed_2 do
    allow_any_instance_of(Pack).to receive(:append).and_return(false)

    expect(Pack).to receive(:delay_for).exactly(1).and_return(Pack)
    expect(Pack).to receive(:recreate_original_document).exactly(1)

    DataProcessor::TempPack.execute(@temp_pack)

    pack = Pack.find_by_name @temp_pack.name
    @original_document = pack.cloud_content_object.path

    expect(@temp_pack.not_processed_count).to eq 0
    expect(@temp_pack.temp_documents.first.state).to eq 'processed'

    expect( pack.try(:pieces).try(:size) ).to eq 3

    expect( File.exist?(@original_document.to_s) ).to be false
  end
end
