# frozen_string_literal: true

module Cotcube
  module Helpers

    def config_prefix
      os = Gem::Platform.local.os
      case os
      when 'linux'
        ''
      when 'freebsd'
        '/usr/local'
      else
        raise RuntimeError, "Unsupported architecture: #{os}"
      end
    end

    def config_path
      config_prefix + '/etc/cotcube'
    end

    def init(config_file_name: nil, 
             gem_name: nil,
             debug: false)
      gem_name ||= self.ancestors.first.to_s
      config_file_name = "#{gem_name.down_case}.yml"
      config_file = config_path + "/#{config_file_name}"

      if File.exist?(config_file)
        config      = YAML.load(File.read config_file).transform_keys(&:to_sym)
      else
        config      = {} 
      end

      defaults = { 
        data_path: '/var/cotcube/' + name,
      }

      config = defaults.merge(config)
      puts "CONFIG is '#{config}'" if debug

      config
    end
  end
end

