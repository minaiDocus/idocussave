class PonctualScripts::PersonalizeSendFileDelivery < PonctualScripts::PonctualScript
  def self.execute(options={})
    new().run
  end

  private

  def execute
    user = User.find_by_code 'FOO%0366'
    end_time = '2020-05-07'.to_datetime
    start_time = '2019-01-01'.to_datetime

    packs = user.packs.where('created_at >= ? AND created_at <= ?', start_time, end_time)

    logger_infos "[PersonalizeSendFileDelivery] - Pack count: #{packs.size}"

    sleep_counter = 0
    packs.each do |pack|
      logger_infos "[PersonalizeSendFileDelivery] - pack_name: #{pack.name} - #{Time.now}"
      FileDelivery.prepare(pack)
      sleep_counter += 1

      if sleep_counter >= 30
        logger_infos "[PersonalizeSendFileDelivery] - sleep - #{Time.now}"
        sleep (60*10) #10.minutes
        sleep_counter = 0
      end
    end
  end
end