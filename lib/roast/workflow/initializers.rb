# frozen_string_literal: true

require "roast/dot_roast"

module Roast
  module Workflow
    class Initializers
      class << self
        def load_all
          project_initializers = Roast::DotRoast.subdir_path("initializers")
          return unless project_initializers

          $stderr.puts "Loading project initializers from #{project_initializers}"
          pattern = File.join(project_initializers, "**/*.rb")
          Dir.glob(pattern, sort: true).each do |file|
            $stderr.puts "Loading initializer: #{file}"
            require file
          end
        rescue => e
          puts "ERROR: Error loading initializers: #{e.message}"
          Roast::Helpers::Logger.error("Error loading initializers: #{e.message}")
        end
      end
    end
  end
end
