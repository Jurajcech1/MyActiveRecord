require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map { |col| "#{col} = ?" }.join(" AND ")
    value = params.values
    search = DBConnection.execute(<<-SQL, value)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL

    if search.nil?
      return []
    else
      search.map { |thing| self.new(thing) }
    end

  end
end

class SQLObject
  extend Searchable
end
