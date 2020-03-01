TempDocument.where('id > 2639833').find_each  { |i| MigrateStorageWorker.perform_async(i.class.to_s, i.id, 'content', 'cloud_content') unless i.cloud_content.attached? }
Pack.where('id > 79654').find_each  { |i| MigrateStorageWorker.perform_async(i.class.to_s, i.id, 'content', 'cloud_content') unless i.cloud_content.attached? }
Pack::Piece.where('id > 2232486').find_each  { |i| MigrateStorageWorker.perform_async(i.class.to_s, i.id, 'content', 'cloud_content') unless i.cloud_content.attached? }
Document.where('id > 2467317').find_each  { |i| MigrateStorageWorker.perform_async(i.class.to_s, i.id, 'content', 'cloud_content') unless i.cloud_content.attached? }
RetrievedData.where('id > 1156464').find_each  { |i| MigrateStorageWorker.perform_async(i.class.to_s, i.id, 'content', 'cloud_content') unless i.cloud_content.attached? }
Email.where('id > 44203').find_each  { |i| MigrateStorageWorker.perform_async(i.class.to_s, i.id, 'original_content', 'cloud_original_content') unless i.cloud_original_content.attached? }

Pack::Piece.order('id desc').find_each  { |i| Pack::Piece.delay.generate_thumbs(i.id) }

Document.order('id desc').find_each  { |i| Document.delay.generate_thumbs(i.id) }
