# -*- encoding : UTF-8 -*-
class PreAssignmentService
  def self.pending
    keyf = %Q{
      function(x) {
        name = x.name.split(' ');
        name.pop();
        name = name.join(' ');
        return { pack_name: name };
      }
    }

    reduce = %Q{
      function(current, result) {
        if(result.date == undefined) {
          result.date = current.created_at;
        }
        if(result.comment == undefined) {
          result.comment = current.pre_assignment_comment;
        }
        return result.piece_counts++;
      }
    }

    Pack::Piece.collection.group(
      keyf:    keyf,
      cond:    { is_awaiting_pre_assignment: true },
      initial: { piece_counts: 0 },
      reduce:  reduce
    ).map do |e|
      o = OpenStruct.new
      o.date = e['date'].to_time
      o.pack_name = e['pack_name']
      o.piece_counts = e['piece_counts'].to_i
      o.comment = e['comment']
      o
    end.sort do |a, b|
      a.date <=> b.date
    end
  end
end
