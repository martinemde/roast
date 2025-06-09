# frozen_string_literal: true

require "roast"

module Roast
  class DotRoast
    autoload :Initializers, "roast/dot_roast/initializers"
    autoload :Cache, "roast/dot_roast/cache"

    class << self
      def root(starting_path = Dir.pwd, ending_path = File.dirname(Dir.home))
        unless starting_path.start_with?(ending_path)
          Roast::Helpers::Logger.warn(<<~WARN)
            Unexpected ending path when looking for .roast:
            Starting path #{starting_path} is not a subdir of ending path #{ending_path}
            Will check all the way up to root.
          WARN

          ending_path = "/"
        end

        candidate = starting_path
        while candidate != ending_path
          break if Dir.exist?(File.join(candidate, ".roast"))

          candidate = File.dirname(candidate)
        end

        File.join(candidate, ".roast")
      end
    end
  end
end
