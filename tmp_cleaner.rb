require 'date'

class TmpCleaner
  def initialize
    tmp_dir = '/home/deploy/main/current/tmp/'
    sub_dirs = ['Invoice', 'Pack', 'Pack::Piece', 'PreAssignmentDelivery', 'TempDocument']
    today = Date.today.strftime('%Y%m%d')

    5.times do |i|
      day = Date.today.prev_day(i).strftime('%Y%m%d')
      next if day == today
      p "=========================================[ #{day} ]=========================================="

      path = File.join(tmp_dir, day) + '*'
      p "--- Clearing #{path} ---> #{system "rm -r #{path}"}"

      sub_dirs.each do |dir|
        path = File.join(tmp_dir, dir, day) + '*'
        p "--- Clearing #{path} ---> #{system "rm -r #{path}"}"
      end
    end
  end
end

TmpCleaner.new