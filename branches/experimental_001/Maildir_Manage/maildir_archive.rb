#!/usr/bin/env ruby
#
#  Created by Paul McKibbin on 2006-11-05.
#  Copyright (c) 2006. All rights reserved.

ARCHIVE_LIST="~/.maildir_archive.xml"
MAIL_ROOT   ="~/Maildir"

maildirs=[]
default ={ :name => "", :archive_name => "~/.Maildir_archive/", :expiry => 7 };
archive_list=File.expand_path(ARCHIVE_LIST)
maildirs << default
if File.exists?(archive_list) then
  require 'rexml/document'
  doc=REXML::Document.new(open(archive_list))
  doc.root.each_element('//maildir') do |p|
    maildirs << p.attributes
  end
end
Dir.chdir(File.expand_path(MAIL_ROOT))
Dir[".*"].each do |source_directory|
  file=maildirs.find { |e| e["name"]==source_directory }
  if file then
    require "ftools"
    srcdir=File.join(File.expand_path(MAIL_ROOT), file["name"], "cur")
    dstdir=File.join(File.expand_path(file["archive_name"]), "cur")
    File.makedirs(dstdir) unless File.exists?(dstdir)
    i=0
    Dir[File.join(srcdir, "*")].each do |oldname|
      age_s = Time.new - File.mtime(oldname)
      if age_s > ((file["expiry"].to_i)*24*60*60)
        if dstdir
          if File.split(oldname)[1] =~ /^\d+[^:]*(:.*)?$/
            newname = sprintf("#{dstdir}/%d.%d.autoarchive.%07d%s", Time.now.to_i, Process.pid, i, Regexp.last_match(1))
            i       += 1
            File.rename(oldname, newname)
          end
        end
      end
    end
  end
end