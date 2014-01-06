require 'pathname'
require 'ript/bootstrap'

module Ript
  module CLI
    module_function

    def load_rules_from_path(path)
      case
      when File.directory?(path)
        path = File.join(path, "**/*.rb")
        files = Dir.glob(path)
        files.each do |file|
          load_rule(file)
        end
      when File.exist?(path)
        load_rule(path)
      else
        raise RulesNotFoundError, "The specified rule file or directory '#{path}' does not exist"
      end
    end

    def load_rule(path)
      require path
    rescue LoadError => e
      raise RulesNotFoundError, "The specified rule file '#{path}' does not exist"
    end

    def requires_bootstrap?
      `iptables --list partition-a --numeric 2>&1 | grep Chain` !~ /^Chain/
    end

    def bootstrap
      "# bootstrap\n#{Ript::Bootstrap.partition.to_iptables}\n"
    end

    class RulesNotFoundError < StandardError; end
  end
end
