# frozen_string_literal: true

class SearchEvaluator
  def initialize(query)
    @query = query
  end

  def hits?(doc, query = @query)
    if query.key?(:bool)
      [*query[:bool][:must]].all? { |x| hits?(doc, x) } &&
        [*query[:bool][:filter]].all? { |x| hits?(doc, x) } &&
        [*query[:bool][:should]].any? { |x| hits?(doc, x) } &&
        [*query[:bool][:must_not]].none? { |x| hits?(doc, x) }
    elsif query.key?(:range)
      term = query[:range].keys[0]
      doc_vals = ary(doc[term])
      range = query[:range][term]
      range.all? do |k, v|
        case k
        when :gt
          doc_vals.any? { |x| x > v }
        when :gte
          doc_vals.any? { |x| x >= v }
        when :lt
          doc_vals.any? { |x| x < v }
        when :lte
          doc_vals.any? { |x| x <= v }
        end
      end
    elsif query.key?(:fuzzy)
      term = query[:fuzzy].keys[0]
      fuzzy = query[:fuzzy][term]
      value = fuzzy[:value]
      min_similarity = fuzzy[:min_similarity]

      ary(doc[term]).any? do |x|
        if min_similarity >= 1
          levenshtein_distance(x, value) <= min_similarity
        elsif min_similarity >= 0
          levenshtein_distance(x, value) <= ((1 - min_similarity) * value.length).floor
        end
      end
    elsif query.key?(:wildcard)
      term = query[:wildcard].keys[0]
      wildcard = query[:wildcard][term]
      value = wildcard.is_a?(Hash) ? wildcard[:value] : wildcard
      value = "\\A#{wildcard_to_regex(value)}\\z"
      value = Regexp.new(value, Regexp::IGNORECASE | Regexp::MULTILINE)

      ary(doc[term]).any? { |x| value.match?(x) }
    elsif query.key?(:match_phrase)
      # This is not accurate at all because it doesn't stem values, but
      # I'm not wont to include a stemmer and dictionary just for this.
      term = query[:match_phrase].keys[0]
      phrase = query[:match_phrase][term]
      value = phrase.is_a?(Hash) ? phrase[:value] : phrase
      value = Regexp.quote(value)
      value = Regexp.new(value, Regexp::IGNORECASE | Regexp::MULTILINE)

      ary(doc[term]).any? { |x| value.match?(x) }
    elsif query.key?(:term)
      term = query[:term].keys[0]
      inner = query[:term][term]
      value = inner.is_a?(Hash) ? inner[:value] : inner
      ary(doc[term]).include?(value)
    elsif query.key?(:match_all)
      true
    end
  rescue StandardError
    false
  end

  # ActiveSupport is not very helpful.
  #   [*Image.first[:first_seen_at]]
  #   # => [59, 10, 3, 2, 1, 2012, 1, 2, false, "UTC"]
  def ary(values)
    values.is_a?(Array) ? values : [values]
  end

  def levenshtein_distance(s, t)
    m = s.length
    n = t.length
    x = [m, n].max
    return m if n == 0
    return n if m == 0
    return x if x > 75 && n != m

    d = Array.new(m + 1) { Array.new(n + 1) }

    (0..m).each { |i| d[i][0] = i }
    (0..n).each { |j| d[0][j] = j }
    (1..n).each do |j|
      (1..m).each do |i|
        d[i][j] = if s[i - 1] == t[j - 1] # adjust index into string
          d[i - 1][j - 1]                 # no operation required
        else
          [
            d[i - 1][j] + 1,              # deletion
            d[i][j - 1] + 1,              # insertion
            d[i - 1][j - 1] + 1 # substitution
          ].min
        end
      end
    end

    d[m][n]
  end

  def wildcard_to_regex(string)
    string.gsub(/([.+^$\[\]\\\(\){}|-])/, '\\\\\1')
          .gsub(/([^\\]|[^\\](?:\\\\)+)\*/, '\1.*')
          .gsub(/\A(?:\\\\)*\*/, '.*')
          .gsub(/([^\\]|[^\\](?:\\\\)+)\?/, '\1.?')
          .gsub(/\A(?:\\\\)*\?/, '.?')
  end
end
