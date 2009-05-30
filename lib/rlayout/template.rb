=begin Rlayout
author: Leon Li(scorpio_leon@hotmail.com)
=end
#for field template

module Rlayout::Template
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    def form_theme(theme)
      write_inheritable_attribute "form_theme", theme
    end
    
    def get_form_theme
      read_inheritable_attribute("form_theme")                 
    end
  end
end

require 'action_view/helpers/form_helper'
module ActionView::Helpers::FormHelper
  def field_context
    @field_context
  end
  def field_context=(context)
    @field_context = context
  end
end

class Rlayout::TemplateUtil
  WITH_TEMPLATE = '_without_template'
  class << self
    def get_template(key, type=nil)
      type = 'common' if type.nil?
      template_key = key+'_'+type
      @tag_templates ||= {}
      if @tag_templates[template_key].nil? || RAILS_ENV != 'production'
        template_file = File.join(RAILS_ROOT, 'templates', key, "#{type}.html.erb")
        template_file = File.join(RAILS_ROOT, 'templates', key, "common.html.erb") unless File.exists?(template_file)
        @tag_templates[template_key] = File.read(template_file)
      end
      @tag_templates[template_key]
    end
    
    def round_tag(tag_name, context, str, *args)
      view_context = Thread.current[:rlayout][:view_context]
      key = (context[:options] && context[:options].delete('theme')) || view_context.controller.form_theme
      unless key.nil?
        context[:body] = str
        view_context.field_context=context
        str = ERB.new(get_template(key, tag_name)).result(Thread.current[:rlayout][:view_binding])
        view_context.field_context=nil
      end
      str
    end
  end
end

class ActionView::Helpers::InstanceTag
  
  instance_methods.each do |m|
    if m =~ /^to_(.*)_tag$/
      next if $1 == 'content'
      new_method = (m+Rlayout::TemplateUtil::WITH_TEMPLATE).to_sym
      alias_method(new_method, m.to_sym) unless method_defined?(new_method)
      class_eval %{
        def #{m}(*args)
          return #{m}#{Rlayout::TemplateUtil::WITH_TEMPLATE}(*args) if @is_enter
          @is_enter = true
          str = #{m}#{Rlayout::TemplateUtil::WITH_TEMPLATE}(*args)
          @is_enter = nil
          context = {}
          context[:input_type] = @tag_type_4template
          context[:name] = @object_name
          context[:simple_name] = @object_name.rindex('_').nil? ? @object_name : @object_name[(@object_name.rindex('_') + 1)..-1]
          context[:full_name] = @tag_name_4template
          context[:id] = @tag_id_4template
          context[:object] = @object
          context[:method_name] = @method_name
          context[:options] = @options_4template
          context[:hidden] = @hidden_options
          Rlayout::TemplateUtil.round_tag('#{$1}', context, str, *args)
        end
      }
    end
  end
  
  alias_method :add_default_name_and_id_old4template, :add_default_name_and_id unless method_defined?(:add_default_name_and_id_old4template)
  def add_default_name_and_id(options)
    add_default_name_and_id_old4template(options)
#    if options['special_name']
#      options['name'] = options['special_name'] == true ? @method_name : options['special_name']
#    end
    @tag_name_4template = options['name']
    @tag_id_4template = options['id']
    @tag_type_4template = options['type']
    @options_4template = options
    @hidden_options = options.delete('hidden') || {}
  end
  
end
module ActionView::Helpers::FormTagHelper
  
  instance_methods.each do |m|
    if m =~ /(.*)_tag$/
      next if $1 == 'form' || $1 == 'field_set'
      new_method = (m+Rlayout::TemplateUtil::WITH_TEMPLATE).to_sym
      alias_method(new_method, m.to_sym) unless method_defined?(new_method)
      class_eval %{
        def #{m}(*args)
          return #{m}#{Rlayout::TemplateUtil::WITH_TEMPLATE}(*args) if @is_enter
          @is_enter = true
          options = args[-1].is_a?(Hash) ? args[-1] : {}
          name = #{['submit', 'image'].include?(m) ? '""' : 'args[0] ||= ""'}
          context = {}
          context[:name] = name
          context[:simple_name] = name
          context[:full_name] = name
          context[:id] = name
          context[:method_name] = name
          context[:hidden] = options.delete('hidden') || {}
          str = #{m}#{Rlayout::TemplateUtil::WITH_TEMPLATE}(*args)
          @is_enter = nil
          context[:options] = options.stringify_keys!
          Rlayout::TemplateUtil.round_tag('#{$1}', context, str, *args)
        end
      }
    end
  end
end