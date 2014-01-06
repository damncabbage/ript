if RUBY_VERSION =~ /^1.8/ then
  puts "Ript requires Ruby 1.9 to run. Exiting."
  exit 2
end

$LOAD_PATH << File.expand_path('../..', File.dirname(__FILE__))

require 'ript/dsl/primitives'
require 'ript/rule'
require 'ript/partition'
require 'ript/exceptions'
require 'ript/patches'

module Ript
  module DSL
    attr_writer :partitions
    def partitions
      @partitions ||= []
    end

    attr_writer :filenames
    def filenames
      @filenames ||= []
    end

    # Top-level DSL method; everything hangs off the Partition definition.
    # Other DSL methods are accessible from inside the partition's block.
    def partition(name, &block)
      filename, line = caller.first.split(':')[0..1]

      if c = partitions.find {|c| c.name == name }
        raise PartitionNameError, [
          "Error: Partition name '#{name}' is already defined!",
          " - existing definition: #{c.filename}:#{c.line}",
          " - new definition: #{filename}:#{line}",
        ].join("\n")
      end

      if name =~ /\s+/
        raise PartitionNameError, [
          "Error: #{filename}:#{line}",
          "Error: Partition name '#{name}' can't contain whitespace.",
        ].join("\n")
      end

      if name.count('-') > 0
        raise PartitionNameError, [
          "Error: #{filename}:#{line}",
          "Error: Partition name '#{name}' can't contain dashes ('-').",
        ].join("\n")
      end

      if name.length > 20
        raise PartitionNameError, [
          "Error: #{filename}:#{line}",
          "Error: Partition name '#{name}' cannot be longer than 20 characters.",
        ].join("\n")
      end

      if self.filenames.include?(filename)
        raise PartitionNameError, [
          "Error: #{filename}:#{line}",
          "Error: Multiple partition definitions are not permitted in the same file.",
        ].join("\n")
      end

      partition = Ript::Partition.new(name, block)
      self.partitions << partition
      self.filenames << filename

    rescue PartitionNameError => e
      # TODO: Move exits and exit codes back out into the CLI app itself.
      # Catch them here for compatibility's sake in the mean time.
      puts e.message
      puts "Aborting."
      exit 140
    end
  end
end

# Compatibility; dump the DSL methods into the global namespace.
include Ript::DSL
