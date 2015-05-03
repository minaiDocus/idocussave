# -*- encoding : UTF-8 -*-
class PreAssignmentService
  class << self
    def _pending(options={sort:-1})
      Pack::Piece.collection.aggregate(
        { '$match' => { 'is_awaiting_pre_assignment' => true } },
        { '$group' => {
            '_id' => { 'pack_id' => '$pack_id', 'comment' => '$pre_assignment_comment' },
            'first_piece_name' => { '$first' => '$name' },
            'piece_counts' => { '$sum' => 1 },
            'date' => { '$min' => '$created_at' }
          }
        },
        { '$sort' => { 'date' => options[:sort] } }
      )
    end

    def pending(options={sort:-1})
      _pending(options).map do |e|
        o = OpenStruct.new
        o.date           = e['date'].try(:localtime)
        o.name           = e['first_piece_name'].sub(/\s\d+$/, '')
        o.document_count = e['piece_counts'].to_i
        o.message        = e['_id']['comment']
        o
      end
    end
  end
end
