module Cedricom
  class FetchReceptions
    def initialize(organization, date = nil)
      @date = date.strftime("%d%m%Y") if date
      @organization = organization
    end

    def get_list
      xml = Hash.from_xml(Cedricom::Api.new(@organization).get_reception_list(@date))

      if xml['Receptions']
        xml['Receptions']['Reception'].each do |reception|
          CedricomReception.create(cedricom_id: reception['IdReception'],
                                   cedricom_reception_date: Date::strptime(reception['DateReception'], '%d%m%Y'),
                                   empty: false,
                                   imported: false,
                                   downloaded: false,
                                   organization: @organization)
        end
      end
    end

    def self.fetch_missing_contents
      receptions = CedricomReception.to_download

      receptions.each do |reception|
        content = Cedricom::Api.new(reception.organization).get_reception(reception.cedricom_id)

        if content
          reception.content.attach(io: StringIO.new(content), filename: 'content.txt', content_type: 'text/plain')

          if reception.content
            reception.update(downloaded: true)
          end
        else
          reception.update(empty: true, downloaded: true)
        end
      end
    end
  end
end