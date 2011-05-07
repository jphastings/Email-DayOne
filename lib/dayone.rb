require 'plist'
require 'uuid'

class DayOne
  KEYS = {
    'Creation Date' => Time,
    'Entry Text' => String,
    'Starred' => [TrueClass,FalseClass],
    'Tags' => Array
  }
    
  KEYS.each do |k|
    # TODO: ensure types are correct
    attr_accessor k[0].downcase.gsub(/\W/,'_').gsub(/_+/,'_')
  end
  attr_reader :uuid
  
  # Options can include any writable attributes. They will be set as the class is instantiated.
  def initialize(options = {})    
    options.each_pair do |k,v|
      # TODO: don't allow setting of others?
      instance_variable_set("@#{k.to_s}",v)
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
    plist['Source'] = "Day One by Mail (http://dayone.byJP.me)"
    plist.to_plist
  end
end