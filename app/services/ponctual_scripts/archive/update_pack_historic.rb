# -*- encoding : UTf-8 -*-
class PonctualScripts::Archive::UpdatePackHistoric
  def self.execute(pack_id)
    pack = Pack.find_by_id(pack_id)
    pack.with_lock do
      begin
        pack.update_attributes(content_historic: nil, tags: nil)
        pack.set_historic
        pack.set_tags
        pack.save
      rescue
        false
      end
    end
  end
end