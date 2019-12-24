# frozen_string_literal: true

module PostgresSet
  class << self
    def add_to_set(relation, column, value)
      sql = Tag.send :sanitize_sql, ["#{column} = ARRAY(SELECT DISTINCT unnest(array_append(#{column}, :val)) ORDER BY 1)", val: value]
      relation.in_batches.update_all(sql)
    end

    def replace(relation, column, old_value, new_value)
      sql = Tag.send :sanitize_sql, ["#{column} = ARRAY(SELECT DISTINCT unnest(array_replace(#{column}, :old, :new)) ORDER BY 1)", old: old_value, new: new_value]
      relation.in_batches.update_all(sql)
    end

    def pull(relation, column, value)
      sql = Tag.send :sanitize_sql, ["#{column} = array_remove(#{column}, :val)", val: value]
      relation.in_batches.update_all(sql)
    end
  end
end
