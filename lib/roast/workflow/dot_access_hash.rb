# typed: true
# frozen_string_literal: true

module Roast
  module Workflow
    class DotAccessHash
      def initialize(hash)
        @hash = hash || {}
      end

      def [](key)
        value = @hash[key.to_sym] || @hash[key.to_s]
        wrap_value(value)
      end

      def []=(key, value)
        @hash[key.to_sym] = value
      end

      def method_missing(method_name, *args, &block)
        method_str = method_name.to_s

        # Handle boolean predicate methods (ending with ?)
        if method_str.end_with?("?")
          key = method_str.chomp("?")
          # Always return false for non-existent keys with ? methods
          return false unless has_key?(key) # rubocop:disable Style/PreferredHashMethods

          !!self[key]
        # Handle setter methods (ending with =)
        elsif method_str.end_with?("=")
          key = method_str.chomp("=")
          self[key] = args.first
        # Handle bang methods (ending with !) - should raise
        elsif method_str.end_with?("!")
          super
        # Handle regular getter methods
        elsif args.empty? && block.nil?
          # Return nil for non-existent keys (like a hash would)
          self[method_str]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        method_str = method_name.to_s

        if method_str.end_with?("!")
          false # Don't respond to bang methods
        elsif method_str.end_with?("?")
          true  # Always respond to predicate methods
        elsif method_str.end_with?("=")
          true  # Always respond to setter methods
        else
          true  # Always respond to getter methods (they return nil if missing)
        end
      end

      def to_h
        @hash
      end

      def keys
        @hash.keys
      end

      def empty?
        @hash.empty?
      end

      def each(&block)
        @hash.each(&block)
      end

      def to_s
        @hash.to_s
      end

      def inspect
        @hash.inspect
      end

      def to_json(*args)
        @hash.to_json(*args)
      end

      def merge(other)
        merged_hash = @hash.dup
        other_hash = other.is_a?(DotAccessHash) ? other.to_h : other
        merged_hash.merge!(other_hash)
        DotAccessHash.new(merged_hash)
      end

      def values
        @hash.values
      end

      def key?(key)
        has_key?(key) # rubocop:disable Style/PreferredHashMethods
      end

      def include?(key)
        has_key?(key) # rubocop:disable Style/PreferredHashMethods
      end

      def fetch(key, *args)
        if has_key?(key) # rubocop:disable Style/PreferredHashMethods
          self[key]
        elsif block_given?
          yield(key)
        elsif !args.empty?
          args[0]
        else
          raise KeyError, "key not found: #{key.inspect}"
        end
      end

      def dig(*keys)
        keys.inject(self) do |obj, key|
          break nil unless obj.is_a?(DotAccessHash) || obj.is_a?(Hash)

          if obj.is_a?(DotAccessHash)
            obj[key]
          else
            obj[key.to_sym] || obj[key.to_s]
          end
        end
      end

      def size
        @hash.size
      end

      alias_method :length, :size

      def map(&block)
        @hash.map(&block)
      end

      def select(&block)
        DotAccessHash.new(@hash.select(&block))
      end

      def reject(&block)
        DotAccessHash.new(@hash.reject(&block))
      end

      def compact
        DotAccessHash.new(@hash.compact)
      end

      def slice(*keys)
        sliced = {}
        keys.each do |key|
          if has_key?(key) # rubocop:disable Style/PreferredHashMethods
            sliced[key.to_sym] = @hash[key.to_sym] || @hash[key.to_s]
          end
        end
        DotAccessHash.new(sliced)
      end

      def except(*keys)
        excluded = @hash.dup
        keys.each do |key|
          excluded.delete(key.to_sym)
          excluded.delete(key.to_s)
        end
        DotAccessHash.new(excluded)
      end

      def delete(key)
        @hash.delete(key.to_sym) || @hash.delete(key.to_s)
      end

      def clear
        @hash.clear
        self
      end

      def ==(other)
        case other
        when DotAccessHash
          @hash == other.instance_variable_get(:@hash)
        when Hash
          @hash == other
        else
          false
        end
      end

      def has_key?(key_name)
        @hash.key?(key_name.to_sym) || @hash.key?(key_name.to_s)
      end

      alias_method :member?, :has_key?

      private

      def wrap_value(value)
        case value
        when Hash
          DotAccessHash.new(value)
        when Array
          # Don't create a new array - return the original array
          # Only wrap Hash elements within the array when needed
          value
        else
          value
        end
      end
    end
  end
end
