=begin Rlayout
author: Leon Li(scorpio_leon@hotmail.com)
=end
require 'action_view'

ActionView::Base.class_eval do
  
  #for using controller method in view
  def method_missing(method_id, *args)
    ActionView::Base.class_eval %{
                      def #{method_id}(*args)
                        @controller.#{method_id}(*args)
                      end
                    }
    send(method_id, *args)
  end
end


