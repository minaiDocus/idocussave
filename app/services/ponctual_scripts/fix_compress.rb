class PonctualScripts::FixCompress < PonctualScripts::PonctualScript
  MAX6 = 281474976710655
  MAX3 = 16777216

  def initialize(file_path=nil)
    @file_path = file_path || '/home/dev-pc/Documents/test'
    @dir_name  = File.dirname @file_path
    @file_name = File.basename @file_path
  end

  def compress_file
    file_size = `ls -al '#{@file_path}' | cut -d' ' -f5`.strip #in octects
    step = 6

    loop_size = (file_size.to_i / step).to_i
    loop_size += 1 if (file_size.to_i % step) > 0
    p loop_size

    File.open("#{@dir_name}/#{@file_name}.mna", 'wb') do |file|
      loop_size.times do |i|
        line = `head -c #{step} '#{@file_path}' | xxd -b | tail -1`.strip
        # line = '00000000: 11111111 11111111 11111111 11111111 11111111 11111111    ffff'
        # step += 6

        # binary = line.split(':').second.strip
        # binary = binary[0, 53].to_s.strip

        # outputs = binary.split(' ').map { |octet| octet.to_i(2).chr }
        # outputs.each { |a| file.write a }
      end
    end

    p 'Done'
  end

  def compress(_binary)
    binary = _binary.to_s.gsub(' ', '')
    dec = to_dec(binary.to_i)

    if dec > MAX3
      first  = dec.to_i / MAX3.to_i
      second = dec.to_i % MAX3.to_i

      result = to_format_bin(first, 3).to_s + to_format_bin(second, 3).to_s
    else
      result = to_format_bin(dec, 6)
    end

    human_bin(result)
  end

  def decompress(_binary)
    binary = _binary.to_s.gsub(' ', '')

    first  = binary[0, 24]
    second = binary[24, 24]

    first_dec  = to_dec(first)
    second_dec = to_dec(second)

    if first_dec == 0
      real_number = second_dec
    else
      real_first  = first_dec * MAX3.to_i
      
      real_number = real_first + second_dec
    end

    final_bin = to_format_bin(real_number, 6)

    human_bin(final_bin)
  end

  def to_dec(_number)
    number = _number.to_s.gsub(' ', '').reverse
    numbers = number.split('')

    result = 0
    numbers.each_with_index do |binaire, puissance|
      result = result.to_i + (binaire.to_i * (2**puissance.to_i))
    end

    result.to_i
  end

  def to_bin(_number)
    number = _number.to_s.gsub(' ', '')
    result = 1
    number = _number
    new_base = ''

    while result > 0
      result = number.to_i / 2
      rest   = number.to_i % 2
      new_base += rest.to_s
      number = result
    end

    new_base.reverse.to_i
  end

  def to_format_bin(_number, octet=1)
    bin = to_bin(_number)
    final_length = octet * 8
    bin_length   = bin.to_s.length

    return bin if bin_length >= final_length

    iteration = final_length - bin_length
    result = ''
    iteration.times do |i|
      result = result.to_s + '0'
    end

    result.to_s + bin.to_s
  end

  def human_bin(_binary)
    binary = _binary.to_s
    string = ''
    6.times do |i|
      begin
        string = string.to_s + binary[(i*8), 8].to_s + ' '
      rescue
      end
    end

    string.to_s.strip
  end
end