# -*- encoding : UTF-8 -*-
class PrepaCompta
  PATH = File.join([Rails.root, 'files', Rails.env, 'prepacompta'])

  class DocumentBundler
    class << self
      def prepare
        temp_packs = TempPack.bundle_needed.not_recently_updated
        if temp_packs.any?
          pack_names = []
          documents = []
          temp_packs.each do |temp_pack|
            current_documents = temp_pack.temp_documents.bundle_needed
            if current_documents.size > 0
              documents += current_documents
              pack_names << temp_pack.name
            end
          end
          if documents.size > 0
            path = current_folder_path
            prepare_folder(path)
            documents.each do |document|
              if document.uploaded?
                document.burst(File.join(path, 'upload'))
              elsif document.scanned_by_dematbox?
                document.burst(File.join(path, 'dematbox_scan'))
              elsif document.scanned?
                new_file_path = File.join(path, 'scan', document.file_name_with_position)
                FileUtils.cp document.content.path, new_file_path
              end
              document.bundling
            end
            create_info_file pack_names, path
          end
        end
      end

      def bundle
        not_processed_dirs.each do |dir|
          file_path = File.join(dir, 'regroupments', 'result.xml')
          if File.exist? file_path
            begin
              file = File.open(file_path)
              doc = Nokogiri::XML file
              doc.css('lot').each do |lot|
                pack_name = lot['name'].gsub('_', ' ') + ' all'
                temp_pack = TempPack.where(name: pack_name).first

                ['upload', 'dematbox_scan', 'scan'].each do |origin|
                  lot.css("piece[origin=#{origin}]").each do |piece|
                    create_piece temp_pack, piece, dir, origin
                  end
                end
              end
              mark_as_processed dir
            ensure
              file.close
            end
          end
        end
      end

      def create_piece(temp_pack, piece, dir, origin)
        Dir.mktmpdir do |tmpdir|
          file_path = File.join(tmpdir, temp_pack.basefilename)

          positions = []
          file_paths = piece.css('file_name').map do |file_name|
            part = file_name.content.sub(/\.pdf\z/i, '').split('_')
            if part.size.in?([4, 5]) && origin == 'scan'
              positions << part[-1].to_i
            elsif part.size.in?([5, 6])
              positions << part[-2].to_i
            end
            File.join(dir, 'regroupments', origin, file_name)
          end

          temp_documents = temp_pack.temp_documents.any_in(position: positions).by_position
          original_temp_document = temp_documents.first

          if file_paths.size > 1
            Pdftk.new.merge file_paths, file_path
          else
            FileUtils.cp file_paths.first, file_path
          end

          temp_document                     = TempDocument.new
          temp_document.temp_pack           = temp_pack
          temp_document.user                = temp_pack.user
          temp_document.organization        = temp_pack.organization
          temp_document.is_an_original      = false
          temp_document.is_a_cover          = original_temp_document.is_a_cover?
          temp_document.content             = open(file_path)
          temp_document.pages_number        = DocumentTools.pages_number(file_path)
          temp_document.position            = temp_pack.next_document_position
          temp_document.delivered_by        = original_temp_document.delivered_by
          temp_document.delivery_type       = original_temp_document.delivery_type
          temp_document.dematbox_box_id     = original_temp_document.dematbox_box_id     if original_temp_document.dematbox_box_id
          temp_document.dematbox_service_id = original_temp_document.dematbox_service_id if original_temp_document.dematbox_service_id
          temp_document.dematbox_text       = original_temp_document.dematbox_text       if original_temp_document.dematbox_text
          if temp_document.save
            temp_document.ready
            temp_documents.each(&:bundled)
          end
        end
      end

      def current_folder_path
        File.join([PrepaCompta::PATH, current_folder_name, 'regroupments'])
      end

      def current_folder_name
        name = Date.today.to_s
        last_name = Dir.glob("#{PrepaCompta::PATH}/*#{name}*").sort.last
        if last_name
          if (number=last_name.split('_')[1])
            "#{name}_#{number.to_i+1}"
          else
            "#{name}_2"
          end
        else
          name
        end
      end

      def prepare_folder(path)
        FileUtils.mkdir_p File.join(path, 'scan')
        FileUtils.mkdir_p File.join(path, 'upload')
        FileUtils.mkdir_p File.join(path, 'dematbox_scan')
        Dir.chdir path
      end

      def create_info_file(pack_names, path)
        File.open(File.join([path, 'info.csv']), 'w') do |f|
          pack_names.each do |pack_name|
            f.puts pack_name.sub(' all', '')
          end
        end
      end

      def not_processed_dirs
        Dir.glob(File.join(PrepaCompta::PATH, '*')).select do |e|
          File.basename(e).match /^\d{4}-\d{2}-\d{2}(_\d+)*$/
        end
      end

      def mark_as_processed(dir)
        new_dir = File.join(File.dirname(dir), "[processed]#{File.basename(dir)}")
        FileUtils.mv dir, new_dir
      end
    end
  end
end
