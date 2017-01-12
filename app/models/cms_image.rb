# -*- encoding : UTF-8 -*-
class CmsImage < ActiveRecord::Base
  has_attached_file :content,
                            styles: {
                              thumb: ['96x96>', :png]
                            },
                            path: ':rails_root/public:url',
                            url: '/system/:rails_env/:class/:attachment/:id/:style/:filename',
                            use_timestamp: false
  do_not_validate_attachment_file_type :content


  def name
    original_file_name || content_file_name
  end
end
