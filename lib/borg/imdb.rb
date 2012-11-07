Dir[File.dirname(__FILE__) + 'imdb/*.rb'].each do |file|
  require File.basename(file, File.extname(file))
end
