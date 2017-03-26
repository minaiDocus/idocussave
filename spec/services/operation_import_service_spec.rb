# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe OperationImportService do
  before(:all) do
    @user = FactoryGirl.create :user, code: 'TS0001'

    @pack = Pack.new
    @pack.owner = @user
    @pack.name = "#{@user.code} AC 201401 all"
    @pack.save

    @pack2 = Pack.new
    @pack2.owner = @user
    @pack2.name = "#{@user.code} BQ 201401 all"
    @pack2.save

    @piece = Pack::Piece.new
    @piece.pack = @pack2
    @piece.name = "#{@user.code} BQ 201401 001"
    @piece.position = 1
    @piece.origin = 'scan'
    @piece.save
  end

  describe '#data' do
    before(:all) do
      @xml = '<operations></operations>'
      @temp_file = Tempfile.new('operations.xml')
      @temp_file.write @xml
      @temp_file.close
    end

    after(:all) do
      FileUtils.remove_entry(@temp_file)
    end

    it 'with :data return xml string' do
      service = OperationImportService.new(data: @xml)
      expect(service.data).to eq(@xml)
    end

    it 'with :file_path return xml string' do
      service = OperationImportService.new(file_path: @temp_file.path)
      expect(service.data).to eq(@xml)
    end

    it 'with empty :file_path return empty string' do
      service = OperationImportService.new(file_path: '')
      expect(service.data).to be_nil
    end
  end

  it 'without :data or :file_path should be invalid' do
    service = OperationImportService.new(nothing: true)
    expect(service).to be_invalid
    expect(service.errors).to eq(['No data to process'])
  end

  it 'with nil :data should be invalid' do
    service = OperationImportService.new(data: nil)
    expect(service).to be_invalid
    expect(service.errors).to eq(['No data to process'])
  end

  it 'with empty :data should be invalid' do
    service = OperationImportService.new(data: '')
    expect(service).to be_invalid
    expect(service.errors).to eq(['No data to process'])
  end

  it 'with incomplete :data should be invalid' do
    service = OperationImportService.new(data: '<operations></operations>')
    expect(service).to be_invalid
    expect(service.errors).to eq(["Element 'operations': Missing child element(s). Expected is ( customer )."])
  end

  it 'with complete :data should be valid' do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.operations {
        xml.customer(code: 'TS0001') {
          xml.pack(name: 'TS0001_AC_201401') {
            xml.piece(number: 1) {
              xml.operation {
                xml.date '2014-01-01'
                xml.label 'Prlv iDocus Janvier 2014'
                xml.credit nil
                xml.debit 29.0
              }
            }
          }
        }
      }
    end
    service = OperationImportService.new(data: builder.to_xml)
    expect(service.valid_schema?).to be true
    expect(service).to be_valid
  end


  it "return Element 'date': 'AZER' is not a valid value of the atomic type 'xs:date'" do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.operations {
        xml.customer(code: 'TS0000') {
          xml.pack(name: 'TS0000_TS_201401') {
            xml.piece(number: 1) {
              xml.operation {
                xml.date 'AZER'
                xml.label 'Prlv iDocus Janvier 2014'
                xml.credit nil
                xml.debit 29.0
              }
            }
          }
        }
      }
    end
    service = OperationImportService.new(data: builder.to_xml)
    expect(service.execute).to be false
    expect(service.errors).to eq(["Element 'date': 'AZER' is not a valid value of the atomic type 'xs:date'."])
  end

  it "return Element 'debit': 'aze' is not a valid value of the local union type." do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.operations {
        xml.customer(code: 'TS0000') {
          xml.pack(name: 'TS0000_TS_201401') {
            xml.piece(number: 1) {
              xml.operation {
                xml.date '2014-01-01'
                xml.label 'Prlv iDocus Janvier 2014'
                xml.credit nil
                xml.debit 'aze'
              }
            }
          }
        }
      }
    end
    service = OperationImportService.new(data: builder.to_xml)
    expect(service.execute).to be false
    expect(service.errors).to eq(["Element 'debit': 'aze' is not a valid value of the local union type."])
  end

  it "return Element 'credit': 'aze' is not a valid value of the local union type." do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.operations {
        xml.customer(code: 'TS0000') {
          xml.pack(name: 'TS0000_TS_201401') {
            xml.piece(number: 1) {
              xml.operation {
                xml.date '2014-01-01'
                xml.label 'Prlv iDocus Janvier 2014'
                xml.credit 'aze'
                xml.debit nil
              }
            }
          }
        }
      }
    end
    service = OperationImportService.new(data: builder.to_xml)
    expect(service.execute).to be false
    expect(service.errors).to eq(["Element 'credit': 'aze' is not a valid value of the local union type."])
  end

  it "return User: 'TS0000' not found" do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.operations {
        xml.customer(code: 'TS0000') {
          xml.pack(name: 'TS0000_TS_201401') {
            xml.piece(number: 1) {
              xml.operation {
                xml.date '2014-01-01'
                xml.label 'Prlv iDocus Janvier 2014'
                xml.credit nil
                xml.debit 29.0
              }
            }
          }
        }
      }
    end
    service = OperationImportService.new(data: builder.to_xml)
    expect(service.execute).to be false
    expect(service.errors).to eq(["User: 'TS0000' not found"])
  end

  it "return Pack: 'TS0001_TS_201401' not found" do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.operations {
        xml.customer(code: 'TS0001') {
          xml.pack(name: 'TS0001_TS_201401') {
            xml.piece(number: 1) {
              xml.operation {
                xml.date '2014-01-01'
                xml.label 'Prlv iDocus Janvier 2014'
                xml.credit nil
                xml.debit 29.0
              }
            }
          }
        }
      }
    end
    service = OperationImportService.new(data: builder.to_xml)
    expect(service.execute).to be false
    expect(service.errors).to eq(["Pack: 'TS0001_TS_201401' not found"])
  end

  it "return Piece: '1' not found" do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.operations {
        xml.customer(code: 'TS0001') {
          xml.pack(name: 'TS0001_AC_201401') {
            xml.piece(number: 1) {
              xml.operation {
                xml.date '2014-01-01'
                xml.label 'Prlv iDocus Janvier 2014'
                xml.credit nil
                xml.debit 29.0
              }
            }
          }
        }
      }
    end
    service = OperationImportService.new(data: builder.to_xml)
    expect(service.execute).to be false
    expect(service.errors).to eq(["Piece: '1' not found"])
  end

  it 'should not be persisted' do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.operations {
        xml.customer(code: 'TS0001') {
          xml.pack(name: 'TS0001_BQ_201401') {
            xml.piece(number: 1) {
              xml.operation {
                xml.date '2014-01-01'
                xml.label 'Prlv iDocus Janvier 2014'
                xml.credit nil
                xml.debit 29.0
              }
            }
            xml.piece(number: 2) {
              xml.operation {
                xml.date '2014-01-01'
                xml.label 'Virement'
                xml.credit 35.0
                xml.debit nil
              }
            }
          }
        }
      }
    end
    service = OperationImportService.new(data: builder.to_xml)
    expect(service.execute).to be false
    expect(service.errors).to eq(["Piece: '2' not found"])
    expect(@user.operations.count).to eq(0)
  end

  context 'with valid data' do
    after(:each) do
      Operation.delete_all
    end

    it 'create successfully an operation' do
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.operations {
          xml.customer(code: 'TS0001') {
            xml.pack(name: 'TS0001_BQ_201401') {
              xml.piece(number: 1) {
                xml.operation {
                  xml.date '2014-01-01'
                  xml.label 'Virement'
                  xml.credit 35.0
                  xml.debit nil
                }
              }
            }
          }
        }
      end
      service = OperationImportService.new(data: builder.to_xml)
      expect(service.execute).to be true
      operation = service.operations.first
      expect(service.operations.size).to eq(1)
      expect(operation).to be_persisted
      expect(operation.date).to eq('2014-01-01'.to_date)
      expect(operation.label).to eq('Virement')
      expect(operation.amount).to eq(35.0)
      expect(@user.operations.first).to eq(operation)
      expect(@pack2.operations.first).to eq(operation)
      expect(@piece.operations.first).to eq(operation)
    end

    it 'negate amount if debit' do
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.operations {
          xml.customer(code: 'TS0001') {
            xml.pack(name: 'TS0001_BQ_201401') {
              xml.piece(number: 1) {
                xml.operation {
                  xml.date '2014-01-01'
                  xml.label 'Prlv iDocus Janvier 2014'
                  xml.credit nil
                  xml.debit 29.0
                }
              }
            }
          }
        }
      end
      service = OperationImportService.new(data: builder.to_xml)
      expect(service.execute).to be true
      expect(service.operations.size).to eq(1)
      operation = service.operations.first
      expect(operation).to be_persisted
      expect(operation.amount).to eq(-29.0)
    end

    it 'use credit if credit and debit exists' do
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.operations {
          xml.customer(code: 'TS0001') {
            xml.pack(name: 'TS0001_BQ_201401') {
              xml.piece(number: 1) {
                xml.operation {
                  xml.date '2014-01-01'
                  xml.label 'Prlv iDocus Janvier 2014'
                  xml.credit 33.0
                  xml.debit 29.0
                }
              }
            }
          }
        }
      end
      service = OperationImportService.new(data: builder.to_xml)
      expect(service.execute).to be true
      expect(service.operations.size).to eq(1)
      operation = service.operations.first
      expect(operation).to be_persisted
      expect(operation.amount).to eq(33.0)
    end
  end
end
