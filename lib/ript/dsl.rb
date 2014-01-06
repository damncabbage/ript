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
        puts "Error: Partition name '#{name}' is already defined!"
        puts " - existing definition: #{c.filename}:#{c.line}"
        puts " - new definition: #{filename}:#{line}"
        puts "Aborting."
        exit 140
      end

      if name =~ /\s+/
        puts "Error: #{filename}:#{line}"
        puts "Error: Partition name '#{name}' can't contain whitespace."
        puts "Aborting."
        exit 140
      end

      if name.count('-') > 0
        puts "Error: #{filename}:#{line}"
        puts "Error: Partition name '#{name}' can't contain dashes ('-')."
        puts "Aborting."
        exit 140
      end

      if name.length > 20
        puts "Error: #{filename}:#{line}"
        puts "Error: Partition name '#{name}' cannot be longer than 20 characters."
        puts "Aborting."
        exit 140
      end

      if filenames.include?(filename)
        puts "Error: #{filename}:#{line}"
        puts "Error: Multiple partition definitions are not permitted in the same file."
        puts "Aborting."
        exit 140
      end

      partition = Ript::Partition.new(name, block)
      self.partitions << partition
      self.filenames << filename
    end
  end
end

# Compatibility; dump the DSL methods into the global namespace.
include Ript::DSL
