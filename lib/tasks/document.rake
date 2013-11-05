# -*- encoding : UTF-8 -*-
namespace :document do
  namespace :bundler do
    desc 'Prepare bundle process'
    task :prepare => [:environment] do
      PrepaCompta::DocumentBundler.prepare
    end
  end
end
