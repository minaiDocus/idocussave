module Fiduceo
  module XML
    module Builder
      class << self
        def retriever(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.retriever {
              xml.id         options[:id]          if options[:id]
              xml.providerId options[:provider_id] if options[:provider_id]
              xml.login      options[:login]       if options[:login]
              xml.pass       options[:pass]        if options[:pass]
              xml.param1     options[:param1]      if options[:param1]
              xml.param2     options[:param2]      if options[:param2]
              xml.param3     options[:param3]      if options[:param3]
              xml.label      options[:label]       if options[:label]
              xml.active     options[:active]      if options[:active]
              xml.period     options[:period]      if options[:period] # NONE, WEEKLY, BIWEEKLY, MONTHLY, BIMONTHLY, TRIMONTHLY, SIXMONTHLY, YEARLY
            }
          end
          builder.to_xml
        end

        def alert(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.alert {
              xml.id options[:id] if options[:id]
              xml.userId options[:user_id] if options[:user_id]
              xml.accountId options[:account_id] if options[:account_id]
              xml.type options[:type] if options[:type] # SOLDE_PREVI || RAD
              xml.status options[:status] if options[:status]
              if options[:alert_params]
                xml.alertParams {
                  options[:alert_params].each do |alert_param|
                    xml.alertParam {
                      xml.name alert_param[:name] if alert_param[:name]
                      xml.value alert_param[:value] if alert_param[:value]
                    }
                  end
                }
              end
              xml.active options[:active] if options[:active]
            }
          end
          builder.to_xml
        end

        def bank_account(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.bankaccount {
              xml.providerId options[:provider_id] if options[:provider_id]
              xml.codeBank options[:code_bank] if options[:code_bank]
              xml.name options[:name] if options[:name]
              if options[:inputs]
                xml.inputs {
                  options[:inputs].each do |input|
                    xml.input {
                      xml.name input[:name] if input[:name]
                      xml.tag input[:tag] if input[:tag]
                      xml.info input[:info] if input[:info]
                      xml.type input[:type] if input[:type] # TELEPHONE || EMAIL || INSEE || PASSWORD || FULLTEXT
                      if input[:values]
                        xml.inputValues {
                          input[:values].each do |value|
                            xml.enumValue value
                          end
                        }
                      end
                    }
                  end
                }
              end
            }
          end
          builder.to_xml
        end

        def doc_to_op_list(list, xml=nil)
          builder = xml || Nokogiri::XML::Builder.new
          builder.docToOpList {
            list.each do |asso|
              doc_to_op asso, builder
            end
          }
          builder.to_xml unless xml
        end

        def doc_to_op(options, xml=nil)
          builder = xml || Nokogiri::XML::Builder.new
          builder.docToOp {
            builder.id options[:id] if options[:id]
            builder.operationId options[:operation_id] if options[:operation_id]
            builder.documentId options[:document_id] if options[:document_id]
            builder.label options[:label] if options[:label]
            builder.vignette options[:vignette] if options[:vignette]
          }
          builder.to_xml unless xml
        end

        def doc_to_proj_list(list, xml=nil)
          builder = xml || Nokogiri::XML::Builder.new
          builder.docToProjList {
            list.each do |asso|
              doc_to_proj asso, builder
            end
          }
          builder.to_xml unless xml
        end

        def doc_to_proj(options, xml=nil)
          builder = xml || Nokogiri::XML::Builder.new
          builder.docToProj {
            builder.id options[:id] if options[:id]
            builder.projectId options[:project_id] if options[:project_id]
            builder.documentId options[:document_id] if options[:document_id]
            builder.label options[:label] if options[:label]
            builder.vignette options[:vignette] if options[:vignette]
          }
          builder.to_xml unless xml
        end

        def document_filter(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.documentFilter {
              xml.fromDate options[:from_date] if options[:from_date]
              xml.toDate options[:to_date] if options[:to_date]
              xml.retrieverId options[:retriever_id] if options[:retriever_id]
              xml.searchLabel options[:search_label] if options[:search_label]
              if options[:tags]
                xml.tags {
                  options[:tags].each do |tag|
                    xml.tag tag
                  end
                }
              end
            }
          end
          builder.to_xml
        end

        def document(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.document {
              xml.id options[:id] if options[:id]
              xml.documentId options[:document_id] if options[:document_id]
              xml.parentId options[:parent_id] if options[:parent_id]
              xml.transactionId options[:transaction_id] if options[:transaction_id]
              xml.retrieverId options[:retriever_id] if options[:retriever_id]
              xml.userId options[:user_id] if options[:user_id]
              xml.documentHash options[:document_hash] if options[:document_hash]
              xml.timestamped options[:timestamped] if options[:timestamped]
              if options[:metabody]
                xml.metabodys {
                  options[:metabody].each do |metabody|
                    xml.metabody {
                      xml.name metabody[:name] if metabody[:name]
                      xml.value metabody[:value] if metabody[:value]
                    }
                  end
                }
              end
              doc_to_op_list(options[:doc_to_op_list], xml)
              doc_to_proj_list(options[:doc_to_proj_list], xml)
              if options[:tags]
                xml.tags {
                  options[:tags].each do |tag|
                    xml.tag tag
                  end
                }
              end
              xml.binarybody options[:binary_body] if options[:binary_body] # base64
              xml.tsq options[:tsq] if options[:tsq] # base64
              xml.tsr options[:tsr] if options[:tsr] # base64
            }
          end
          builder.to_xml
        end

        def operation_filter(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.operationFilter {
              xml.fromDate options[:from_date] if options[:from_date]
              xml.toDate options[:to_date] if options[:to_date]
              xml.accountId options[:account_id] if options[:account_id]
              xml.categoryId options[:category_id] if options[:category_id]
              xml.feeling options[:feeling] if options[:feeling] # VERY_GOOD || GOOD || AVERAGE || BAD || VERY_BAD
              xml.note options[:note] if options[:note]          # VERY_GOOD || GOOD || AVERAGE || BAD || VERY_BAD
              xml.searchLabel options[:search_label] if options[:search_label]
              if options[:tags]
                xml.tags {
                  options[:tags].each do |tag|
                    xml.tag tag
                  end
                }
              end
            }
          end
          builder.to_xml
        end

        def operations(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.operations {
              options[:operations].each do |op|
                operation(op, xml)
              end
            }
          end
          builder.to_xml
        end

        def operation(options, xml=nil)
          builder = xml || Nokogiri::XML::Builder.new
          builder.operation {
            builder.id options[:id] if options[:id]
            builder.customId options[:custom_id] if options[:custom_id]
            builder.parentId options[:parent_id] if options[:parent_id]
            builder.dateOp options[:date_op] if options[:date_op]
            builder.dateVal options[:date_val] if options[:date_val]
            builder.dateTransac options[:date_transac] if options[:date_transac]
            builder.label options[:label] if options[:label]
            builder.amount options[:amount] if options[:amount]
            builder.accountBalance options[:accountBalance] if options[:accountBalance]
            builder.comment options[:comment] if options[:comment]
            builder.note options[:note] if options[:note]
            builder.feeling options[:feeling] if options[:feeling]
            doc_to_op_list(builder, options[:doc_to_op_list])
            if options[:tags]
              builder.tags {
                options[:tags].each do |tag|
                  builder.tag tag
                end
              }
            end
            builder.supplierFound options[:supplier_found] if options[:supplier_found]
            builder.cityFound options[:city_found] if options[:city_found]
            builder.countryFound options[:country_found] if options[:country_found]
            builder.typeId options[:type_id] if options[:type_id]
            builder.adresse options[:adresse] if options[:adresse]
            builder.postalCode options[:postal_code] if options[:postal_code]
            builder.latitude options[:latitude] if options[:latitude]
            builder.longitude options[:longitude] if options[:longitude]
            builder.categoryId options[:category_id] if options[:category_id]
            builder.accountId options[:account_id] if options[:account_id]
            builder.userId options[:user_id] if options[:user_id]
            builder.checked options[:checked] if options[:checked]
            builder.operationFutureId options[:operation_future_id] if options[:operation_future_id]
            builder.future options[:future] if options[:future]
          }
          builder.to_xml unless xml
        end

        def operation_cuts(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.operationCuts {
              options[:operation_cuts].each do |op_cut|
                operation_cut(op_cut, xml)
              end
            }
          end
          builder.to_xml
        end

        def operation_cut(options, xml=nil)
          builder = xml || Nokogiri::XML::Builder.new
          builder.operationCut {
            builder.amount options[:amount] if options[:amount]
            builder.comment options[:comment] if options[:comment]
            builder.categoryId options[:category_id] if options[:category_id]
          }
          builder.to_xml unless xml
        end

        def mouvements(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.mouvements {
              xml.numClientPrincipal options[:num_client_principal] if options[:num_client_principal]
              xml.numClientCotitulaire options[:num_client_cotitulaire] if options[:num_client_cotitulaire]
              xml.numCompte options[:num_compte] if options[:num_compte]
              xml.montant options[:montant] if options[:montant]
              xml.dteComptable options[:dte_comptable] if options[:dte_comptable]
              xml.codOperation options[:cod_operation] if options[:cod_operation]
              xml.numOperation options[:num_operation] if options[:num_operation]
              xml.libelle options[:libelle] if options[:libelle]
              xml.idMouvement options[:id_mouvement] if options[:id_mouvement]
              xml.dteMAJ options[:dte_maj] if options[:dte_maj]
              xml.codMCC options[:cod_mcc] if options[:cod_mcc]
              xml.siretCommercant options[:siret_commercant] if options[:siret_commercant]
              xml.deptCommercant options[:dept_commercant] if options[:dept_commercant]
              xml.villeCommercant options[:ville_commercant] if options[:ville_commercant]
              xml.raisonSocialeCommercant options[:raison_sociale_commercant] if options[:raison_sociale_commercant]
              xml.codPaysCommercant options[:cod_pays_commercant] if options[:cod_pays_commercant]
              xml.codNNE options[:cod_nne] if options[:cod_nne]
              xml.idCreancier options[:id_creancier] if options[:id_creancier]
              xml.idMouvementFutur options[:id_mouvement_futur] if options[:id_mouvement_futur]
              xml.dtePremierEcheance options[:dte_premier_echeance] if options[:dte_premier_echeance]
              xml.dteDerniereEcheance options[:dte_derniere_echeance] if options[:dte_derniere_echeance]
              xml.perodicite options[:perodicite] if options[:perodicite]
              xml.typeMouvement options[:type_mouvement] if options[:type_mouvement] # Mouvement || PrelevementSIT || PrelevementSEPA || VirementSIT || VirementSEPA || Manuel
              xml.solde options[:solde] if options[:solde]
            }
          end
          builder.to_xml
        end

        def project(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.operationCut {
              xml.id options[:id] if options[:id]
              xml.userId options[:user_id] if options[:user_id]
              xml.name options[:name] if options[:name]
              xml.endDate options[:endDate] if options[:endDate]
              xml.targetAmount options[:targetAmount] if options[:targetAmount]
              xml.savedAmount options[:savedAmount] if options[:savedAmount]
              xml.amount options[:amount] if options[:amount]
              xml.comment options[:comment] if options[:comment]
              xml.active options[:active] if options[:active]
              if options[:doc_to_proj_list]
                doc_to_proj_list(options[:doc_to_proj_list], xml)
              end
            }
          end
          builder.to_xml
        end

        def transaction(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.transaction {
              xml.id options[:id] if options[:id]
              xml.userId options[:user_id] if options[:user_id]
              xml.transactionStatus options[:transaction_status] if options[:transaction_status] # PENDING || SCHEDULED || IN_PROGRESS || COMPLETED || COMPLETED_NOTHING_TO_DOWNLOAD || COMPLETED_NOTHING_NEW_TO_DOWNLOAD || COMPLETED_WITH_MISSING_DOCS || COMPLETED_WITH_ERRORS || LOGIN_FAILED || UNEXPECTED_ACCOUNT_body || CHECK_ACCOUNT || DEMATERIALISATION_NEEDED || RETRIEVER_ERROR || PROVIDER_UNAVAILABLE || TIMEOUT || BROKER_UNAVAILABLE || WAIT_FOR_USER_ACTION
              if options[:transaction_events]
                xml.transactionEvents {
                  options[:transaction_events].each do |transaction_event|
                    xml.transactionEvent {
                      xml.timestamp transaction_event[:timestamp] if transaction_event[:timestamp]
                      xml.status transaction_event[:status] if transaction_event[:status]
                    }
                    xml.lastUserInfo options[:last_user_info] if options[:last_user_info]
                  end
                }
              end
              if options[:retrieved_documents]
                xml.retrievedDocuments {
                  options[:retrieved_documents].each do |retrieved_document|
                    xml.documentId retrieved_document
                  end
                }
              end
              xml.retrieverId options[:retriever_id] if options[:retriever_id]
              xml.foundDocumentCount options[:found_document_count] if options[:found_document_count]
            }
          end
          builder.to_xml
        end

        def user_preferences(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.userpreferences {
              xml.id options[:id] if options[:id]
              xml.userId options[:user_id] if options[:user_id]
              xml.defaultEcheanceMonth options[:default_echeance_month] if options[:default_echeance_month]
              xml.isBankProAvailable options[:is_bank_pro_available] if options[:is_bank_pro_available]
              xml.maxDataBancaireRetrievers options[:max_data_bancaire_retrievers] if options[:max_data_bancaire_retrievers]
              xml.maxRetrievers options[:max_retrievers] if options[:max_retrievers]
            }
          end
          builder.to_xml
        end

        def user_import(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.userImport {
              xml.id options[:id] if options[:id]
              xml.userId options[:user_id] if options[:user_id]
              xml.email options[:email] if options[:email]
              xml.login options[:login] if options[:login]
              xml.pass options[:pass] if options[:pass]
              xml.fiduceoId options[:fiduceo_id] if options[:fiduceo_id]
            }
          end
          builder.to_xml
        end

        def expense_target(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.expenseTarget {
              xml.userId options[:user_id] if options[:user_id]
              xml.type options[:type] if options[:type] # AUTO || MANUAL
              xml.categoryId options[:category_id] if options[:category_id]
              xml.amount options[:amount] if options[:amount]
              xml.suggestion options[:suggestion] if options[:suggestion]
              xml.currentAmountLeft options[:current_amount_left] if options[:current_amount_left]
              xml.defaultEcheance options[:default_echeance] if options[:default_echeance]
            }
          end
          builder.to_xml
        end

        def operation_future(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.operationFuture {
              xml.id options[:id] if options[:id]
              xml.userId options[:user_id] if options[:user_id]
              xml.factoryId options[:factory_id] if options[:factory_id]
              xml.date options[:date] if options[:date]
              xml.label options[:label] if options[:label]
              xml.amount options[:amount] if options[:amount]
              xml.categoryId options[:category_id] if options[:category_id]
              xml.supplierFound options[:supplier_found] if options[:supplier_found]
              xml.cityFound options[:city_found] if options[:city_found]
              xml.countryFound options[:country_found] if options[:country_found]
              xml.typeId options[:type_id] if options[:type_id]
              xml.adresse options[:adresse] if options[:adresse]
              xml.postalCode options[:postal_code] if options[:postal_code]
              xml.latitude options[:latitude] if options[:latitude]
              xml.longitude options[:longitude] if options[:longitude]
              xml.status options[:status] if options[:status] # WAITING_FOR_CONFIRMATION || LOOKING_FOR_OPERATION
              xml.futureStatus options[:future_status] if options[:future_status] # WAITING_FOR_CONFIRMATION || LOOKING_FOR_OPERATION
              xml.operationType options[:operation_type] if options[:operation_type] # CHECK || CB || PRELEV
              xml.accountId options[:account_id] if options[:account_id]
              xml.operationId options[:operation_id] if options[:operation_id]
              xml.duplicateOperationFutureId options[:duplicate_operation_future_id] if options[:duplicate_operation_future_id]
              xml.system options[:system] if options[:system]
            }
          end
          builder.to_xml
        end

        def operation_future_factory(options)
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.operationFutureFactory {
              xml.id options[:id] if options[:id]
              xml.userId options[:user_id] if options[:user_id]
              xml.period options[:period] if options[:period]
              xml.recurringCount options[:recurring_count] if options[:recurring_count]
              xml.operationFuture options[:operation_future] if options[:operation_future]
            }
          end
          builder.to_xml
        end
      end
    end
  end
end
