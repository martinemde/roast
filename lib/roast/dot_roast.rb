# frozen_string_literal: true

require "fileutils"
require "roast/helpers/logger"

module Roast
  module DotRoast
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
        until candidate == ending_path
          dot_roast_candidate = File.join(candidate, ".roast")
          return dot_roast_candidate if Dir.exist?(dot_roast_candidate)

          candidate = File.dirname(candidate)
        end

        File.join(starting_path, ".roast")
      end

      def ensure_subdir(subdir_name, gitignored: true)
        subdir_path = File.join(root, subdir_name)
        FileUtils.mkdir_p(subdir_path) unless File.directory?(subdir_path)

        if gitignored
          gitignore_path = File.join(subdir_path, ".gitignore")
          File.write(gitignore_path, "*") unless File.exist?(gitignore_path)
        end

        subdir_path
      end

      def subdir_path(subdir_name)
        path = File.join(root, subdir_name)
        File.directory?(path) ? path : nil
      end
    end
  end
end
