# frozen_string_literal: true

require "digest"

module Roast
  class DotRoast
    class Cache
      class << self
        def for_workflow(workflow_name, workflow_path)
          namespace = workflow_name + Digest::MD5.hexdigest(workflow_path).first(4)
          for_namespace(namespace)
        end

        def for_namespace(namespace)
          ensure_exists
          ensure_gitignore_exists
          @cache = ActiveSupport::Cache::FileStore.new(path_for_namespace(namespace))
          @cache
        end

        def path_for_namespace(namespace)
          namespace.empty? ? path : File.join(path, namespace)
        end

        def path
          File.join(DotRoast.root, "cache")
        end

        def ensure_exists
          FileUtils.mkdir_p(path) unless File.directory?(path)
        end

        def gitignore_path
          File.join(path, ".gitignore")
        end

        def ensure_gitignore_exists
          File.write(gitignore_path, "*") unless File.exist?(gitignore_path)
        end
      end
    end
  end
end
