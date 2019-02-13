# -*- encoding : UTf-8 -*-
class UpdateAdvancedTables
  class Preseizures
    def self.execute
      self.partial
    end

    def self.for_all
      new(true).execute
    end

    def self.partial
      new(false).execute
    end

    def initialize(for_all=true)
      if for_all
        @sql_preseizures = Pack::Report::Preseizure.where("DATE_FORMAT(pack_report_preseizures.updated_at, '%Y%m%d') >= '#{2.years.ago.strftime('%Y%m%d')}'")
      else
        # max_id = AdvancedPreseizure.select('max(id) as max_id').first.try(:max_id).to_i
        # @sql_preseizures = Pack::Report::Preseizure.where("id > #{max_id}") if max_id > 0
        @sql_preseizures = Pack::Report::Preseizure.where("DATE_FORMAT(pack_report_preseizures.updated_at, '%Y%m%d%H%i') >= '#{30.minutes.ago.strftime('%Y%m%d%H%M')}'")
      end
    end

    def execute
      return false unless @sql_preseizures.any?

      field_lists = [
                      'pack_report_preseizures.id',
                      'pack_report_preseizures.user_id',
                      'pack_report_preseizures.organization_id',
                      'pack_report_preseizures.report_id',
                      'pack_reports.pack_id',
                      'pack_report_preseizures.operation_id',
                      'pack_report_preseizures.position',
                      'pack_report_preseizures.deadline_date',
                      'pack_report_preseizures.delivery_tried_at',
                      'pack_report_preseizures.delivery_message',
                      'pack_reports.name',
                      'pack_report_preseizures.piece_number',
                      'pack_report_preseizures.third_party',
                      'pack_report_preseizures.cached_amount',
                      'pack_report_preseizures.updated_at',
                      'pack_report_preseizures.created_at',
                    ]

      delivery_state = "  CASE
                            WHEN pack_report_preseizures.is_delivered_to != '' 
                              THEN 'delivered'
                            WHEN pack_report_preseizures.is_delivered_to = '' AND pack_report_preseizures.delivery_message != '' AND pack_report_preseizures.delivery_message != '{}'
                              THEN 'failed'
                            WHEN pack_report_preseizures.is_delivered_to = '' AND pack_report_preseizures.delivery_tried_at IS NULL AND ( softwares_settings.is_ibiza_used = true OR softwares_settings.is_exact_online_used = true )
                              THEN 'not_delivered'
                            ELSE ''
                          END"

      @sql_preseizures = @sql_preseizures.joins(:report).joins('INNER JOIN softwares_settings ON softwares_settings.user_id = pack_report_preseizures.user_id').select(
        field_lists.join(','), 
        delivery_state + " as p_delivery_state"
      )

      field_insert = field_lists.map{ |field| field.gsub(/pack_report_preseizures[.]|pack_reports[.]/, '') }

      field_update = field_lists.map { |field| field.gsub(/pack_report_preseizures[.]|pack_reports[.]/, '') + '=' + field if field != 'pack_report_preseizures.id' }.compact

      p sql_insertion = " INSERT INTO advanced_preseizures ( #{field_insert.join(',')}, delivery_state )
                          #{@sql_preseizures.to_sql}
                          ON DUPLICATE KEY UPDATE
                          #{field_update.join(',')},
                          delivery_state = #{delivery_state};
                        "
      AdvancedPreseizure.connection.execute(sql_insertion)

      AdvancedPreseizure.connection.execute("DELETE FROM advanced_preseizures WHERE DATE_FORMAT(updated_at, '%Y%m%d') < '#{2.years.ago.strftime('%Y%m%d')}'")
    end
  end
end