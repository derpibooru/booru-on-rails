# frozen_string_literal: true

require 'time'
require 'relative_date_parser'

class SearchTerm
  attr_accessor :term, :float_fields, :literal_fields, :int_fields
  attr_accessor :ngram_fields, :boost, :fuzz
  attr_reader :wildcarded, :ngram_query

  def initialize(term, default_field, options = {})
    @term = term
    allowed_fields = (options[:allowed_fields] || {})
    # List of accepted literal fields.
    @literal_fields = (allowed_fields[:literal] || [])
    # List of accept boolean fields.
    @boolean_fields = (allowed_fields[:boolean] || [])
    # List of NLP-analyzed fields.
    @ngram_fields = (allowed_fields[:full_text] || [])
    # List of date/time fields.
    @date_fields = (allowed_fields[:date] || [])
    # List of floating point fields.
    @float_fields = (allowed_fields[:float] || [])
    # List of integer fields.
    @int_fields = (allowed_fields[:integer] || [])
    # List of allowed IP fields
    @ip_fields = (allowed_fields[:ip] || [])
    @fuzz = options[:fuzz]
    @boost = options[:boost]
    @field_aliases = options[:aliases] || {}
    @field_transforms = options[:transforms] || {}
    @no_downcase = options[:no_downcase] || []
    @default_field = default_field
    @ngram_query = @wildcarded = false
  end

  def append(str)
    @term.concat str.downcase
  end

  def prepend(str)
    @term.prepend(str.downcase)
  end

  def normalize_field_name(field_name)
    if @field_aliases.key?(field_name)
      @field_aliases[field_name]
    else
      field_name
    end
  end

  def normalize_val(field_name, val, range = nil)
    if @int_fields.include?(field_name)
      begin
        val = Integer(val)

        # convert to range
        val = { gte: val - @fuzz, lte: val + @fuzz } if @fuzz && range.nil?
      rescue StandardError
        raise SearchParsingError,
              "Values of \"#{field_name}\" field must be decimal integers; " \
              "\"#{val}\" is invalid."
      end
    elsif @boolean_fields.include?(field_name)
      if !%w[true false].include?(val)
        raise SearchParsingError,
              "Values of \"#{field_name}\" must be \"true\" or \"false\"; " \
              "\"#{val}\" is invalid."
      end
    elsif @ip_fields.include?(field_name)
      begin
        IPAddr.new(val)
      rescue StandardError
        raise SearchParsingError, "Values of \"#{field_name}\" must be IP "\
              "addresses or CIDR ranges; \"#{val}\" is invalid."
      end
    elsif @date_fields.include?(field_name)
      if val.empty?
        raise SearchParsingError,
              "Field \"#{field_name}\" missing date/time value."
      end

      # Convert date into date/time.
      orig_val = val.clone

      # Has an error occurred?
      err = false

      # Ordered arguments used to construct time representations.
      time_data = [nil, nil, nil, nil, nil, nil]
      target_index = -1

      # Get and detach timezone. (The timezone here would default to UTC.)
      timezone = nil
      val.gsub!(/(?:\s*[Zz]|[\+\-]\d{2}:\d{2})$/) do |m|
        timezone = m
        timezone = nil if %w[z Z].include? timezone
        ''
      end

      sym_table = [
        /^(\d{4})/,
        /^\-(\d{2})/,
        /^\-(\d{2})/,
        /^(?:\s+|T|t)(\d{2})/,
        /^:(\d{2})/,
        /^:(\d{2})/
      ]

      higher = lower = nil

      sym_table.each do |re|
        if val.empty?
          break
        else
          target_index += 1
          if val =~ re
            time_data[target_index] = Regexp.last_match[1].to_i
            val.gsub!(re, '')
          else
            err = true
            break
          end
        end
      end

      # Calculate the limits of the required query.
      if !err
        begin
          if timezone.nil?
            lower = Time.utc(*time_data)
          else
            time_data << timezone
            lower = Time.new(*time_data) # rubocop:disable Rails/TimeZone
          end
          return { range.to_sym => lower } if %w[lt gte].include? range
        rescue StandardError
          err = true
        end
      end

      while !err && higher.nil?
        time_data[target_index] += 1
        begin
          higher = if timezone.nil?
            Time.utc(*time_data)
          else
            Time.new(*time_data) # rubocop:disable Rails/TimeZone
          end
        rescue StandardError
          time_data[target_index] = if target_index < 3
            # Days and months roll back to 1.
            1
          else
            0
          end
          target_index -= 1
          err = true if target_index < 0
        end
      end

      if err
        higher, lower = RelativeDateParser.parse(orig_val)

        if higher
          return { range.to_sym => lower } if %w[lt gte].include? range

          err = nil # reset error state
        end
      end

      if err
        raise SearchParsingError, "Value \"#{orig_val}\" is not recognized as a valid ISO 8601 date/time."
      elsif range == 'lte'
        return { lt: higher }
      elsif range == 'gt'
        return { gte: higher }
      else
        return { gte: lower, lt: higher }
      end
    elsif @float_fields.include?(field_name)
      begin
        val = Float(val)
        val = { gte: val - @fuzz, lte: val + @fuzz } if @fuzz && range.nil?
      rescue StandardError
        raise SearchParsingError,
              "Values of \"#{field_name}\" field must be decimals."
      end
    elsif !@no_downcase.include?(field_name)
      val = val.downcase
    end

    if %w[lt gt gte lte].include? range
      { range.to_sym => val }
    else
      val
    end
  end

  # Checks any terms with colons for whether a field is specified, and
  # returns an Array: [field, value, extra-options].
  def _escape_colons
    @term.match(/^(.*?[^\\]):(.*)$/) do |m|
      field, val = m[1, 2]
      field.downcase!
      # Range query.
      if field =~ /(.*)\.([gl]te?|eq)$/
        range_field = Regexp.last_match[1].to_sym
        if @date_fields.include?(range_field) ||
           @int_fields.include?(range_field) ||
           @float_fields.include?(range_field)
          return [normalize_field_name(range_field),
                  normalize_val(range_field, val, Regexp.last_match[2])]
        end
      end

      field = field.to_sym

      if @ngram_fields.include?(field)
        @ngram_query = true
      elsif !(@date_fields.include?(field) ||
                 @int_fields.include?(field) ||
                 @float_fields.include?(field) ||
                 @literal_fields.include?(field) ||
                 @boolean_fields.include?(field) ||
                 @ip_fields.include?(field))
        @ngram_query = @ngram_fields.include?(@default_field)
        return [
          @default_field, normalize_val(@default_field, "#{field}:#{val}")
        ]
      end

      return [normalize_field_name(field), normalize_val(field, val)]
    end
  end

  def parse
    wildcardable = !/^"([^"]|\\")+"$/.match(term)
    @term = @term.slice(1, @term.size - 2) if !wildcardable

    field = nil
    field, value = _escape_colons if @term.include? ':'
    # No colon or #_escape_colons encountered an escaped colon.
    if field.nil?
      @ngram_query = @ngram_fields.include?(@default_field)
      field = @default_field
      value = normalize_val(@default_field, @term)
    end

    return @field_transforms[field].call(value) if @field_transforms[field]

    extra = {}

    # Parse boosting parameter.
    extra[:boost] = @boost.to_f if !@boost.nil?

    if value.is_a? Hash
      return { range: { field => value.merge(extra) } }
    elsif !@fuzz.nil?
      # Parse edit distance parameter.
      normalize_term! value, !wildcardable
      return { fuzzy: { field => { value: value, fuzziness: @fuzz }.merge(extra) } }
    elsif wildcardable && (value =~ /(?:^|[^\\])[\*\?]/)
      # '*' and '?' are wildcard characters in the right context;
      # don't unescape them.
      value.gsub!(/\\([^\*\?])/, '\1')
      # All-matching wildcards merit special treatment.
      @wildcarded = true
      @ngram_query = false
      return { match_all: {} } if value == '*'
      if extra.empty?
        return { wildcard: { field => value } }
      else
        return { wildcard: { field => { value: value }.merge(extra) } }
      end
    elsif @ngram_query
      if extra.empty?
        return { match_phrase: { field => value } }
      else
        return { match_phrase: {
          field => { value: value }.merge(extra)
        } }
      end
    else
      normalize_term!(value, !wildcardable) if value.is_a?(String)
      if extra.empty?
        return { term: { field => value } }
      else
        return { term: { field => { value: value }.merge(extra) } }
      end
    end
  end

  def normalize_term!(match, quoted)
    if quoted
      match.gsub!('\"', '"')
    else
      match.gsub!(/\\(.)/, '\1')
    end
  end

  def to_s
    @term
  end
