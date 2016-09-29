# Use this file to import the sales information into the
# the database.
require "pg"
require "csv"
require "pry"

def db_connection
  begin
    connection = PG.connect(dbname: "korning")
    yield(connection)
  ensure
    connection.close
  end
end

class DbObject
  attr_reader :table_name
  def primary_key_value
    send(self.primary_key)
  end

  def sanitized_primary_key_value
    "\'" + primary_key_value + "\'"
  end

  def columns
    information.keys
  end

  def sanitized_columns
    sanitized_columns = columns
    sanitized_columns.delete("table_name")
    sanitized_columns.join(', ')
  end

  def values
    information.values
  end

  def sanitized_values
    relevant_values = values
    relevant_values.delete(table_name)
    relevant_values = relevant_values.map do |value|
      "\'" + value.to_s + "\'"
    end
    relevant_values.join(', ')
  end

  def information
    #returns an hash of instance variable keys and values
    get_information
  end

  def get_information
    hash = {}
    instance_variables.each do |var|
      hash[var.to_s.delete("@")] = self.instance_variable_get(var)
    end
    hash
  end

  def save_to_database
    begin
      db_connection do |conn|
        conn.exec("INSERT INTO #{table_name} (#{sanitized_columns}) VALUES (#{sanitized_values})")
      end
    rescue PG::UniqueViolation
    end
  end

  def update_id
    db_connection do |conn|
      self.id = conn.exec("SELECT id FROM #{table_name} WHERE #{primary_key.to_s} = #{sanitized_primary_key_value}").values.first.first.to_i
    end
  end

  def save
    instance_variables.each do |variable|
      begin
        if self.send(variable.to_s.delete("@")).save
          instance_variable_set("@#{self.send(variable.to_s.delete("@")).class.to_s.downcase}_id", self.send(variable.to_s.delete("@")).id)
          remove_instance_variable("@#{self.send(variable.to_s.delete("@")).class.to_s.downcase}")
        end
      rescue
      end
    end
    save_to_database
    update_id
  end
end

class Sale < DbObject
  attr_reader :revenue, :date_sold, :units_sold
  attr_accessor :employee, :product, :customer, :invoice, :id
  def initialize(data)
    @table_name = "sales"
    @revenue = data["sale_amount"]
    @date_sold = data["sale_date"]
    @units_sold = data["units_sold"]
    @employee = data["employee"]
    @product = data["product"]
    @customer = data["customer_and_account_no"]
    @invoice = data["invoice_no"]
  end

  def primary_key
    :revenue
  end
end

class Employee < DbObject
  attr_reader :name, :email
  attr_accessor :id
  def initialize(data)
    @table_name = "employees"
    parse_data(data)
  end

  def parse_data(data)
    data = data.split(' (')
    @name = data[0]
    @email = data[1].gsub(/[()]/, "")
  end

  def primary_key
    :email
  end
end

class Product < DbObject
  attr_reader :name
  attr_accessor :id
  def initialize(data)
    @table_name = "products"
    @name = data
  end

  def primary_key
    :name
  end
end

class Customer < DbObject
  attr_reader :name, :account_number
  attr_accessor :id
  def initialize(data)
    @table_name = "customers"
    parse_data(data)
  end

  def parse_data(data)
    data = data.split(' ')
    @name = data[0]
    @account_number = data[1].gsub(/[()]/, "")
  end

  def primary_key
    :account_number
  end
end

class Invoice < DbObject
  attr_reader :invoice_number
  attr_accessor :id
  def initialize(data)
    @table_name = "invoices"
    @invoice_number = data[:invoice_no]
  end

  def primary_key
    :invoice_number
  end
end

class Frequency < DbObject
  attr_reader :frequency
  attr_accessor :id
  def initialize(data)
    @table_name = "frequencies"
    @frequency = data[:frequency]
  end

  def primary_key
    :frequency
  end
end

sales, employees, products, customers, invoices = [], [], [], [], []
file_name = 'sales.csv'
CSV.foreach(file_name, headers: true) do |row|
  row["employee"] = Employee.new(row["employee"])
  row["product"] = Product.new(row["product_name"])
  row["customer_and_account_no"] = Customer.new(row["customer_and_account_no"])
  row["invoice_no"] = Invoice.new(invoice_no: row["invoice_no"])
  row["invoice_frequency"] = Frequency.new(frequency: row["invoice_frequency"])
  sales << Sale.new(row)
end

sales.each(&:save)

db_connection do |conn|
  puts conn.exec("select * from employees")
end

binding.pry
