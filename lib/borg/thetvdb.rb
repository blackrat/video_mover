Dir[File.dirname(__FILE__) + 'thetvdb/*.rb'].each do |file|
  require File.basename(file, File.extname(file))
end
