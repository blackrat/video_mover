Dir[File.dirname(__FILE__) + 'common/*.rb'].each do |file|
  require File.basename(file, File.extname(file))
end
