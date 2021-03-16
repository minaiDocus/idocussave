require 'date'

class TmpCleaner
  def initialize
    tmp_dir = '/home/deploy/main/current/tmp/'
    sub_dirs = ['Invoice', 'Pack', 'Pack::Piece', 'PreAssignmentDelivery', 'TempDocument', 'McfDocument']
    today = Date.today.strftime('%Y%m%d')

    5.times do |i|
      day = Date.today.prev_day(i).strftime('%Y%m%d')
      next if day == today
      p "=========================================[ #{day} ]=========================================="

      path = File.join(tmp_dir, day) + '*'
      p "--- Clearing #{path} ---> #{system "rm -r #{path}"}"

      remove_entry_each_two_hours_ago(tmp_dir)

      sub_dirs.each do |dir|
        path = File.join(tmp_dir, dir, day) + '*'
        p "--- Clearing #{path} ---> #{system "rm -r #{path}"}"

        remove_entry_each_two_hours_ago(tmp_dir, dir)
      end
    end

  end

  private

  def remove_entry_each_two_hours_ago(tmp_dir, dir=nil)
    two_hours_ago = Time.now.strftime('%Y%m%d%H').to_i - 2
    p "=========================================[ #{two_hours_ago} ]=========================================="

    if dir
      path = File.join(tmp_dir, dir, "#{two_hours_ago}") + '*'
    else
      path = File.join(tmp_dir, "#{two_hours_ago}") + '*'
    end

    p "--- Clearing #{path} ---> #{system "rm -r #{path}"}"
  end
end

TmpCleaner.new