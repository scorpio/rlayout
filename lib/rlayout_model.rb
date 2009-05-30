=begin Rlayout
author: Leon Li(scorpio_leon@hotmail.com)
=end
require 'rlayout/model'

ActionController::Base.class_eval do
  #for page layout
  include Rlayout::Model
end