module Bitstat
  module DataProviders
    class Physpages
      include Bitlogger::Loggable

      def initialize(options)
        @resources_path = options.fetch(:resources_path)
        @vpss           = {}
      end

      def regenerate
        nodes  = []
        params = [:kmemsize, :oomguarpages, :swappages]
        resources = get_file_contents(@resources_path)
        resources.shift
        resources.shift
        resources = resources.map! { |l| l.split(':') }.flatten!

        id = 0
        resources.each_index do |i|
          line = resources[i].strip
          if i % 22 == 0
            id = line.to_i
            nodes.push({ :veid => id })
          else
            params.each do |p|
              nodes.last[p] = line.split[1].to_i if line.strip.start_with?(p.to_s)
            end
          end
        end

        @vpss = calculate_all(nodes)
      end

      def get_file_contents(path)
        File.readlines(path)
      rescue Errno::ENOENT => e
        warn("File #{path} does not exist, retrying ...")
        sleep(0.01)
        retry
      end

      def calculate_all(nodes)
        out = []
        nodes.each do |node|
          out.push({ :physpages => calculate_mb(
                                       node[:swappages],
                                       node[:kmemsize],
                                       node[:oomguarpages]
                                   ),
                     :veid      => node[:veid] })
        end

        out
      end

      def calculate_mb(swappages, kmemsize, oomguarpages)
        (((kmemsize / 1024) + (oomguarpages - swappages) * 4) / 1024).to_i
      end

      def each_vps(&block)
        @vpss.each { |vps| block.call(vps) }
      end

      def vpss
        # returns hash of vpss indexed by veid and deletes veid from vps data
        @vpss.inject({}) { |out, vps| out[vps[:veid].to_i] = vps.reject { |k, _| k == :veid } ; out }
      end
    end
  end
end