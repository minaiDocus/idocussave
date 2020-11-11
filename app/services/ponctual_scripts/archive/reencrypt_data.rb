# Used when rotating encryption key
# Decrypt with the old key et re-encrypt with the new key
class PonctualScripts::Archive::ReencryptData
  def self.execute
    list = [
      [BudgeaAccount,      [:access_token]],
      [Retriever,          [:param1, :param2, :param3, :param4, :param5, :answers]],
      [NewProviderRequest, [:url, :login, :description, :message, :email, :password, :types]],
      [DropboxBasic,       [:access_token]],
      [GoogleDoc,          [:refresh_token, :access_token, :access_token_expires_at]],
      [Box,                [:refresh_token, :access_token]],
      [Ftp,                [:host, :port, :login, :password]],
      [Ibiza,              [:access_token, :access_token_2]],
      [Knowings,           [:url, :username, :password, :pole_name]]
    ]

    # NOTE: Disable update_states for Ibiza to avoid reverifying all the tokens
    Ibiza.skip_callback(:save, :before, :update_states)

    list.each do |klass, attributes|
      puts klass
      klass.all.each do |entry|
        attributes.each do |attribute|
          entry.send("#{attribute}=", entry.send(attribute))
        end
        entry.save
        print '.'
      end
      print "\n"
    end

    true
  end
end
