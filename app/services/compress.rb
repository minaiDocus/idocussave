class Compress
  ByteFetch = 700_000

  def initialize
    @lastest_biggest = nil
    create_sequence_table
    create_elements_table
  end

  def compress(file_path)
    dirname = File.dirname file_path
    @file_input = file_path
    @file_name  = File.basename(file_path.to_s)

    # zip_name = @file_input.to_s + '.zip'

    return false unless File.exist? file_path.to_s

    @trans_file = File.open("#{dirname}/#{@file_name}.trans", 'wb')
    # @univ_file  = File.open("#{dirname}/#{@file_name}.unv", 'wb')

    process('compress')

    @trans_file.close
    # @univ_file.close

    # system "zip -j '#{zip_name}' '#{@trans_file.path}' '#{@univ_file.path}' 2>&1"

    # FileUtils.rm @file_input.to_s
    # FileUtils.rm @trans_file.path.to_s
    # FileUtils.rm @univ_file.path.to_s
  end

  def decompress(file_path)
    dirname = File.dirname file_path
    return false unless File.exist? file_path.to_s
    system "unzip -o '#{file_path}'  -d '#{dirname}'"

    @file_input = file_path.to_s.gsub('.zip', '.trans')
    @file_name  = File.basename(@file_input.to_s).gsub('.trans', '')
    @file_univ  = @file_input.to_s.gsub('.trans', '.unv')

    @last_decomp_addresses = []
    @data_univ   = []
    @univ_parser = 0

    return false if !File.exist?(@file_input.to_s) || !File.exist?(@file_univ.to_s)

    @final_file = File.open(Rails.root.join('files', "#{@file_name}"), 'wb')

    process('decompress')

    @final_file.close

    FileUtils.rm @file_input.to_s
    FileUtils.rm @file_univ.to_s
    FileUtils.rm file_path.to_s
  end

  private

  def process(type = 'compress')
    last_addresses = []

    step          = ByteFetch * 6 #Step Multiple of 6
    file_size     = (`ls -l "#{@file_input.to_s}" | cut -d' ' -f5`).strip
    loop_counter  = (file_size.to_f / step.to_f).to_f.ceil
    real_count    = 0
    last_percent  = nil

    loop_counter.times do |i|
      p '------MMM-------'
      j = i + 1

      before_last_line = ((loop_counter - j) == 1) ? true : false
      last_line = ((loop_counter - j) == 0) ? true : false

      data_chunk = (`head -c #{j * step} "#{@file_input.to_s}" | xxd -b | tail -#{(step / 6)}`).strip

      data_chunk.split("\n").each do |line|
        lines = line.gsub('0 ', '0').gsub('1 ', '1')

        if before_last_line
          last_addresses << lines.split(' ')[0].strip
        elsif last_line
          next if last_addresses.include?(lines.split(' ')[0].strip)
        end

        real_count += 1
        chunk = lines.split(' ')[1].strip

        process_compress_of(chunk)   if type == 'compress'
        process_decompress_of(chunk) if type == 'decompress'

        chunk_percent = real_count * 6
        chunk_state   = ((chunk_percent * 100).to_f / file_size.to_f).to_f.floor
        if last_percent != chunk_state
          last_percent  = chunk_state
          p "=====> #{chunk_state.to_s} %"
        end
      end
    end
  end

  def process_compress_of(bytes)
    @datas = bytes.gsub(' ', '').strip
    apply_compress
    #apply_func
    #check_results
    #seek_for_best_func
    #write_results
    # apply_func_8
  end

  def process_decompress_of(bytes)
    @datas = bytes.gsub(' ', '').strip
    reply_func_8
  end

  def sequence_base
    ['u', 'v', 'w', 'x', 'y', 'z']
  end

  def bytes
    @datas.scan(/.{1,8}/)
  end

  def write_results
    @translation[@best_match_func].scan(/.{1,8}/).each{ |octet| @trans_file.write octet.to_i(2).chr }
    @univ_file.write @best_match_func
  end

  def write_result_matches
    function = ''
    @matches.each do |hsh|
      hsh.each do |data|
        function += data[0].to_s
        byte = data[1]

        @trans_file.write byte.to_i(2).chr
      end
    end

    (6 - function.length).times{ |i| function += '0' } if function.length < 6

    index = @univ_hash[function.to_s].to_i
    bin_index = to_bin(index)

    bin_index.scan(/.{1,8}/).each{ |octet| @univ_file.write octet.to_i(2).chr }
  end

  def seek_for_best_func
    sorted = @good_results.sort_by{ |k, v| -v['step'] }
    @best_match_func = sorted[0][0]

    sorted.each do |datas|
      func  = datas[0].to_s
      value = datas[1]

      if !@lastest_biggest.nil? && value['step'] >= 30 && value['biggest'] == @lastest_biggest
        @best_match_func = func
        break
      end
    end

    @lastest_biggest = @good_results[@best_match_func]['biggest']
  end

  def calculate_data_state(bytes)
    length = bytes.to_s.length
    one_length = bytes.to_s.count('1')

    one_percentage   = (one_length * 100) / length
    zero_percentage  = 100 - one_percentage

    step_percentage = one_percentage - zero_percentage #if negatif zero is more than one_percentage
    biggest = step_percentage > 0 ? '1' : '0'

    { 'one' => one_percentage, 'zero' => zero_percentage, 'step' => step_percentage.abs, 'biggest' => biggest }
  end

  def apply_func
    @translation = {}

    functions.each do |data|
      func   = data[0].to_s
      parser = data[1]
      _line = ''

      bytes.each do |byte|
        _tmp_res = ''

        parser.each_with_index do |k, i|
          if k.to_i == 0
            _tmp_res += byte[i].to_s
          else
            _tmp_res += byte[i].to_s == '0' ? '1' : '0'
          end
        end

        _line += _tmp_res
      end

      @translation[func.to_s] = _line
    end
  end

  def apply_func_8
    @matches = []

    bytes.each do |byte|
      @translation = {}

      functions.each do |data|
        func   = data[0].to_s
        parser = data[1]

        _tmp_res = ''
        parser.each_with_index do |k, i|
          if k.to_i == 0
            _tmp_res += byte[i].to_s
          else
            _tmp_res += byte[i].to_s == '0' ? '1' : '0'
          end
        end

        @translation[func.to_s] = _tmp_res
      end

      check_results
      seek_for_best_func

      @matches <<  { @best_match_func.to_s => @translation[@best_match_func.to_s].to_s }
    end

    write_result_matches
  end

  def apply_compress
    hexa = "%02x" % @datas.to_s.to_i(2)

    hack = hexa.split('')
    elements = hack.uniq.sort
    elements_str = elements.join('')

    corr = {}
    sequence_base.each_with_index do |base, index|
      real = elements[index].presence || '-'
      corr[real] = base
    end

    sequence_str = ''
    hack.each do |el|
      sequence_str += corr[el].to_s
    end
    
    element_number  = @elem_hash[elements_str.to_s]
    sequence_number = @univ_hash[sequence_str.to_s]

    el_bin = to_bin(element_number, 2)
    el_bin.scan(/.{1,8}/).each{ |octet| @trans_file.write octet.to_i(2).chr }

    sq_bin = to_bin(sequence_number, 2)
    sq_bin.scan(/.{1,8}/).each{ |octet| @trans_file.write octet.to_i(2).chr }
  end

  def check_results
    @good_results = {}

    @translation.each do |data|
      func  = data[0]
      value = data[1]

      @good_results[func.to_s] = calculate_data_state(value)
    end
  end

  def reply_func_8
    get_univ_datas

    current_univ = @data_univ.shift
    current_univ_index = current_univ.to_i(2)
    current_univ_txt = @univ_tab[current_univ_index.to_i].to_s

    bytes.each_with_index do |byte, ind|
      parser = functions[current_univ_txt[ind].to_s]
      _tmp_res = ''
      parser.each_with_index do |k, i|
        if k.to_i == 0
          _tmp_res += byte[i].to_s
        else
          _tmp_res += byte[i].to_s == '0' ? '1' : '0'
        end
      end

      @final_file.write _tmp_res.to_i(2).chr
    end
  end

  def get_univ_datas
    return @data_univ if @data_univ.any?

    @univ_parser += 1

    step          = ByteFetch * 6 #Step Multiple of 6
    file_size     = (`ls -l "#{@file_univ.to_s}" | cut -d' ' -f5`).strip
    loop_counter  = (file_size.to_f / step.to_f).to_f.ceil

    before_last_line = ((loop_counter - @univ_parser) == 1) ? true : false
    last_line = ((loop_counter - @univ_parser) == 0) ? true : false

    data_chunk = (`head -c #{@univ_parser * step} "#{@file_univ.to_s}" | xxd -b | tail -#{(step / 6)}`).strip

    data_chunk.split("\n").each do |line|
      lines = line.gsub('0 ', '0').gsub('1 ', '1')

      if before_last_line
        @last_decomp_addresses << lines.split(' ')[0].strip
      elsif last_line
        next if @last_decomp_addresses.include?(lines.split(' ')[0].strip)
      end

      chunk = lines.split(' ')[1].strip

      chunk.scan(/.{1,24}/).each{ |univ| @data_univ << univ }
    end
  end

  def create_elements_table
    table = {'0'=>'0', '1'=>'1', '2'=>'2', '3'=>'3', '4'=>'4', '5'=>'5', '6'=>'6', '7'=>'7', '8'=>'8', '9'=>'9', '10'=>'a', '11'=>'b', '12'=>'c', '13'=>'d', '14'=>'e', '15'=>'f'}
    @elem_tab = []
    @elem_hash = {}
    counter = 0
    
    table.each do |t1|
      res = t1[1].to_s
      @elem_tab << res
      @elem_hash[res] = counter
      counter += 1

      table.each do |t2|
        next if t2[0].to_i <= t1[0].to_i
        res = t1[1].to_s + t2[1].to_s
        @elem_tab << res
        @elem_hash[res] = counter
        counter += 1

        table.each do |t3|
          next if t3[0].to_i <= t2[0].to_i
          res = t1[1].to_s + t2[1].to_s + t3[1].to_s
          @elem_tab << res
          @elem_hash[res] = counter
          counter += 1

          table.each do |t4|
            next if t4[0].to_i <= t3[0].to_i
            res = t1[1].to_s + t2[1].to_s + t3[1].to_s + t4[1].to_s
            @elem_tab << res
            @elem_hash[res] = counter
            counter += 1

            table.each do |t5|
              next if t5[0].to_i <= t4[0].to_i
              res = t1[1].to_s + t2[1].to_s + t3[1].to_s + t4[1].to_s + t5[1].to_s
              @elem_tab << res
              @elem_hash[res] = counter
              counter += 1

              table.each do |t6|
                next if t6[0].to_i <= t5[0].to_i
                res = t1[1].to_s + t2[1].to_s + t3[1].to_s + t4[1].to_s + t5[1].to_s + t6[1].to_s
                @elem_tab << res
                @elem_hash[res] = counter
                counter += 1
              end
            end
          end
        end
      end
    end
  end

  def create_sequence_table
    @univ_hash   = {}
    @univ_tab = []

    counter = 0
    sequence_base.each do |data1|
      un = data1
      sequence_base.each do |data2|
        deux = data2
        sequence_base.each do |data3|
          trois = data3
          sequence_base.each do |data4|
            quatre = data4
            sequence_base.each do |data5|
              cinq = data5
              sequence_base.each do |data6|
                six = data6

                _tmp = un.to_s + deux.to_s + trois.to_s + quatre.to_s + cinq.to_s + six.to_s
                @univ_hash[_tmp.to_s] = counter.to_i
                @univ_tab[counter.to_i] = _tmp.to_s

                counter += 1
              end
            end
          end
        end
      end
    end
  end

  def to_bin(_number, octet=2)
    max_length = 8 * octet
    result = 1
    number = _number
    new_base = ''

    while result > 0
      result = number.to_i / 2
      rest   = number.to_i % 2
      new_base += rest.to_s

      number = result
    end

    (max_length - new_base.length).times{ |i| new_base += '0' } if new_base.length < max_length

    new_base.reverse
  end
end