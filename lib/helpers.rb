class NoSuchUserError < ArgumentError; end
class NoSuchEmailError < ArgumentError; end
class MismatchUserError < ArgumentError; end
class NoJournalFoundError < ArgumentError; end

def scan_for_journal(dir = '/',depth = nil,final = true)
  js = @dropbox.list(dir).select { |f| f.path.match(/\.dayone$/) }
  
  return js[0].path unless js.count == 0
  
  unless depth == 0
    @dropbox.list(dir).select {|f| f.directory? }.each do |d|
      j = scan_for_journal(d.path,depth.nil? ? nil : depth - 1,false)
      return j unless j.nil?
    end
  end
  
  raise NoJournalFoundError if final
  nil
end