require 'date'

class TmpCleaner
  def initialize
    tmp_dir = '/home/deploy/main/current/tmp/'

    today = Date.today.strftime('%Y%m%d')

    7.times do |i|
      day = Date.today.prev_day(i).strftime('%Y%m%d')
      p "=========================================[ #{day} ]=========================================="

      if day == today
        time_index = Time.now.strftime('%H').to_i - 1

        if time_index > 0
          time_index.times do |t|
            remove_entries(tmp_dir, "#{day}#{sprintf('%02d', t)}")
          end
        end
      else
        remove_entries(tmp_dir, day)
      end
    end

  end

  private

  def remove_entries(tmp_dir, target_dir=nil)
    sub_dirs = ['Invoice', 'Pack', 'Pack::Piece', 'PreAssignmentDelivery', 'TempDocument', 'McfDocument']

    path = File.join(tmp_dir, target_dir) + '*'
    p "--- Clearing #{path} ---> #{system "rm -r #{path}"}"

    sub_dirs.each do |dir|
      path = File.join(tmp_dir, dir, target_dir) + '*'
      p "--- Clearing #{path} ---> #{system "rm -r #{path}"}"
    end
  end
end

TmpCleaner.new