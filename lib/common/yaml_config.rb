require 'yaml'
require '../../lib/common/meta'

module YamlConfig
  include Meta

  class << self
    def included(base)
      base.instance_eval do
        extend ClassMethods
        attr_accessor :config_directories
      end
    end
  end

  module ClassMethods
    def yaml_extension
      '.yml'
    end

    def directories(*arr)
      basedir=File.expand_path(File.expand_path(File.join(File.dirname(__FILE__),'..','..')))
      arr.each do |directory,dirlist|
        config_directories[directory]=dirlist
        meta_def(directory.to_s+'_dir') {
          dir=[dir] unless dir.is_a?(Array)
          dir.each {|gdir| gdir.to_s.chr=='/' ? gdir : File.expand_path(File.join(basedir,gdir.to_s))}
        }
      end
    end

    def config(*arr)
      arr.each do |file|
        meta_def(file) {
          cf=nil
          meta.directories[:etc].each { |cd|
            cf=File.expand_path(File.join(cd,"#{file}#{CONFIG_EXT}"))
            break if File.exists?(cf)
          }
          File.exists?(cf) ? (YAML.load_file(cf)) : nil
        }
      end
    end
  end
end
