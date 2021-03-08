class PonctualScripts::GenerateSEPAXmlFromCSV < PonctualScripts::PonctualScript
  def self.execute(file_path)
    new({file_path: file_path}).run
  end

  private

  def execute
    data = CSV.read(@options[:file_path], :row_sep => :auto, :col_sep => ";")
    data.shift
    builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
      xml.Document('', :xmlns => "urn:iso:std:iso:20022:tech:xsd:pain.001.001.02") {
        xml.send('pain.001.001.02') {
          xml.GrpHdr {
            xml.MsgId "IDOCUS-625A64-032021"
            xml.CreDtTm "2021-03-04T02:01:35"
            xml.NbOfTxs "26"
            xml.CtrlSum "511.20"
            xml.Grpg "MIXD"
            xml.InitgPty {
              xml.Nm "IDOCUS"
              xml.Id {
                xml.OrgId {
                  xml.PrtryId {
                    xml.Id "80406772600021"
                  }
                }
              }
            }
          }
          xml.PmtInf {
            xml.PmtInfId "IDOCUS-ecart prel 032021"
            xml.PmtMtd "TRF"
            xml.PmtTpInf {
              xml.SvcLvl {
                xml.Cd "SEPA"
              }
            }
            xml.ReqdExctnDt "2021-03-05"
            xml.Dbtr {
              xml.Nm "IDOCUS"
            }
            xml.DbtrAcct {
              xml.Id {
                xml.IBAN "FR1130002004140000375625A64"
              }
            }
            xml.DbtrAgt {
              xml.FinInstnId {
                xml.BIC "CRLYFRPP"
              }
            }

            data.each do |row|
              xml.CdtTrfTxInf {
                xml.PmtId {
                  xml.EndToEndId "IDOCUS-ecart 032021"
                }
                xml.Amt {
                  xml.InstdAmt(row[5], :Ccy => "EUR")
                }
                xml.CdtrAgt {
                  xml.FinInstnId {
                    xml.BIC row[3]
                  }
                }
                xml.Cdtr {
                  xml.Nm row[4]
                }
                xml.CdtrAcct {
                  xml.Id {
                    xml.IBAN row[2]
                  }
                }
                xml.RmtInf {
                  xml.Ustrd row[1]
                }
              }
            end
          }
        }
      }
    end

    export_xml_from_csv_file(builder.to_xml)

    p builder.to_xml

    builder.to_xml
  end


  def export_xml_from_csv_file(data)
    File.write(file_path, data)
  end

  def file_path
    File.join(ponctual_dir, 'ecart_v1_v2.xml')
  end

  def ponctual_dir
    dir = "#{Rails.root}/spec/support/files/ponctual_scripts/export_xml"
    FileUtils.makedirs(dir)
    FileUtils.chmod(0777, dir)
    dir
  end
end
