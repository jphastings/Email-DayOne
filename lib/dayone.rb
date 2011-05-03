require 'plist'
require 'uuid'

class DayOne
  KEYS = {
    'Creation Date' => Time,
    'Entry Text' => String,
    'Starred' => [TrueClass,FalseClass]
  }
  
  KEYS.each do |k|
    # TODO: ensure types are correct
    attr_accessor k[0].downcase.gsub(/\W/,'_').gsub(/_+/,'_')
  end
  attr_reader :uuid
  
  # Options can include any writable attributes. They will be set as the class is instantiated.
  def initialize(options = {})
    options.each_pair do |key,value|
      
    end
    @uuid = UUID.new.generate.gsub('-','').upcase
  end
  
  # TODO:
  def self.open(filename)
    
  end
  
  def to_plist
    plist = KEYS.dup
    plist.each_pair do |k,allowed|
      internal = k.downcase.gsub(/\W/,'_').gsub(/_+/,'_')
      val = self.send(internal.to_sym)
      raise(ArgumentError,"#{internal} is a #{val.class}. It must be of type #{[*allowed].join(', ')}") unless [*allowed].include? val.class
      plist[k] = val
    end
    plist['UUID'] = @uuid
    plist.to_plist
  end
end

d = DayOne.new

d.creation_date = Time.now
d.entry_text = "Hi there!"
d.starred = false

p d.to_plist