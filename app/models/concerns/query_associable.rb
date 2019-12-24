# frozen_string_literal: true

module QueryAssociable
  extend ActiveSupport::Concern

  class_methods do
    def normalize_user_query_program(str)
      # " \nsome stuff \n\r thing" -> "(some stuff) || (thing)"
      if str
        str.delete("\r")
           .split("\n")
           .reject { |x| x.strip.empty? }
           .map { |x| "(#{x})" }
           .join(' || ')
      else
        ''
      end
    end

    def parse_user_query_program(str, target_model, options = {})
      return {} if str.blank?

      test_user_query_program(str, target_model, options).parsed
    end

    def test_user_query_program(str, target_model, options = {})
      target_model.get_search_parser(normalize_user_query_program(str), options)
    end
  end
end
