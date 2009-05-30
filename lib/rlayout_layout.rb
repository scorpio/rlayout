=begin Rlayout
author: Leon Li(scorpio_leon@hotmail.com)
=end
require 'rlayout/layout'

if RAILS_GEM_VERSION >= '2.2'
  ActionView::Base.class_eval do
    #for rails 2.2
    include Rlayout::Layout
  end
else
  ActionController::Base.class_eval do
    #for rails 2.1
    include Rlayout::Layout
  end
end
