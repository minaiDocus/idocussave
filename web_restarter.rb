require 'date'

class WebRestarter
  def initialize
    free_memory = %x(free | grep 'Mem' | sed "s/\ \ */\ /g" | cut -d ' ' -f4).strip
    hostname    = %x(hostname).strip

    if( free_memory.to_i <= 700000 && (hostname == 'app-1' || hostname == 'app-2') ) #Free memory is less than 700Mi
      modif_date_str  = %x(stat -c '%y' /home/deploy/main/current/tmp/restart.txt).strip
      modif_timestamp = (modif_date_str != '') ? DateTime.parse(modif_date_str).to_time.to_i : 0

      time_diff       = Time.now.to_i - modif_timestamp

      p "[#{Time.now}]   -- Memory left #{free_memory.to_s}"

      if(time_diff >= 3600 || free_memory.to_i <= 250000) #last restarting is more than 1Hours(3600 sec)
        p "[#{Time.now}] -- Restarting now - last restarting : - #{time_diff} sec"
        restarting = %x(touch /home/deploy/main/current/tmp/restart.txt)
      else
        p "[#{Time.now}] -- Can't restart - last restarting : - #{time_diff} sec"
      end
    end
  end
end

WebRestarter.new