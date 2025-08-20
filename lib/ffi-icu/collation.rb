# frozen_string_literal: true

module ICU
  module Collation
    ATTRIBUTES = {
      :french_collation => 0,
      :alternate_handling => 1,
      :case_first => 2,
      :case_level => 3,
      :normalization_mode => 4,
      :strength => 5,
      :hiragana_quaternary_mode => 6,
      :numeric_collation => 7
    }.freeze

    ATTRIBUTE_VALUES = {
      nil => -1,
      :primary => 0,
      :secondary => 1,
      :default_strength => 2,
      :tertiary => 2,
      :quaternary => 3,
      :identical => 15,

      false => 16,
      true => 17,

      :shifted => 20,
      :non_ignorable => 21,

      :lower_first => 24,
      :upper_first => 25
    }.freeze

    ATTRIBUTE_VALUES_INVERSE = ATTRIBUTE_VALUES.to_h { |k, v| [v, k] }.freeze

    def self.collate(locale, arr)
      Collator.new(locale).collate(arr)
    end

    def self.keywords
      enum_ptr = Lib.check_error { |error| Lib.ucol_getKeywords(error) }
      keywords = Lib.enum_ptr_to_array(enum_ptr)
      Lib.uenum_close(enum_ptr)

      hash = {}
      keywords.each do |keyword|
        enum_ptr = Lib.check_error { |error| Lib.ucol_getKeywordValues(keyword, error) }
        hash[keyword] = Lib.enum_ptr_to_array(enum_ptr)
        Lib.uenum_close(enum_ptr)
      end

      hash
    end

    def self.available_locales
      (0...Lib.ucol_countAvailable).map do |idx|
        Lib.ucol_getAvailable(idx)
      end
    end

    class Collator
      ULOC_VALID_LOCALE = 1
      UCOL_DEFAULT = -1
      UCOL_ON = 17
      UCOL_PRIMARY = 0

      def initialize(locale)
        case locale
        when 'bo'
          rules = File.read(File.join(__dir__, '/collation_rules/bo_rules.txt'))
          set_rules(rules)
        when 'new-Deva'
          rules = File.read(File.join(__dir__, '/collation_rules/new-Deva_rules.txt'))
          set_rules(rules)
        when 'new Newa'
          rules = File.read(File.join(__dir__, '/collation_rules/new-Newa_rules.txt'))
          set_rules(rules)
        else
          ptr = Lib.check_error { |error| Lib.ucol_open(locale, error) }
          @c = FFI::AutoPointer.new(ptr, Lib.method(:ucol_close))
        end
      end

      def locale
        Lib.check_error { |error| Lib.ucol_getLocale(@c, ULOC_VALID_LOCALE, error) }
      end

      def compare(a, b)
        Lib.ucol_strcoll(
          @c,
          UCharPointer.from_string(a), a.size,
          UCharPointer.from_string(b), b.size
        )
      end

      def greater?(a, b)
        Lib.ucol_greater(@c, UCharPointer.from_string(a), a.size,
                         UCharPointer.from_string(b), b.size)
      end

      def greater_or_equal?(a, b)
        Lib.ucol_greaterOrEqual(@c, UCharPointer.from_string(a), a.size,
                                UCharPointer.from_string(b), b.size)
      end

      def equal?(*args)
        return super() if args.empty?

        raise(ArgumentError, "wrong number of arguments (#{args.size} for 2)") if args.size != 2

        a, b = args

        Lib.ucol_equal(@c, UCharPointer.from_string(a), a.size,
                       UCharPointer.from_string(b), b.size)
      end

      def collate(sortable)
        raise(ArgumentError, 'argument must respond to :sort with arity of 2') unless sortable.respond_to?(:sort)

        sortable.sort { |a, b| compare(a, b) }
      end

      def rules
        @rules ||= begin
          length = FFI::MemoryPointer.new(:int)
          ptr = Lib.ucol_getRules(@c, length)
          ptr.read_array_of_uint16(length.read_int).pack('U*')
        end
      end

      def collation_key(string)
        ptr = UCharPointer.from_string(string)
        size = Lib.ucol_getSortKey(@c, ptr, string.size, nil, 0)
        buffer = FFI::MemoryPointer.new(:char, size)
        Lib.ucol_getSortKey(@c, ptr, string.size, buffer, size)
        buffer.read_bytes(size - 1)
      end

      def [](attribute)
        ATTRIBUTE_VALUES_INVERSE[Lib.check_error do |error|
          Lib.ucol_getAttribute(@c, ATTRIBUTES[attribute], error)
        end]
      end

      def []=(attribute, value)
        Lib.check_error do |error|
          Lib.ucol_setAttribute(@c, ATTRIBUTES[attribute], ATTRIBUTE_VALUES[value], error)
        end
      end

      # create friendly named methods for setting attributes
      ATTRIBUTES.each_key do |attribute|
        class_eval <<-CODE, __FILE__, __LINE__ + 1
          # def case_first
          #   self[:case_first]
          # end
          #
          # def case_first=(value)
          #   self[:case_first] = value
          # end

          def #{attribute}
            self[:#{attribute}]
          end

          def #{attribute}=(value)
            self[:#{attribute}] = value
          end
        CODE
      end
      
      def set_rules(string)
        ptr = Lib.check_error { |error| ICU::Lib.ucol_openRules(UCharPointer.from_string(string), string.mb_chars.length, UCOL_ON, UCOL_PRIMARY, nil, error) }
        @c = FFI::AutoPointer.new(ptr, Lib.method(:ucol_close))
      end
    end
  end
end
