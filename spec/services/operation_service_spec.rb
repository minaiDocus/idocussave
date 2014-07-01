# -*- encoding : UTF-8 -*-
require 'spec_helper'

describe OperationService do
  before(:all) do
    DatabaseCleaner.start

    @user = FactoryGirl.create :user, code: 'TS0001'

    @pack = Pack.new
    @pack.owner = @user
    @pack.users << @user
    @pack.name = "#{@user.code} AC 201401 all"
    @pack.save

    @pack2 = Pack.new
    @pack2.owner = @user
    @pack2.users << @user
    @pack2.name = "#{@user.code} BQ 201401 all"
    @pack2.save

    @piece = Pack::Piece.new
    @piece.pack = @pack2
    @piece.name = "#{@user.code} BQ 201401 001"
    @piece.position = 1
    @piece.origin = 'scan'
    @piece.save
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  it 'read from file' do
    file = Tempfile.new('data.xml')
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.operations {
        xml.customer code: 'TS0000'
      }
    end
    file.write builder.to_xml
    file.close
    result = OperationService.import_from_xml(file_path: file.path)
    result.should eq(["User: 'TS0000' not found"])
    FileUtils.remove_entry file.path
  end

  it 'return no data to process' do
    result = OperationService.import_from_xml(data: '')
    result.should eq(['No data to process'])

    result = OperationService.import_from_xml(file_path: '')
    result.should eq(['No data to process'])
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
    result = OperationService.import_from_xml(data: builder.to_xml)
    result.should eq(["Element 'date': 'AZER' is not a valid value of the atomic type 'xs:date'."])
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
    result = OperationService.import_from_xml(data: builder.to_xml)
    result.should eq(["Element 'debit': 'aze' is not a valid value of the local union type."])
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
    result = OperationService.import_from_xml(data: builder.to_xml)
    result.should eq(["Element 'credit': 'aze' is not a valid value of the local union type."])
  end

  it "return User: 'TS0000' not found" do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.operations {
        xml.customer code: 'TS0000'
      }
    end
    result = OperationService.import_from_xml(data: builder.to_xml)
    result.should eq(["User: 'TS0000' not found"])
  end

  it "return Pack: 'TS0001_TS_201401' not found" do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.operations {
        xml.customer(code: 'TS0001') {
          xml.pack name: 'TS0001_TS_201401'
        }
      }
    end
    result = OperationService.import_from_xml(data: builder.to_xml)
    result.should eq(["Pack: 'TS0001_TS_201401' not found"])
  end

  it "return Piece: '1' not found" do
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.operations {
        xml.customer(code: 'TS0001') {
          xml.pack(name: 'TS0001_AC_201401') {
            xml.piece number: 1
          }
        }
      }
    end
    result = OperationService.import_from_xml(data: builder.to_xml)
    result.should eq(["Piece: '1' not found"])
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
            xml.piece number: 2
          }
        }
      }
    end
    result = OperationService.import_from_xml(data: builder.to_xml)
    result.should eq(["Piece: '2' not found"])
    @user.operations.count.should eq(0)
  end

  context 'with valid XML' do
    after(:each) do
      Operation.delete_all
    end

    it 'create one operation' do
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
      result = OperationService.import_from_xml(data: builder.to_xml)
      operation = result.first
      result.size.should eq(1)
      operation.should be_persisted
      operation.date.should eq('2014-01-01'.to_date)
      operation.label.should eq('Prlv iDocus Janvier 2014')
      operation.amount.should eq(-29.0)
      @user.operations.first.should eq(operation)
      @pack2.operations.first.should eq(operation)
      @piece.operations.first.should eq(operation)
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
      result = OperationService.import_from_xml(data: builder.to_xml)
      result.size.should eq(1)
      operation = result.first
      operation.should be_persisted
      operation.amount.should eq(-29.0)
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
      result = OperationService.import_from_xml(data: builder.to_xml)
      result.size.should eq(1)
      operation = result.first
      operation.should be_persisted
      operation.amount.should eq(33.0)
    end
  end
end
