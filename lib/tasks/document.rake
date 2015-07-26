# -*- encoding : UTF-8 -*-
namespace :document do
  namespace :bundler do
    desc 'Prepare bundle process'
    task :prepare => [:environment] do
      puts "[#{Time.now}] document:bundler:prepare - START"
      PrepaCompta::DocumentBundler.prepare
      puts "[#{Time.now}] document:bundler:prepare - END"
    end
  end
end
