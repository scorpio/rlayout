=begin Rlayout
author: Leon Li(scorpio_leon@hotmail.com)
=end

module Rlayout
  module Layout
    LAYOUT_PARAMETER = :layout if !defined?(LAYOUT_PARAMETER)
    def self.included(base)
      base.class_eval do
        # #for rails 2.1
        if method_defined?(:render_with_no_layout)
          base.class_eval do
            alias_method :render, :render_with_a_layout_ext
          end
        end

        # #for rails 2.2
        base.class_eval do
          alias_method :_render_with_layout, :_render_with_layout_with_rlayout
        end
      end

    end

    #for rails 2.1
    def render_with_a_layout_ext(options = nil, extra_options = {}, &block) #:nodoc:
      template_with_options = options.is_a?(Hash)

      # #get layout from view
      options_new = options.dup.merge :layout => false if template_with_options
      content_for_layout = render_with_no_layout(options_new, extra_options, &block)
      new_layout = params[LAYOUT_PARAMETER]
      if new_layout.nil? || new_layout.empty?
        page_config = @template.instance_variable_get("@content_for_config")
        unless page_config.nil?
          page_config = page_config.strip
          page_config.split("\n").each do |pair|
            key, value = pair.split(": ")
            value = '' if value.nil?
            if key == 'layout'
              new_layout = value
            else
              @template.instance_variable_set("@content_for_#{key}", value)
            end
          end
        end
      end
      unless new_layout.nil? || new_layout.empty?
        options ||= {}
        options[:layout] = new_layout == 'false' ? false : new_layout
        template_with_options = true
      end

      if (layout = pick_layout(template_with_options, options)) && apply_layout?(template_with_options, options)
        # #assert_existence_of_template_file(layout)

        options = options.merge :layout => false if template_with_options
        logger.info("Rendering template within #{layout}") if logger
        # #content_for_layout = render_with_no_layout(options, &block)
        erase_render_results
        add_variables_to_assigns
        @template.instance_variable_set("@content_for_layout", content_for_layout)
        response.layout = layout
        status = template_with_options ? options[:status] : nil
        render_for_text(@template.render_file(layout, true), status)
      else
        # #render_with_no_layout(options, &block)
        content_for_layout
      end
    end

    #for rails 2.2
    def  _render_with_layout_with_rlayout(options, local_assigns, &block) #:nodoc:
      partial_layout = options.delete(:layout)

      if block_given?
        begin
          @_proc_for_layout = block
          concat(render(options.merge(:partial => partial_layout)))
        ensure
          @_proc_for_layout = nil
        end
      else
        begin

          original_content_for_layout = @content_for_layout if defined?(@content_for_layout)
          @content_for_layout = render(options)

          # #part 1 start to add for extract layout from page
          pagel_layout = params[LAYOUT_PARAMETER] unless params[LAYOUT_PARAMETER].nil?
          unless @content_for_config.nil?
            @content_for_config.strip!
            @content_for_config.split("\n").each do |pair|
              next unless pair.index(":")
              seperator_index = pair.index(":") - 1
              key = pair[0..seperator_index]
              value = pair[(seperator_index + 2)..pair.length] || ''
              value.strip!
              if key == 'layout'
                pagel_layout = value if pagel_layout.nil? || pagel_layout.empty?
              else
                if key == 'head' && value =~ /<meta\s*name=["']?layout["']?\s*content=["']([^"']+)/
                  pagel_layout = $1
                end
                instance_variable_set("@content_for_#{key}", value)
              end
            end
          end
          
          unless pagel_layout == 'false'
            partial_layout = active_layout(pagel_layout) if pagel_layout.present?
            # #part 1 end to add for extract layout from page
            if (options[:inline] || options[:file] || options[:text])
              @cached_content_for_layout = @content_for_layout
              render(:file => partial_layout, :locals => local_assigns)
            else
              render(options.merge(:partial => partial_layout))
            end
            # #part 2 start to add for extract layout from page
          else
            @content_for_layout
          end
          # #part 2 end to add for extract layout from page
        ensure
          @content_for_layout = original_content_for_layout
        end
      end
    end
  end
end
=begin Rlayout
author: Leon Li(scorpio_leon@hotmail.com)
=end
