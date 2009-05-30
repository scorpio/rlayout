=begin Rlayout
author: Leon Li(scorpio_leon@hotmail.com)
=end
require 'rlayout/template'
require 'action_view'


ActionController::Base.class_eval do
  include Rlayout::Template
  #for field temlate
  alias_method :process_cleanup_old4template, :process_cleanup  unless method_defined?(:process_cleanup_old4template)
  def process_cleanup
    process_cleanup_old4template
    Thread.current[:rlayout] = nil    
  end
  def form_theme
    self.class.get_form_theme
  end
end


ActionView::Base.class_eval do
  
  #for field temlate
  alias_method :initialize_old4template, :initialize unless method_defined?(:initialize_old4template)
  def initialize(*args)
    initialize_old4template(*args)
    Thread.current[:rlayout] = {}
    Thread.current[:rlayout][:view_context] = self
    Thread.current[:rlayout][:view_binding] = binding
  end
  
end


