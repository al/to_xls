require 'rubygems'
require 'spreadsheet'
require 'stringio'

class Hash
  def to_xls(options = {})
    book = Spreadsheet::Workbook.new

    each do |key, value|
      sheet = book.create_worksheet
      sheet.name = key.to_s.gsub('_', ' ').titleize
      value.to_xls({ :sheet => sheet }.merge(options[key] || {}))
    end
    
    return book
  end
  
  def to_xls_data(options = {})
    data = StringIO.new('')
    self.to_xls(options).write(data)
    return data.string
  end
end

class Array
  # Options for to_xls: columns, name, header, sheet
  def to_xls(options = {})
    sheet = options[:sheet]
    unless sheet
      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet
      sheet.name = options[:name] || 'Sheet 1'
    end

    if self.any?
      columns = options[:columns] || self.first.attributes.keys.sort

      if columns.any?
        line = 0
        
        unless options[:headers] == false
          if options[:headers].is_a?(Array)
            sheet.row(0).concat options[:headers].collect(&:to_s)
          else
            aux_headers_to_xls(self.first, columns, sheet.row(0))
          end
          line = 1
        end
        
        self.each do |item|
          row = sheet.row(line)
          columns.each {|column| aux_to_xls(item, column, row)}
          line += 1
        end
      end
    end

    return book || sheet
  end
  
  def to_xls_data(options = {})
    data = StringIO.new('')
    self.to_xls(options).write(data)
    return data.string
  end
  
  private  
  def aux_to_xls(item, column, row)
    if item.nil?
      row.push(nil)
    elsif column.is_a?(String) or column.is_a?(Symbol)
      row.push(item.send(column))
    elsif column.is_a?(Hash)
      column.each{|key, values| aux_to_xls(item.send(key), values, row)}
    elsif column.is_a?(Array)
      column.each{|value| aux_to_xls(item, value, row)}
    end
  end
  
  def aux_headers_to_xls(item, column, row)
    if item.nil?
      row.push(nil)
    elsif column.is_a?(String) or column.is_a?(Symbol)
      row.push("#{item.class.name.underscore}_#{column}")
    elsif column.is_a?(Hash)
      column.each{|key, values| aux_headers_to_xls(item.send(key), values, row)}
    elsif column.is_a?(Array)
      column.each{|value| aux_headers_to_xls(item, value, row)}
    end
  end
  
end
