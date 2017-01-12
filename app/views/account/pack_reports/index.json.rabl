object false

child @pack_reports => :items do
  extends 'account/pack_reports/show'
end

node :page do
  params[:page] || 1
end

node :per_page do
  params[:per_page] || Kaminari.config.default_per_page
end

node :total do
  @pack_reports_count
end
