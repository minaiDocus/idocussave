# -*- encoding : UTF-8 -*-
class Order::KitGenerator
  include POSIX::Spawn

  TRIMESTRE = [nil,"1er Trimestre","2e Trimestre","3e Trimestre","4e Trimestre"]

  class << self
    def folder(folders,file_sending_kit, filename = 'folders.pdf')
      Prawn::Document.generate "#{Order::FileSendingKitGenerator::TEMPDIR_PATH}/#{filename}", page_layout: :landscape, page_size: 'A3', left_margin: 32, right_margin: 7, bottom_margin: 32, top_margin: 7 do |pdf|
        folders.each_with_index do |folder,index|
          folder_bloc pdf, folder, file_sending_kit
          if !folders[index+1].nil?
            pdf.start_new_page page_layout: :landscape, page_size: 'A3', left_margin: 32, right_margin: 7, bottom_margin: 32, top_margin: 7
          end
        end
      end
    end

    def mail(mails,file_sending_kit, filename = 'mails.pdf')
      Prawn::Document.generate "#{Order::FileSendingKitGenerator::TEMPDIR_PATH}/#{filename}", left_margin: 70, right_margin: 70 do |pdf|
        pdf.font 'Helvetica'

        mails.each_with_index do |mail,index|
          mail_bloc pdf, mail, file_sending_kit
          if !mails[index+1].nil?
            pdf.start_new_page left_margin: 70, right_margin: 70
          end
        end
      end
    end

    def customer_labels(labels, filename = 'customer_labels.pdf')
      Prawn::Document.generate "#{Order::FileSendingKitGenerator::TEMPDIR_PATH}/#{filename}", page_size: 'A4', margin: 0 do |pdf|
        pdf.font_size 11
        pdf.move_down 32
        nb = 0
        labels.each_with_index do |label,index|
          nb += 1
          if nb == 15
            pdf.start_new_page page_size: 'A4', margin: 0
            pdf.move_down 32
            nb = 1
          end
          if index % 2 == 0
            pdf.float { customer_label_bloc(pdf, label) }
          else
            customer_label_bloc pdf, label, 297
          end
        end
      end
    end

    def labels(labels, filename = 'workshop_labels.pdf')
      Prawn::Document.generate "#{Order::FileSendingKitGenerator::TEMPDIR_PATH}/#{filename}", page_size: 'A4', margin: 0 do |pdf|
        pdf.font_size 9
        pdf.move_down 32
        nb = 0
        labels.each_with_index do |label,index|
          nb += 1
          if nb == 15
            pdf.start_new_page page_size: 'A4', margin: 0
            pdf.move_down 32
            nb = 1
          end
          if index % 2 == 0
            pdf.float { label_bloc(pdf,label) }
          else
            label_bloc pdf, label, 297
          end
        end
      end
    end

    def folder_bloc(pdf, folder, file_sending_kit)
      pdf.font_size 16

      # LEFT SIDE
      pdf.float do
        pdf.move_down 15
        pdf.bounding_box [0, pdf.cursor], width: 531, height: 785 do
          pdf.stroke_bounds
          pdf.bounding_box [15, pdf.cursor - 15], width: 501, height: 755 do
            pdf.text file_sending_kit.instruction.to_s, inline_format: true
          end
        end
      end

      # RIGHT SIDE
      pdf.bounding_box [595, pdf.cursor], width: 531, height: 800 do
        pdf.move_down 9
        pdf.font_size 6
        pdf.text folder[:file_code], align: :right

        pdf.move_down 6
        pdf.font_size 16
        # LOGO
        pdf.float do
          pdf.bounding_box [0, pdf.cursor], width: 265, height: 169 do
            pdf.image "#{file_sending_kit.real_left_logo_path}", height: file_sending_kit.left_logo_height, width: file_sending_kit.left_logo_width, vposition: :center, position: :center
          end
        end
        pdf.bounding_box [265, pdf.cursor], width: 265, height: 169 do
          pdf.image "#{file_sending_kit.real_right_logo_path}", height: file_sending_kit.right_logo_height, width: file_sending_kit.right_logo_width, vposition: :center, position: :center
        end

        pdf.move_down 10

        # QR CODE
        pdf.bounding_box [100, pdf.cursor], width: 531, height: 84 do
          pdf.print_qr_code folder[:file_code], extent: 72
        end

        pdf.move_down 10

        # INFORMATION
        pdf.float do
          pdf.bounding_box [0, pdf.cursor], width: 416, height: 512 do

            data = [
              ['CODE :',    "<b>#{folder[:code]}</b>"],
              ['NOM :',     "<b>#{folder[:company]}</b>"],
              ['PERIODE :', "<b>#{folder[:period]}</b>"],
              ['JOURNAL :', "<b>#{folder[:account_book_type]}</b>"]
            ]
            data << ['INSTRUCTIONS :',"<font size='11'>#{folder[:instructions]}"] if folder[:instructions].present?

            pdf.table data, width: 416, cell_style: { inline_format: true, padding: [12, 4, 12, 4] }, column_widths: { 0 => 150 } do
              style row(0..-1), borders: []
              style columns(0), align: :right
            end
          end
        end

        pdf.float do
          pdf.image File.join([Rails.root,"app/assets/images/application/kit_info.png"]), width: 105.mm, height: 74.mm, vposition: :bottom
        end

        # QR CODE
        pdf.bounding_box [460, pdf.cursor], width: 113, height: 512 do
          pdf.move_down 435
          pdf.print_qr_code folder[:file_code], extent: 72
        end
      end
    end

    def mail_bloc(pdf, mail, file_sending_kit)
      pdf.font_size 8
      pdf.default_leading 4
      header_data = [
        [
          "IDOCUS\n17, rue Galilée\n75116 Paris.",
          "SAS au capital de 50 000 €\nRCS PARIS: 804 067 726\nTVA FR12804067726",
          "contact@idocus.com\nwww.idocus.com\nTél : 0 811 030 177"
        ]
      ]

      pdf.table header_data, width: 471, column_widths: [157,157,157] do
        style row(0), borders: [:top,:bottom], border_color: 'AFA6A6', text_color: 'AFA6A6'
        style columns(0), align: :left
        style columns(1), align: :center
        style columns(2), align: :right
      end

      pdf.move_down 15
      pdf.image "#{file_sending_kit.real_logo_path}", width: file_sending_kit.logo_width, height: file_sending_kit.logo_height, position: :center

      pdf.font_size 10

      pdf.move_down 12
      pdf.bounding_box [230, pdf.cursor], width: 240 do
        pdf.text mail[:client_address].join("\n"), align: :right
      end

      pdf.move_down 15

      pdf.text "Votre code client : <b>#{mail[:client_code]}</b>", align: :left, style: :italic, inline_format: true

      pdf.move_down 8
      pdf.text "Paris, le #{I18n.l(Time.now, format: '%d %B %Y')}", align: :right

      pdf.move_down 15

      pdf.text "Bonjour,"
      pdf.move_down 8
      pdf.text "Le cabinet #{mail[:prescriber_company]}, vous propose désormais un service de numérisation de toutes les pièces nécessaires à la tenue de votre comptabilité."
      pdf.move_down 8
      pdf.text "Cette prestation, assurée par iDocus, va vous permettre un accès rapide et très pratique à vos documents."
      pdf.text "Ils seront disponibles dans votre espace personnel sur le site <b>www.idocus.com</b>", inline_format: true
      pdf.move_down 8
      pdf.text "Nous venons de vous créer un compte pour y accéder : "

      pdf.bounding_box [25, pdf.cursor], width: 515 do
        pdf.text "-  votre login : <b> #{mail[:client_email]}</b>", inline_format: true
        pdf.text "-  votre mot de passe : <b> #{mail[:client_password]} (à changer lors de votre première connexion)</b>", inline_format: true
      end

      pdf.move_down 10
      pdf.text "Tous les mois, vous y retrouverez les fichiers issus de la numérisation de vos papiers."
      pdf.bounding_box [25, pdf.cursor], width: 515 do
        pdf.text "-  Un fichier par chemise (AC, VT, BQ....)"
        pdf.text "-  Format des fichiers : PDF"
        pdf.text "-  Traitement d’OCR effectué (Reconnaissance Optique de Caractères)."
        pdf.text "-  L’interface du site vous permet aussi de télécharger, découper, regrouper les pages."
        pdf.text "-  Beaucoup de nouvelles fonctionnalités sont prévues dans les semaines et mois à venir, nous vous tiendrons informés."
      end

      pdf.move_down 10
      pdf.text "Vos documents qui sont déjà sous format électronique sont à intégrer dans le système iDocus grâce à la fonctionnalité « Téléverser » accessible dans votre espace personnel."

      pdf.move_down 10
      pdf.text "Le respect des consignes et des dates préconisées par #{mail[:prescriber_company]} ainsi que la  bonne utilisation des chemises et enveloppes ci-jointes garantiront l’efficacité de notre service."

      pdf.move_down 10
      pdf.text "Nous vous souhaitons une bonne utilisation."

      pdf.move_down 13
      pdf.text "L’équipe iDocus", align: :center
    end

    def customer_label_bloc(pdf, label, y=0)
      pdf.bounding_box [y, pdf.cursor], width: 297, height: 111 do
        pdf.move_down 10
        pdf.bounding_box [15, pdf.cursor], width: 297 do
          label.each_with_index do |field, index|
            if index == 1
              width, height = `identify -format \"%wx%h\" "#{BarCode::TEMPDIR_PATH}/#{field}.png"`.split('x').map(&:to_i)
              w = width - ((width*20) / 100)
              pdf.float do
                pdf.bounding_box [0, pdf.cursor], width: w do
                  pdf.image "#{BarCode::TEMPDIR_PATH}/#{field}.png", height: height, width: w
                end
              end
              pdf.bounding_box [w + 5, pdf.cursor], width: 297-w, height: height do
                pdf.font_size 8
                pdf.move_down 8
                pdf.text field, inline_format: true
              end
              pdf.move_down 4
            else
              pdf.font_size 9
              pdf.text field, inline_format: true
              pdf.move_down 2
            end
          end
        end
      end
    end

    def label_bloc(pdf, label, y=0)
      pdf.bounding_box [y, pdf.cursor], width: 297, height: 111 do
        pdf.move_down 18
        pdf.bounding_box [15, pdf.cursor], width: 297 do
          label.each_with_index do |field, index|
            if index == 0
              width, height = `identify -format \"%wx%h\" "#{BarCode::TEMPDIR_PATH}/#{field}.png"`.split('x').map(&:to_i)
              w = width - ((width*20) / 100)
              pdf.float do
                pdf.bounding_box [0, pdf.cursor], width: w do
                  pdf.image "#{BarCode::TEMPDIR_PATH}/#{field}.png", height: height, width: w
                end
              end
              pdf.bounding_box [w + 5, pdf.cursor], width: 297-w, height: height do
                pdf.font_size 8
                pdf.move_down 8
                pdf.text field, inline_format: true
              end
              pdf.move_down 4
            else
              pdf.font_size 9
              pdf.text field, inline_format: true
              pdf.move_down 2
            end
          end
        end
      end
    end
  end
end
