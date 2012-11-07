require 'borg/yaml_config'
module Borg
  module Config
    class << self
      def included(base)
        base.class_eval do
          include Borg::YamlConfig
          directories :etc => ['~/.borg', '/etc/borg', '../etc', '../../etc']
        end
      end
    end
  end
end
