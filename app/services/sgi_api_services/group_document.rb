# -*- encoding : UTF-8 -*-
class SgiApiServices::GroupDocument
  FILE_NAME_PATTERN_1 = /\A([A-Z0-9]+_*[A-Z0-9]*_[A-Z][A-Z0-9]+_\d{4}([01T]\d)*)_\d{3,4}\.pdf\z/i
  FILE_NAME_PATTERN_2 = /\A([A-Z0-9]+_*[A-Z0-9]*_[A-Z][A-Z0-9]+_\d{4}([01T]\d)*)_\d{3,4}_\d{3}\.pdf\z/i

  def initialize(json_content)
    @errors       = []
    @json_content = json_content
  end


  def execute
    if valid_json_content?
      @json_content['packs'].each do |pack|
        temp_pack = find_temp_pack(pack['name'])

        pack['pieces'].each do |piece|
          SgiApiServices::CreateTempDocumentFromGrouping.new(piece['piece_url'], temp_pack, piece['file_name']).execute
        end
      end

      { success: true }
    else
      @errors << { success: false }
      @errors.reduce { |accumulator_value, hash_value| (accumulator_value || {}).merge hash_value }
    end
  end

  def self.position(file_name)
    if FILE_NAME_PATTERN_1.match(file_name)
      file_name.split('_')[-1].to_i
    elsif FILE_NAME_PATTERN_2.match(file_name)
      file_name.split('_')[-2].to_i
    end
  end


  def self.basename(file_name)
    if (result = FILE_NAME_PATTERN_1.match(file_name))
      if file_name.split('_').size == 5
        result[1].sub('_', '%').tr('_', ' ')
      else
        result[1].tr('_', ' ')
      end
    elsif (result = FILE_NAME_PATTERN_2.match(file_name))
      if file_name.split('_').size == 6
        result[1].sub('_', '%').tr('_', ' ')
      else
        result[1].tr('_', ' ')
      end
    end
  end

  private

  def find_temp_pack(name)
    #WORKAROUND: handle 'MVN%GRHCONSULT' ancient code 'AC0162'
    _name = name
    _name = name.gsub('AC0162', 'MVN%GRHCONSULT') if name.match(/^AC0162/)

    TempPack.where(name: _name.tr('_', ' ') + ' all').first
  end


  def valid_json_content?
    @json_content['packs'].each do |pack|
      if (temp_pack = find_temp_pack(pack['name']))
        file_names = pack['pieces'].map{|p| p['file_name']}
        if file_names.uniq.size != file_names.size
          @errors << { "file_name_duplicated_with_pack_id_#{pack['id']}" => "File name : #{file_names.size - file_names.uniq.size} duplicate(s)."}
        else
          pack['pieces'].each do |piece|
            @piece_url = piece['piece_url']
            verify_piece temp_pack, file_names, piece['origin'], piece['id']
          end
        end
      else
        @errors << { "pack_name_unknown_with_pack_id_#{pack['id']}" => "Pack name : \"#{pack['name']}\", unknown." }
      end
    end

    @errors.empty?
  end


  def verify_piece(temp_pack, file_names, origin, piece_id)
    if origin.in?(%w(scan dematbox_scan upload))
      file_names.uniq.each do |file_name|
        verify_file_name temp_pack, file_name, origin, piece_id
      end
    else
      @errors << { "piece_origin_unknown_with_piece_id_#{piece_id}" => "Piece origin : \"#{origin}\", unknown." }
    end
  end


  def verify_file_name(temp_pack, file_name, origin, piece_id)
    if (origin == 'scan' && !FILE_NAME_PATTERN_1.match(file_name)) || (origin != 'scan' && !FILE_NAME_PATTERN_2.match(file_name))
      @errors << { "file_name_does_not_match_origin_with_piece_id_#{piece_id}" => "File name : \"#{file_name}\", does not match origin : \"#{origin}\"." }
    else
      position = self.class.position(file_name)
      basename = self.class.basename(file_name)

      #WORKAROUND: handle 'MVN%GRHCONSULT' ancient code 'AC0162'
      basename = basename.gsub('AC0162', 'MVN%GRHCONSULT') if basename.match(/^AC0162/)

      is_basename_match = temp_pack.name.match(/\A#{basename}/)

      temp_document = temp_pack.temp_documents.where(position: position).first

      if is_basename_match && temp_document
        if temp_document.bundled?
          @errors << { "file_name_already_grouped_with_piece_id_#{piece_id}" => "File name : \"#{file_name}\", already grouped." }
        elsif !url_exist?
          @errors << { "undownloadable_file_for_piece_id_#{piece_id}" => "File name : \"#{file_name}\" and piece_url: \"#{@piece_url}\", not found." }
        end
      else
        @errors << { "file_name_unknown_with_piece_id_#{piece_id}" => "File name : \"#{file_name}\", unknown." }
      end
    end
  end

  def url_exist?
    uri = URI.parse(@piece_url)
    response = Net::HTTP.get_response(uri)
    response.code.to_i == 200
  end
end
