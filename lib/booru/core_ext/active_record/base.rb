# frozen_string_literal: true

module ActiveRecord
  class Base
    # ActiveRecord extension for INSERT INTO ... SELECT ... ON CONFLICT DO NOTHING
    # @return [ActiveRecord::Result]
    #
    def self.insert_all(*args)
      predicate = args[0]
      options   = args.extract_options!

      return super(*args) unless predicate.class < ActiveRecord::Relation

      table   = connection.quote_table_name(table_name)
      columns = options[:columns] || self.columns.reject { |c| primary_key == c.name }.map(&:name)
      columns = columns.map { |c| connection.quote_column_name(c) }

      connection.exec_insert(
        "INSERT INTO #{table} (#{columns.join(', ')}) #{predicate.to_sql} ON CONFLICT DO NOTHING",
        "#{name} Insert"
      )
    end

    # ActiveRecord extension for INSERT INTO ... ON CONFLICT DO UPDATE SET ...
    # Delegates to {#upsert_select} or {#upsert_values} based on argument type.
    #
    # @return [ActiveRecord::Result]
    #
    def self.upsert_all(*args)
      predicate = args[0]
      options   = args.extract_options!

      if predicate.class < ActiveRecord::Relation
        upsert_select(predicate, options)
      else
        upsert_values(predicate, options)
      end
    end

    # ActiveRecord extension for INSERT INTO ... SELECT ... ON CONFLICT DO UPDATE SET ...
    # @return [ActiveRecord::Result]
    #
    def self.upsert_select(predicate, options)
      table   = connection.quote_table_name(table_name)
      columns = options[:columns] || self.columns.reject { |c| primary_key == c.name }.map(&:name)
      columns = columns.map { |c| connection.quote_column_name(c) }
      updates = sanitize_sql_for_assignment(options[:set])
      uniq_by = [*options[:unique_by]].map { |c| connection.quote_column_name(c) }.join(', ')

      connection.exec_insert(
        "INSERT INTO #{table} (#{columns.join(', ')}) #{predicate.to_sql} ON CONFLICT (#{uniq_by}) DO UPDATE SET #{updates}",
        "#{name} Upsert"
      )
    end

    # ActiveRecord extension for INSERT INTO ... VALUES ... ON CONFLICT DO UPDATE SET ...
    # @return [ActiveRecord::Result]
    #
    def self.upsert_values(values, options)
      table   = connection.quote_table_name(table_name)
      columns = values[0].keys
      values  = values.map do |r|
        "(#{r.sort_by { |k, _| columns.index(k) }.map { |_, v| "'#{connection.quote_string(v.to_s)}'" }.join(', ')})"
      end.join(', ')
      columns = columns.map { |c| connection.quote_column_name(c) }
      updates = sanitize_sql_for_assignment(options[:set])
      uniq_by = [*options[:unique_by]].map { |c| connection.quote_column_name(c) }.join(', ')

      connection.exec_insert(
        "INSERT INTO #{table} (#{columns.join(', ')}) VALUES #{values} ON CONFLICT (#{uniq_by}) DO UPDATE SET #{updates}",
        "#{name} Upsert"
      )
    end
  end
end
