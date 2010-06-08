class SmartFox::User
  attr_accessor :id, :moderator, :name
  
  def parse(node)
    @id = node['i'].to_i
    @name = node.find_first('n').first.content
    
    self
  end

  def self.parse(node)
    new.parse(node)
  end
end