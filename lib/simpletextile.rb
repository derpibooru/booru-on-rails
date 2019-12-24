require 'camo'

class SimpleTextile
  # Ruby \s does not match extra unicode space characters
  RX_SPACE_CHARS = '\n \t\u00a0\u1680\u180E\u2000-\u200A\u202F\u205F\u3000'
  RX_SPACE = /[#{RX_SPACE_CHARS}]/
  RX_SPACE_BEGIN = /\A[#{RX_SPACE_CHARS}]+/
  RX_SPACE_END = /[#{RX_SPACE_CHARS}]+\z/

  # Used when markup surrounds a single word
  RX_QUICKTXT = /[0-9a-z*+@_{}]+/i
  RX_NOT_QUICKTXT = /[^0-9a-z*+@_{}]/i

  # Characters which are valid before the main markup characters
  RX_SPECIAL_BEFORE = /[#{RX_SPACE_CHARS}!"#$\%&(),\-.\/:;<=?\[\\\]^`|~\'\"]/

  # Matches the source URL of an image
  RX_IMG = /\A>?([^#{RX_SPACE_CHARS}"?][^#{RX_SPACE_CHARS}"]*)\z/

  # Extracts the title attribute from an image or link, i.e. !http://example.com/img.png(Image.)!
  RX_TITLE = /\A([^\(]+)\(([^\)]*)\)\z/

  # Link validation RX.
  RX_URL_OK = /^(http:\/\/|https:\/\/|\/|#)/

  # Image validation RX. Images may use the data: URI, but
  # cannot contain only a fragment.
  RX_IMGURL_OK = /^(http:\/\/|https:\/\/|\/|data:image\/)/

  RX_URL = /\G(?:[^%#{RX_SPACE_CHARS}"]|%[0-9a-fA-F]{2})+/
  RX_URL_INVALID_AT_END = /[`~!@$^&\*_+\-=\[\]\\|;:,.'?#)]/

  # Acronym match.
  RX_ABBREV = /([A-Z]{2,})\(([^\r\n<>\)]+)\)/

  # Spoiler Match.
  RX_SPOILER = /\[spoiler\][#{RX_SPACE_CHARS}]*(.*?)[#{RX_SPACE_CHARS}]*\[\/spoiler\]/sm

  # Quote + Citation Match.
  RX_QUOTE_WITH_CITE = /\[bq="([^"]*)"\][#{RX_SPACE_CHARS}]*(.*?)[#{RX_SPACE_CHARS}]*\[\/bq\]/sm

  # Quote Match.
  RX_QUOTE = /\[bq\][#{RX_SPACE_CHARS}]*(.*?)[#{RX_SPACE_CHARS}]*\[\/bq\]/sm

  HANDLERS = []

  attr_accessor :last_markup_end

  def initialize(opt={})
    @custom_match = []
    @last_markup_end = 0
  end

  # Install the default replacement entities.
  def default_match
    @custom_match << proc do |t|
      t.gsub! /-&gt;/, '&#8594;'
      t.gsub! /--/, '&#8212;'
      t.gsub! /\.\.\./, '&#8230;'
      t.gsub! /(#{RX_SPACE})-(#{RX_SPACE})/o, '\1&#8211;\2'
      t.gsub! /\(tm\)/i, '&#8482;'
      t.gsub! /\(r\)/i, '&#174;'
      t.gsub! /\(c\)/i, '&#169;'
      t.gsub! /\'/, '&#8217;'
      t.gsub!(RX_ABBREV) { "<acronym title=\"#{markup(html_escape_attr($2), 'm')}\">#{$1}</acronym>" }
      t.gsub! /&amp;(#[0-9]+|[a-z]+);/i, '&\\1;'
      spoilerify! t
      quotify! t
    end
    self
  end

  # Install a filter which will be run over each
  # string of plain text before it is placed in
  # the output. The text will have been html-escaped.
  def match(rx, repl=nil, &block)
    if repl
      @custom_match << proc {|t| t.gsub! rx, repl}
    else
      @custom_match << proc {|t| t.gsub! rx, &block}
    end
    self
  end

  # Parse a block of textile into HTML.
  def parse(text)
    text = text.gsub(/[\r&<>]/, "\r" => '', '&' => '&amp;', '<' => '&lt;', '>' => '&gt;')

    @markup = []

    # Pull out "bracketed" literals. Save them in a separate array.
    if text.index('[==')
      text.gsub!(/\[==((?:.|\n)*?)==\]/){|m| markup(m[3..-4], 'm') }
    end

    @phase = 0
    out = []
    textile_parse_partial text, out = []
    text = out.join ''

    @custom_match.each {|p| p.call(text)}

    @phase = 1
    out = []
    textile_parse_partial text, out = []
    text = out.join ''

    if not @markup.empty?
      text = unmarkup(text)
    end

    text.gsub! /\ *\n/, "<br>\n"

    return text
  end

  # Tests if the string contains balanced markup.
  def self.balanced_markup(t)
    openpos = closepos = -1
    while closepos
      openpos = t.index('<', openpos + 1)
      closepos = t.index('>', closepos + 1)
      if closepos && (!openpos || openpos >= closepos)
        return false
      end
    end
    return !openpos
  end

  def self.parse(text)
    return SimpleTextile.new.default_match.parse(text)
  end

  class Handler
    def run(parser, t, idx, m, out, bracketed) end

    def bracketable?() false end
    def phase() 1 end
    def char() '' end

    # Tests if the character of t at idx can be considered "special".
    # This is true only if the preceding character matches RX_SPECIAL_BEFORE
    # and the following character is not a space.
    def begin_special?(parser, t, idx, l=1)
      (idx <= parser.last_markup_end || (@rxbefore || RX_SPECIAL_BEFORE).match(t[idx-1, 1]))
    end

    ## Try to detect an absolute URL that's missing a scheme.
    def add_scheme(url)
      url =~ /^[a-z0-9-]+\.[-a-z0-9.]+\//i ? 'http://' + url : url
    end

    ## Find a url for an image or text link.
    ## Remove unbalanced parentheses from the end. This allows Wikipedia links
    ## to work properly: ("Yes":http://en.wikipedia.org/Yes_(Band))
    def match_url(t, startpos, bracketed)
      return unless (linkm = RX_URL.match(t, startpos))
      url = linkm[0]
      endpos = linkm.end(0)
      if bracketed then
        return unless (bpos = t.index(']', startpos)) && bpos <= endpos
        if bpos < endpos then
          url = url[0, url.length + bpos - endpos]
          endpos = bpos
        end
      else
        while !url.empty?
          e = url[-1]
          break if (e == ')' && (ocnt ||= url.count('(')) == url.count(')')) || e !~ RX_URL_INVALID_AT_END
          url.chop!
          endpos -= 1
        end
      end
      return add_scheme(url), endpos
    end
  end

  ## Special marker for the closing </a> in a link which remembers the
  ## index of the URL in the original text
  class LinkEnd < String
    attr_accessor :pos
    def initialize(pos)
      super("</a>")
      @pos = pos
    end
  end

  class AttrHandler < Handler
    def initialize(chr, opt)
      @char = chr

      @rxforbid = opt[:rxforbid]
      @attr = opt[:attr]
      @dblattr = opt[:dblattr]
      @bracketable = opt[:bracketable]
      @rxbefore = opt[:rxbefore]
      @literal = opt[:literal]

      if @bracketable
        @rxbracket = Regexp.new "#{Regexp.escape chr}\\]"
        if @dblattr
          @rxdblbracket = Regexp.new "#{Regexp.escape(chr+chr)}\\]"
        end
      end

      @rxsamechr = opt[:rxsamechr] || Regexp.new("\\G#{Regexp.escape chr}{#{@dblattr?3:2},}")
      # @rxsamechr = opt[:rxsamechr] || Regexp.new("\\G#{Regexp.escape chr}{#{@dbl?3:2},}")
    end

    def bracketable?
      @bracketable
    end

    def char
      @char
    end

    def ends(&block)
      @endb = block
      self
    end

    def quicktxt(parser, m)
      if m.length > 2 and m.end_with? @char
        attr = @attr
        r = 1..-2
        if @dblattr and m[1] == @char
          if m[-2] == @char
            if m.length < 5
              attr = nil
            else
              r = 2..-3
              attr = @dblattr
            end
          elsif m[2] != @char
            return @char + quicktxt(parser, m[1..-1])
          end
        end
      end
      if attr
        mm = m[r]
        h = @literal ? nil : HANDLERS[phase][mm[0]]
        return "<#{attr}>#{h ? h.quicktxt(parser, mm) : mm}</#{attr}>"
      end
      return m
    end

    def run(parser, t, idx, m, out, bracketed, skip_before_test=false)
      if not bracketed and not skip_before_test
        if (ma = @rxsamechr.match(t, idx))
          out << ma[0]
          return ma.end(0)
        end
        return unless begin_special?(parser, t, idx)
      end

      isdbl = @dblattr && t[idx + 1] == @char
      if !bracketed &&
          (qt = RX_QUICKTXT.match(t, idx)) &&
          (mt = qt[0]).index(@char, @dblattr ? 2 : 1)
        out << quicktxt(parser, mt)
        return idx + mt.length
      end
      attr = isdbl ? @dblattr : @attr
      return unless attr

      cchar = isdbl ? @char*2 : @char
      idx += isdbl ? 2 : 1

      return if RX_SPACE.match(t[idx]) && !(bracketed && @literal)

      epos = idx
      while true
        if bracketed
          rxbracket = isdbl ? @rxdblbracket : @rxbracket
          endm = rxbracket.match(t, epos + 1)
          return if not endm
          epos = endm.begin(0)
        else
          while true
            epos = t.index(cchar, epos + 1)
            unless epos
              # fallback to trying with a single char: **a a* -> *<strong>a a</strong>
              if isdbl and t[idx] != @char
                outp = out.length
                out << ""
                if (r = run(parser, t, idx - 1, m, out, false, true))
                  out[outp] = @char
                  return r
                else
                  out.pop
                end
              end
              return
            end
            next if RX_SPACE.match(t[epos - 1])
            if @endb
              break if @endb.call(t, epos)
            else
              data = t[idx, epos - idx]
              break
            end
          end
        end

        data = t[idx, epos - idx]
        return if data.empty? || (!(@literal && bracketed) && data =~ /\n\n/)
        next unless SimpleTextile.balanced_markup(data)

        spos = out.length
        if @literal then
          out << parser.markup("<#{attr}>#{parser.unmarkup(data)}</#{attr}>", 'm')
        else
          out << parser.markup("<#{attr}>", '<')
          if @rxforbid
            parser.textile_parse_partial(data, out) do |ptxt|
              if ptxt =~ @rxforbid
                out.slice! spos..out.length
                return
              end
            end
          else
            parser.textile_parse_partial(data, out)
          end
          out << parser.markup("</#{attr}>", '>')
        end

        return epos + cchar.length
      end
    end
  end

  class QuotHandler < Handler
    def char() '"' end
    def bracketable?() true end
    def phase() 0 end

    def quicktxt(parser, m)
      return m
    end

    def run(parser, t, idx, m, out, bracketed)
      return unless (epos = t.index('":', idx + 1))
      return unless t[idx + 1] !~ RX_SPACE && t[epos - 1] !~ RX_SPACE

      url, endpos = match_url(t, epos + 2, bracketed)
      return unless url && url =~ RX_URL_OK

      data = t[idx + 1, epos - idx - 1]

      if (m = RX_TITLE.match(data))
        data = m[1].gsub(RX_SPACE_END, '')
        title = m[2]
      else
        title = nil
      end

      return if data.empty?

      start = out.length
      ltxt = "<a href=\"#{parser.html_escape_attr(url)}\""
      ltxt.concat " title=\"#{parser.html_escape_attr(title)}\"" if title
      ltxt.concat ">"
      out << parser.markup(ltxt, '<')
      sub_literals = []
      parser.textile_parse_partial(data, out) do |m| sub_literals << m end

      # Allow unescaped quotes at the beginning and end
      t = sub_literals.join ' '
      unless (m = /\A("*)[^"]+("*)\z/.match(t)) && m[1].length == m[2].length
        out.slice! start..out.length
        return
      end
      out << parser.markup("</a>", '>')
      return endpos
    end
  end

  class BracketHandler < Handler
    def initialize(phase) @phase = phase end
    def char() '[' end
    def phase() @phase end

    def run(parser, t, idx, m, out, bracketed)
      return unless (h = HANDLERS[@phase][t[idx + 1]])
      if h.bracketable?
        start = out.length
        nidx = h.run(parser, t, idx + 1, '', out, true)
        return if not nidx
        if t[nidx] != ']'
          out.slice! start..out.length
          return
        end
        return nidx + 1
      end
    end
  end

  class LiteralHandler < Handler
    def char() '=' end
    def bracketable?() true end
    def phase() 0 end

    def run(parser, t, idx, m, out, bracketed)
      return if t[idx + 1] != '=' or RX_SPACE.match(t[idx + 2] || ' ')
      idx += 2
      epos = t.index('==', idx)
      return unless epos
      return if epos == idx || t[idx] =~ RX_SPACE || t[epos - 1] =~ RX_SPACE
      data = t[idx, epos - idx]
      return if data =~ /\n\n/

      out << parser.markup(parser.unmarkup(data), 'm')
      return epos + 2
    end
  end

  class ImageHandler < Handler
    def char() '!' end
    def bracketable?() true end
    def phase() 0 end

    def run(parser, t, idx, m, out, bracketed)
      epos = t.index('!', idx + 1)
      return unless epos
      url = t[idx + 1, epos - idx - 1]

      link = nil
      if t[epos + 1] == ':'
        link, endpos = match_url(t, epos + 2, bracketed)
        if link && link =~ RX_URL_OK
          epos = endpos - 1
        else
          link = nil
        end
      end

      if (m = RX_TITLE.match(url))
        url = m[1]
        title = m[2]
      else
        title = nil
      end

      url = add_scheme(url)
      url = "https:#{url}" if url[0..1] == '//'

      return unless RX_IMG.match(url)
      return unless url =~ RX_IMGURL_OK

      return if bracketed && t[epos + 1] != ']'
      return if title && (title =~ RX_SPACE_BEGIN || title =~ RX_SPACE_END)

      # Combat overly eager escaping of HTML entities.
      image_url = url.gsub(/&(amp|lt|gt);/, '&amp;' => '&', '&lt;' => '<', '&gt;' => '>')
      proxied_uri = Camo.image_url(image_url)

      otxt = link ? "<a href=\"#{parser.html_escape_attr(link)}\">" : ""
      otxt.concat "<span class=\"imgspoiler\"><img src=\"#{proxied_uri.to_s}\""
      if title
        title = parser.html_escape_attr(title)
        otxt.concat " title=\"#{title}\" alt=\"#{title}\""
      end
      otxt.concat '></span>'
      otxt.concat '</a>' if link
      out << parser.markup(otxt, 'm')
      return epos + 1
    end
  end

  def self.add_handler(h)
    (HANDLERS[h.phase] ||= {})[h.char] = h
  end

  add_handler QuotHandler.new
  add_handler BracketHandler.new 0
  add_handler BracketHandler.new 1
  add_handler ImageHandler.new
  add_handler LiteralHandler.new
  add_handler AttrHandler.new '*', attr: 'strong', dblattr: "b", bracketable: true, rxbefore: RX_NOT_QUICKTXT
  add_handler AttrHandler.new '_', attr: 'em', dblattr: "i", bracketable: true, rxbefore: RX_NOT_QUICKTXT, rxforbid: /_/
  add_handler AttrHandler.new '@', attr: 'code', bracketable: true, literal: true, rxbefore: RX_NOT_QUICKTXT
  add_handler AttrHandler.new '+', attr: 'ins', bracketable: true, rxbefore: RX_NOT_QUICKTXT
  [['^', 'sup'], ['-', 'del'], ['~', 'sub']].each do |a|
    add_handler AttrHandler.new(a[0], attr: a[1], bracketable: true,
                                rxbefore: /[#{RX_SPACE_CHARS}"]/).ends {|t, idx| (t[idx + 1]||' ') !~ /[*+>@a-z0-9_{}]/i}
  end
  add_handler AttrHandler.new '?', dblattr: 'cite', bracketable: true, rxbefore: /./

  RX_SPECIAL = HANDLERS.map{|h| Regexp.new "[#{Regexp.escape h.keys.join ''}]"}

  def markup(text, ec)
    @markup << text
    "\r#{@markup.length - 1}#{ec}"
  end

  def unmarkup(text)
    text.gsub(/\r(\d+)[<>m]/){|m| @markup[m[1..-2].to_i]}
  end

  def html_escape_attr(text)
    # [<>&] are already escaped.
    unmarkup(text).gsub(/["'\n]/, '"' => '&quot;', "'" => '&#39;', "\n" => '')
  end

  def quotify!(t)
    # Put [bq][/bq] blocks into <blockquote>s. Local var x indicates when all
    # embedded <block
    x = true
    while x
      x = t.gsub!(RX_QUOTE_WITH_CITE) do
        if SimpleTextile.balanced_markup $2
          "<blockquote title=\"#{html_escape_attr($1)}\">#{$2}</blockquote>"
        else
          "&#91;bq=\"#{html_escape_attr($1)}\"&#93;#{$2}&#91;/bq&#93;"
        end
      end
    end
    x = true
    while x
      x = t.gsub!(RX_QUOTE) do
        if SimpleTextile.balanced_markup $1
          "<blockquote>#{$1}</blockquote>"
        else
          "&#91;bq&#93;#{$1}&#91;/bq&#93;"
        end
      end
    end
    t
  end

  def spoilerify!(t)
    # Put [spoiler][/spoiler] blocks into spoiler spans. Local var x indicates when all
    # embedded <span (?????)
    x = true
    while x
      x = t.gsub!(RX_SPOILER) do
        if SimpleTextile.balanced_markup $1
          "<span class=\"spoiler\">#{$1}</span>"
        else
          "&#91;spoiler&#93;#{$1}&#91;/spoiler&#93;"
        end
      end
    end
    t
  end

  def textile_parse_partial(t, out)
    @last_markup_end = 0
    @level = (@level || 0) + 1

    rx_special = RX_SPECIAL[@phase]
    handlers = HANDLERS[@phase]

    idx = srchidx = 0
    outp = out.length
    out << ""
    while true
      m = rx_special.match(t, srchidx)
      special_idx = m ? m.begin(0) : t.length

      if !m ||
          ((handler = handlers[m[0]]) &&
           (newidx = handler.run(self, t, special_idx, m[0], out, false)))
        ptxt = t[idx, special_idx - idx]
        if block_given?
          yield ptxt
        end
        out[outp] = ptxt
        break unless m
        outp = out.length
        out << ""

        idx = srchidx = newidx
        @last_markup_end = idx
      else
        srchidx = special_idx + m[0].length
      end
    end

    @level -= 1
  end
end
