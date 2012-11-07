require '../../lib/common/yaml_config'
module BorgConfig
  include ::YamlConfig
  directories :etc=>['~/.borg','/etc/borg','../etc']

end
