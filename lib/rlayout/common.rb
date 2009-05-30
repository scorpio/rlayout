=begin Rlayout
author: Leon Li(scorpio_leon@hotmail.com)
=end
class Object
  def class_simple_name
    if self.is_a?(Class)
      fullname = self.to_s
    else
      fullname = self.class.to_s
    end
    fullname.scan(/(.*::)*([^\(]*)/)[0][1]
  end
end