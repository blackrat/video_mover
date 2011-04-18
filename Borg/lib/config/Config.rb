require 'yaml'
class Object
  def meta_def name, &blk
    (class <<self; self; end).instance_eval { define_method name, &blk }
  end
end

module Config
  DIRECTORIES={:etc=>['~/.borg','/etc/borg','../etc']}
  CONFIG_EXT=".yml"
  basedir=File.expand_path(File.expand_path(File.join(File.dirname(__FILE__),'..','..')))

  DIRECTORIES.each { |name,dir|
    meta_def(name.to_s+'_dir') {
      dir=[dir] unless dir.is_a?(Array)
      dir.each { |gdir| gdir.to_s[0].chr=='/' ? gdir : File.expand_path(File.join(basedir,gdir.to_s)) }
    }
  }

  def self.included(base)
    base.extend ConfigMethods
  end

  module ConfigMethods
    def config(*arr)
      arr.each do |file|
        meta_def(file) {
          @cf=nil
          DIRECTORIES[:etc].each { |cd|
            @cf=File.expand_path(File.join(cd,"#{file}#{CONFIG_EXT}"))
            break if File.exists?(@cf)
          } if @cf.nil?
          File.exists?(@cf) ? (YAML.load_file(@cf)) : nil
        }
      end
    end
  end
end
