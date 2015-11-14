require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns

    return @columns if @columns
      @columns = DBConnection.execute2(<<-SQL).first
        SELECT
          *
        FROM
          #{self.table_name}
        SQL
      @columns.map!{ |column| column.to_sym }
  end

  def self.finalize!
    self.columns.each do |column|

      define_method "#{column}" do
        attributes[column]
      end

      define_method "#{column}="  do |value|
        attributes[column] = value
      end
    end

    define_method "attributes" do
      @attributes ||= {}
    end

  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    if @table_name.nil?
      self.to_s.tableize
    else
      @table_name
    end
  end

  def self.all
    @all_rows = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL
    self.parse_all(@all_rows)
  end

  def self.parse_all(results)
    result_array = []
    results.each do |result|
      result_array << self.new(result)
    end
    result_array
  end

  def self.find(id)
    item = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
    SQL
    return nil if item.empty?
    self.new(item.first)
  end

  def initialize(params = {})
    params.each do |k, v|
      k_sym = k.to_sym
      unless self.class.columns.include?(k_sym)
        fail "unknown attribute '#{k}'"
      end
      self.send "#{k}=", v
    end

  end

  def attributes
    # ...
  end

  def attribute_values
    self.class.columns.map { |column| self.send "#{column}" }
  end

  def insert
    cols = self.class.columns
    col_names = cols.map { |col| col.to_s }.join(",")
    question_marks = (["?"] * cols.length).join(",")
    DBConnection.execute(<<-SQL, attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id=(DBConnection.last_insert_row_id)
  end

  def update
    set_cols = self.class.columns.map { |col| "#{col} = ?" }.join(",")
    DBConnection.execute(<<-SQL, attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_cols}
      WHERE
        id = ?
    SQL
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end
end
