require 'csv'
require 'pry'

class InvalidHeadersError < StandardError
end

class CSVCollection < Array
  def unique!
    binding.pry
  end
end

class CSVParser
  attr_reader :file_name
  def initialize(args)
    @source_file = args[:source_file]
    args[:information].each { |k,v| instance_variable_set("@#{k}",v) if !k.nil? }
    instance_variables.each { |var| eval "def #{var.to_s.sub('@', '')}\n #{var}; end" }
  end

  def headers
    @headers ||= information.keys
  end

  def information
    #returns an hash of instance variable keys and values
    @information ||= get_information
  end

  def get_information
    hash = {}
    instance_variables.each do |var|
      hash[var.to_s.delete("@")] = self.instance_variable_get(var)
    end
    irrelevant_information.each { |key| hash.delete(key) }
    hash
  end

  def irrelevant_information
    ["file_name", "source_file"]
  end

  def save(file_name = self.source_file)
    @file_name = file_name
    add_headers if CSV.readlines(file_name).size == 0
    unless CSV.readlines(file_name)[0].sort != headers.sort
      add_information
    else
      raise InvalidHeadersError
    end
  end

  def add_headers
    CSV.open(file_name, "w") do |writer|
      writer << headers
    end
  end

  def add_information
    CSV.open(file_name, "ab", headers: information.keys) do |writer|
      writer << information.values
    end
  end

  def self.import(file_name)
    data = CSVCollection.new
    CSV.foreach(file_name, headers: true) do |row|
      data << CSVParser.new(source_file: file_name, information: row)
    end
    data
  end
end

data = CSVParser.import('test.csv')
data.map { |datum| datum.save('another.csv')}
