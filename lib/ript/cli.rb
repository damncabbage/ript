module Ript
  module CLI
    module_function

    def load_rules_from_path(path)
      case
      when File.directory?(path)
        files = Dir.glob(File.join(path, '**/*.rb'))
        files.each do |file|
          require file
        end
      when File.exist?(path)
        require path
      else
        raise LoadError, "The specified rule file or directory '#{path}' does not exist"
      end
    end

  end
end
