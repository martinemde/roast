# typed: true
# frozen_string_literal: true

module Roast
  module Helpers
    # Utility class for resolving file paths with directory structure issues
    class PathResolver
      class << self
        # Intelligently resolves a path considering possible directory structure issues
        def resolve(path)
          # Store original path for logging if needed
          original_path = path

          # Early return if the path is nil or empty
          return path if path.nil? || path.empty?

          # First try standard path expansion
          expanded_path = File.expand_path(path)

          # Return early if the file exists at the expanded path
          return expanded_path if File.exist?(expanded_path)

          # Get current directory and possible project root paths
          current_dir = Dir.pwd
          possible_roots = [
            current_dir,
            File.expand_path(File.join(current_dir, "..")),
            File.expand_path(File.join(current_dir, "../..")),
            File.expand_path(File.join(current_dir, "../../..")),
            File.expand_path(File.join(current_dir, "../../../..")),
            File.expand_path(File.join(current_dir, "../../../../..")),
          ]

          # Check for directory name duplications anywhere in the path
          path_parts = expanded_path.split(File::SEPARATOR).reject(&:empty?)

          # Try removing each duplicate segment individually and check if the resulting path exists
          path_parts.each_with_index do |part, i|
            next if i == 0 # Skip the first segment

            # Check if this segment appears earlier in the path
            next unless path_parts[0...i]&.include?(part)

            # Create a new path without this segment
            test_parts = path_parts.dup
            test_parts.delete_at(i)
            test_parts.prepend("/") if original_path.start_with?("/")

            test_path = File.join(test_parts)

            # If this path exists, return it
            return test_path if File.exist?(test_path)

            # Also try removing all future occurrences of this segment name
            duplicate_indices = []
            path_parts.each_with_index do |segment, idx|
              if idx > 0 && segment == part && idx >= i
                duplicate_indices << idx
              end
            end

            next if duplicate_indices.none?

            filtered_parts = path_parts.dup
            # Remove from end to beginning to keep indices valid
            duplicate_indices.reverse_each { |idx| filtered_parts.delete_at(idx) }
            filtered_parts.prepend("/") if original_path.start_with?("/")
            test_path = File.join(filtered_parts)

            return test_path if File.exist?(test_path)
          end

          # Try detecting all duplicates at once
          seen_segments = {}
          duplicate_indices = []

          path_parts.each_with_index do |part, i|
            if seen_segments[part]
              duplicate_indices << i
            else
              seen_segments[part] = true
            end
          end

          if duplicate_indices.any?
            # Try removing all duplicates
            unique_parts = path_parts.dup
            # Remove from end to beginning to keep indices valid
            duplicate_indices.reverse_each { |i| unique_parts.delete_at(i) }
            unique_parts.prepend("/") if original_path.start_with?("/")
            test_path = File.join(unique_parts)

            return test_path if File.exist?(test_path)
          end

          # Try relative path resolution from various possible roots
          relative_path = path.sub(%r{^\./}, "")
          possible_roots.each do |root|
            # Try the path as-is from this root
            candidate = File.join(root, relative_path)
            return candidate if File.exist?(candidate)

            # Try with a leading slash removed
            if relative_path.start_with?("/")
              candidate = File.join(root, relative_path.sub(%r{^/}, ""))
              return candidate if File.exist?(candidate)
            end
          end

          # Try extracting the path after a potential project root
          if expanded_path.include?("/src/") || expanded_path.include?("/lib/") || expanded_path.include?("/test/")
            # Potential project markers
            markers = ["/src/", "/lib/", "/test/", "/app/", "/config/"]
            markers.each do |marker|
              next unless expanded_path.include?(marker)

              # Get the part after the marker
              parts = expanded_path.split(marker, 2)
              next unless parts.size == 2

              marker_dir = marker.gsub("/", "")
              relative_from_marker = parts[1]

              # Try each possible root with this marker
              possible_roots.each do |root|
                candidate = File.join(root, marker_dir, relative_from_marker)
                return candidate if File.exist?(candidate)
              end
            end
          end

          # Default to the original expanded path if all else fails
          expanded_path
        end
      end
    end
  end
end
