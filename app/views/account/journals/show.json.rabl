object @journal

attributes :id, :slug, :name, :description, :client_ids, :requested_client_ids

#child :clients => :users do
#  attributes :id, :first_name, :last_name, :company, :code
#  node :journal_ids do |user|
#    user['account_book_type_ids']
#  end
#end
#
#child :requested_clients => :requested_users do
#  attributes :id, :first_name, :last_name, :company, :code
#end

#if current_user.admin?
#  node(:edit_url) { |article| edit_article_url(article) }
#end
#
#child :author do
#  attributes :id, :name
#  node(:url) { |author| author_url(author) }
#end
#
#child :comments do
#  attributes :id, :name, :content
#end

