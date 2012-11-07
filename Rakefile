require 'rubygems'
require 'fileutils'
libdir=File.join($:.last, 'borg', 'common')
puts libdir
LIBLIST =["borg_config.rb", "string.rb", "title_case.rb", "with_index.rb", "file_name.rb", "file_type.rb", "meta.rb", "yaml_config.rb"]
datadir ="/etc/borg"
DATALIST=["extensions.yml", "extractions.yml", "fixups.yml", "regular_expressions.yml", "replacements.yml", "borg_params.yml"]
bindir  ="/usr/local/bin"
BINLIST =["movevideo", "moveall"]

desc "Install Borg Applications"
task :install => [:libfiles, :datafiles, :binfiles]
task :uninstall => [:rem_libfiles, :rem_datafiles, :rem_binfiles]

desc "Install library files"
task :libfiles do
  mkdir_p libdir
  LIBLIST.each do |x|
    puts("Copying #{x}")
    cp File.join('lib', 'config', x), libdir
  end
end

desc "Uninstall library files"
task :rem_libfiles do
  LIBLIST.each do |x|
    puts("Removing #{x}")
    rm File.join(libdir, x)
  end
end

desc "Install data files"
task :datafiles do
  mkdir_p datadir
  DATALIST.each do |x|
    puts("Copying #{x}")
    cp File.join('etc', x), datadir
  end
end

desc "Uninstall data files"
task :rem_datafiles do
  DATALIST.each do |x|
    puts("Removing #{x}")
    rm File.join(datadir, x)
  end
end


desc "Install executable"
task :binfiles do
  BINLIST.each do |x|
    puts("Copying #{x}")
    cp File.join('bin', x), bindir
  end
end

desc "Uninstall executable"
task :rem_binfiles do
  BINLIST.each do |x|
    puts("Removing #{x}")
    rm File.join(bindir, x)
  end
end
