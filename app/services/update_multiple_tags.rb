# Update Document tags
module UpdateMultipleTags
  def self.execute(user, tags, document_ids, type = 'piece')
    sub = []
    add = []

    tags.downcase.split.each do |tag|
      next unless tag =~ /-*\w*/

      if tag[0] == '-'
        sub << tag.sub('-', '').sub('*', '.*')
      else
        add << tag
      end
    end

    document_ids.each do |document_id|
      if type == 'piece'
        document = Pack::Piece.where(id: document_id).first
      else
        document = Document.where(id: document_id).first
      end

      next unless document && (document.user == user ||
                  (user.is_prescriber && user.customers.include?(document.user)) || user.is_admin)

      sub.each do |s|
        tags = document.tags || []

        document.tags.each do |tag|
          tags -= [tag] if tag =~ /#{s}/
        end

        document.tags = tags
      end

      document.tags = (document.tags || []) + add if add.any?

      document.save

      if type != 'piece' && document.mixed?
        document.pack.set_tags
        document.pack.save
      end
    end
  end
end
