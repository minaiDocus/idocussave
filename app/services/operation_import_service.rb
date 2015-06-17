# -*- encoding : UTF-8 -*-
class OperationImportService
  # Import operations from an XML document
  #
  # ==== Options
  #
  # One of +:data+ or +:file_path+ must be provided, if both are provided then +:data+ will be selected
  #
  # * +:data+ - An XML string like "<operations>...</operations>"
  # * +:file_path+ - A path to the XML file
  #
  # ==== Examples
  #
  #   OperationImportService.new(data: "<operations>...</operations>")
  #   OperationImportService.new(file_path: "path/to/file.xml")
  def initialize(options)
    @data      = options[:data]
    @file_path = options[:file_path]

    @data = '' if (@data.nil? && options.keys.include?(:data)) || (@data.nil? && @file_path.nil?)

    @operations = []
    @errors     = []
  end

  def execute
    if valid?
      document.xpath('//customer').each do |customer_element|
        user_code = customer_element.attributes['code'].value
        user = User.find_by_code user_code
        if user
          customer_element.xpath('//pack').each do |pack_element|
            name = pack_element.attributes['name'].value
            pack_name = name.gsub('_', ' ')
            pack_name += ' all' unless pack_name.match(/ all\z/)
            pack = user.packs.where(name: pack_name).first
            if pack
              pack_element.xpath('//piece').each do |piece_element|
                number = piece_element.attributes['number'].value
                piece = pack.pieces.where(position: number.to_i).first
                if piece
                  if @errors.empty?
                    piece_element.xpath('//operation').each do |operation_element|
                      operation = Operation.new
                      operation.organization = user.organization
                      operation.user         = user
                      operation.pack         = pack
                      operation.piece        = piece
                      operation.date         = operation_element.xpath('//date').first.try(:content)
                      operation.label        = operation_element.xpath('//label').first.try(:content)
                      credit = operation_element.xpath('//credit').first.try(:content)
                      debit = operation_element.xpath('//debit').first.try(:content)
                      if credit.present?
                        operation.amount = credit.to_f.abs
                      elsif debit.present?
                        operation.amount = -debit.to_f.abs
                      end
                      @operations << operation
                    end
                  end
                else
                  @errors << "Piece: '#{number}' not found"
                end
              end
            else
              @errors << "Pack: '#{name}' not found"
            end
          end
        else
          @errors << "User: '#{user_code}' not found"
        end
      end
      @operations.each(&:save) if @errors.empty?
    end
    @errors.empty?
  end

  def data
    @data ||= read_data_from_file
  end

  def operations
    @operations
  end

  def errors
    @errors
  end

  def valid_schema?
    if @valid_schema
      @valid_schema
    else
      errors = schema.validate(document).map(&:to_s)
      @errors += errors
      @valid_schema = errors.empty?
    end
  end

  def valid?
    @valid ||= validate
  end

  def invalid?
    !valid?
  end

private

  def read_data_from_file
    @data = File.read(@file_path) rescue nil
  end

  def schema
    @schema ||= Nokogiri::XML::Schema(File.read(Rails.root.join('lib/xsd/operations.xsd')))
  end

  def document
    @document ||= Nokogiri::XML(data)
  end

  def validate
    if data.present?
      valid_schema?
    else
      @errors << 'No data to process'
      false
    end
  end
end
