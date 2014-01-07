module Ript
  module Iptables
    module_function

    def has_partition?(type)
      `iptables --list #{partition_types[type]} --numeric 2>&1 | grep Chain` =~ /^Chain/
    end

    def partition_types
      {
        :a => 'filter',
        :d => 'nat',
        :s => 'nat',
      }
    end

    def current_chain_names_by_partition
      # Collect the full iptables output
      output = {}
      partition_types.each_pair do |type, table|
        output[type] =  `iptables --table #{table} --list partition-#{type} --numeric 2>&1 | grep -v 'No chain/target/match by that name'`.split("\n")
      end

      blacklist  = %w(PREROUTING POSTROUTING OUTPUT INPUT FORWARD Chain target before-a after-a partition-a partition-d partition-s)
      chains = {}

      partition_types.keys.each do |type|
        chains[type] = {}
        output[type].each do |line|
          chain_name = line.split(/ /).first
          next if blacklist.include? chain_name
          partition = chain_name.split(/-/).first
          chains[type][partition] ||= []
          chains[type][partition] << chain_name
        end
      end

      # Add the chains that aren't referenced anywhere to the end
      ['nat', 'filter'].each do |table|
        unlisted = `iptables --table #{table} --list --numeric 2>&1 | grep 'Chain'`.split("\n")
        unlisted = unlisted.map {|l| l.split(/ /)[1]} - blacklist
        unlisted.each do |chain_name|
          partition, type = chain_name.split(/-/)
          type = type[0].to_sym
          chains[type][partition] ||= []
          unless chains[type][partition].include? chain_name
            chains[type][partition] << chain_name
          end
        end
      end
      chains
    end

  end
end
