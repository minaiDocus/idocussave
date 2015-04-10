# Some gems load ActiveRecord even thought it is not needed, so to fix rspec-rails loading process
# See rspec-rails-x.x.x/lib/rspec/rails/extensions/active_record/base.rb:13
module ActiveRecord
  module VERSION
    STRING = '3.2.21'
  end
end
