# frozen_string_literal: true

xml.instruct!
xml.oembed do
  @data.each_pair do |k, v|
    xml.tag!(k.to_sym, v)
  end
end