end

class SearchParser
  attr_reader :search_str, :requires_query

  TOKEN_LIST = [
    [:fuzz, /^~(?:\d+(\.\d+)?|\.\d+)/],
    [:boost, /^\^[\-\+]?\d+(\.\d+)?/],
    [:quoted_lit, /^\s*"(?:(?:[^"]|\\")+)"/],
    [:lparen, /^\s*\(\s*/],
    [:rparen, /^\s*\)\s*/],
    [:and_op, /^\s*(?:\&\&|AND)\s+/],
    [:and_op, /^\s*,\s*/],
    [:or_op, /^\s*(?:\|\||OR)\s+/],
    [:not_op, /^\s*NOT(?:\s+|(?>\())/],
    [:not_op, /^\s*[\!\-]\s*/],
    [:space, /^\s+/],
    [:word, /^(?:[^\s,\(\)\^~]|\\[\s,\(\)\^~])+/],
    [:word, /^(?:[^\s,\(\)]|\\[\s,\(\)])+/]
  ].freeze

  def initialize(search_str, default_field, options = {})
    @search_str = search_str.strip
    # State variable indicating whether fuzz or boosting is used, which
    # mandates embedding the respective query AST in a query (instead
    # of a more efficient filter).
    @requires_query = false
    # Default search field.
    @default_field = default_field
    @allowed_fields = options[:allowed_fields]
    # Hash describing aliases to target ES fields.
    (@field_aliases = options[:field_aliases]) || {}
    (@field_transforms = options[:field_transforms]) || {}
    (@no_downcase = options[:no_downcase]) || []
    @parsed = _parse
  end

  attr_reader :allowed_fields

  def _bool_to_es_op(operator)
    if operator == :and_op
      :must
    else
      :should
    end
  end

  def _flatten_operands(ops, operator, negate)
    # The Boolean operator type.
    bool = _bool_to_es_op operator
    # The query AST thus far.
    query = {}
    # Build the Array of operands based on the unifying operator.
    bool_stack = []
    ops.each do |op_type, negate_term, op|
      if op_type == :term && negate_term
        # Term negation.
        op = { bool: { must_not: [op] } }
      end
      bool_exp = op[:bool]
      if !bool_exp.nil? && bool_exp.keys.size == 1 && bool_exp.key?(bool)
        bool_stack.concat bool_exp[bool]
      elsif bool_exp.nil? || !bool_exp.keys.empty?
        bool_stack.push op
      end
    end
    query[bool] = bool_stack if !bool_stack.empty?

    # Negation of the AST Hash.
    if negate
      if query.keys.size == 1 && query.key?(:must_not)
        return [:subexp, false, { bool: { must: query[:must_not] } }]
      else
        # Return point when explicit negation at the AST root is needed.
        return [:subexp, false, { bool: { must_not: [{ bool: query }] } }]
      end
    end
    [:subexp, false, { bool: query }]
  end

  def _parse
    # Stack for search terms and earlier combinations of search terms.
    operand_stack = []
    tokens.each_with_index do |token, idx|
      next if token == :not_op

      # Negation immediately follows the current token or operator.
      negate = (tokens[idx + 1] == :not_op)
      if token.is_a? SearchTerm
        parsed = token.parse
        @requires_query = true if token.wildcarded || token.fuzz || token.boost || token.ngram_query
        # Each operand is encoded as an Array containing the type
        # of operand (term or subexpressions), whether it is
        # negated, the actual term or subexpression as an ES-compliant
        # Hash, and a key map enumerating any undoable flattening,
        # which is null for terms
        operand_stack.push [:term, negate, parsed]
      else
        op_2 = operand_stack.pop
        op_1 = operand_stack.pop
        raise SearchParsingError, 'Missing operand.' if op_1.nil? || op_2.nil?

        operand_stack.push _flatten_operands([op_1, op_2], token, negate)
      end
    end

    raise SearchParsingError, 'Missing operator.' if operand_stack.size > 1

    op = operand_stack.pop

    if op.nil?
      {}
    else
      negate = op[1]
      exp = op[2]
      return { bool: { must_not: [exp] } } if negate

      return exp
    end
  end

  def parsed
    @parsed.presence || { match_none: {} }
  end

  def tokens
    @tokens ||= _lex
  end

  def new_search_term(term_str)
    SearchTerm.new(
      term_str.lstrip,
      @default_field,
      allowed_fields: @allowed_fields,
      aliases:        @field_aliases,
      transforms:     @field_transforms,
      no_downcase:    @no_downcase
    )
  end

  def _lex
    # Queue of operators.
    ops = []
    # Search term storage between match iterations, for multi-word
    # search results and special cases.
    search_term = boost = fuzz = nil
    # Count any left parentheses within the actual search term?
    lparen_in_term = 0
    # Negation of a single term.
    negate = false
    # Negation of a subexpression.
    group_negate = []
    # Stack of terms and operators shifted from queue.
    token_stack = []
    # The string containing the match and boost expressions matched thus
    # far, should the term ultimately not have a proper match/boost syntax.
    boost_fuzz_str = +''

    # Shunting-yard algorithm, to convert to a postfix-style IR.
    until @search_str.empty?
      TOKEN_LIST.each do |token|
        symbol, regexp = token
        match = regexp.match @search_str
        next unless match

        match = match.to_s

        # Add the current search term to the stack once we have reached
        # another operator.
        if ([:and_op, :or_op].include? symbol) || (
            symbol == :rparen && lparen_in_term == 0)
          if search_term
            # Set options data.
            search_term.boost = boost
            search_term.fuzz  = fuzz
            # Push to stack.
            token_stack.push search_term
            # Reset term and options data.
            search_term = fuzz = boost = nil
            boost_fuzz_str = +''
            lparen_in_term = 0
            if negate
              token_stack.push :not_op
              negate = false
            end
          end
        end

        # React to the token type that we have matched.
        case symbol
        when :and_op
          token_stack.push(ops.shift) while ops[0] == :and_op
          ops.unshift :and_op
        when :or_op
          token_stack.push(ops.shift) while [:and_op, :or_op].include?(ops[0])
          ops.unshift :or_op
        when :not_op
          if search_term
            # We're already inside a search term, so it does
            # not apply, obv.
            search_term.append match
          else
            negate = !negate
          end
        when :lparen
          if search_term
            # If we are inside the search term, do not error out
            # just yet; instead, consider it as part of the search
            # term, as a user convenience.
            search_term.append match
            lparen_in_term += 1
          else
            ops.unshift :lparen
            group_negate.push negate
            negate = false
          end
        when :rparen
          if lparen_in_term != 0
            search_term.append match
            lparen_in_term -= 1
          else
            # Shift operators until a right parenthesis is encountered.
            balanced = false
            until ops.empty?
              op = ops.shift
              if op == :lparen
                balanced = true
                break
              end
              token_stack.push op
            end
            raise SearchParsingError, 'Imbalanced parentheses.' if !balanced

            token_stack.push :not_op if group_negate.pop
          end
        when :fuzz
          if search_term
            fuzz = match[1..-1].to_f
            # For this and boost operations, we store the current match
            # so far to a temporary string in case this is actually
            # inside the term.
            boost_fuzz_str.concat match
          else
            search_term = new_search_term match
          end
        when :boost
          if search_term
            boost = match[1..-1]
            boost_fuzz_str.concat match
          else
            search_term = new_search_term match
          end
        when :quoted_lit
          if search_term
            search_term.append match
          else
            search_term = new_search_term match
          end
        when :word
          # Part of an unquoted literal.
          if search_term
            if fuzz || boost
              boost = fuzz = nil
              search_term.append boost_fuzz_str
              boost_fuzz_str = +''
            end

            search_term.append match
          else
            search_term = new_search_term match
          end
        else
          # Append extra spaces within search terms.
          search_term.append(match) if search_term
        end

        # Truncate string and restart the token tests.
        @search_str = @search_str.slice(match.size,
                                        @search_str.size - match.size)
        break
      end
    end

    # Append final tokens to the stack, starting with the search term.
    if search_term
      search_term.boost = boost
      search_term.fuzz = fuzz
      token_stack.push search_term
    end
    token_stack.push(:not_op) if negate

    raise SearchParsingError, 'Imbalanced parentheses.' if ops.any? { |x| [:rparen, :lparen].include?(x) }

    token_stack.concat ops

    token_stack
  end
end

class SearchParsingError < StandardError
end
