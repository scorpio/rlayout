=begin Rlayout
# author: Leon Li(scorpio_leon@hotmail.com)
=end
# #TODO support multi-model
require 'rlayout/common'
module Rlayout
  module Model
    def self.included(base)
      base.extend(ClassMethods)
    end

    def create
      before_create if respond_to?(:before_create)
      result = self.class.get_action_result(:create)
      begin
        execute_create
        create_success_callback if respond_to?(:create_success_callback)
        result = result[:success].dup
      rescue => e
        if respond_to?(:create_error_callback)
          create_error_callback(e)
        else
          add_error e
        end
        if result[:error].present?
          result = result[:error].dup
        else
          raise e
        end
      end
      before_create_result if respond_to?(:before_create_result)
      result_type = result.delete(:type)
      case result_type.to_s
      when 'redirect'
        redirect_to(self.class.parse_result(result, binding))
      when 'render'
        render(self.class.parse_result(result, binding))
      end
    end

    def update
      result = self.class.get_action_result(:update)
      before_update if respond_to?(:before_update)
      begin
        execute_update
        update_success_callback if respond_to?(:update_success_callback)
        result = result[:success].dup
      rescue => e
        if respond_to?(:update_error_callback)
          update_error_callback(e)
        else
          add_error e
        end
        if result[:error].present?
          result = result[:error].dup
        else
          raise e
        end
      end
      before_update_result if respond_to?(:before_update_result)
      result_type = result.delete(:type)
      case result_type.to_s
      when 'redirect'
        redirect_to(self.class.parse_result(result, binding))
      when 'render'
        render(self.class.parse_result(result, binding))
      end
    end

    def destroy
      result = self.class.get_action_result(:destroy)
      before_destroy if respond_to?(:before_destroy)
      begin
        execute_destroy
        destroy_success_callback if respond_to?(:destroy_success_callback)
        result = result[:success].dup
      rescue => e
        if respond_to?(:destroy_error_callback)
          destroy_error_callback(e)
        else
          add_error e
        end
        if result[:error].present?
          result = result[:error].dup
        else
          raise e
        end
      end
      before_destroy_result if respond_to?(:before_destroy_result)
      result_type = result.delete(:type)
      case result_type.to_s
      when 'redirect'
        redirect_to(self.class.parse_result(result, binding))
      when 'render'
        render(self.class.parse_result(result, binding))
      end
    end

    protected

    def add_error(error=nil)
      flash[:error] ||= []
      flash[:error] = [flash[:error]] unless flash[:error].is_a?(Array)
      flash[:error] << (error || $!.to_s)
    end

    def find_model_by_id
      self.class.get_model_class.find(params[:id])
    end
    
    def need_model?
      @action_name_sym = params[:action].to_sym
      self.class.need_model[@action_name_sym] ||= begin
        model_require = self.class.get_model_require
        if model_require.nil?
          false
        else
          if model_require.include?(:none)
            false
          else
            model_require_options = self.class.get_model_require_options
            # #TODO use regex
            if model_require_options && model_require_options[:except] && model_require_options[:except].include?(@action_name_sym)
              false
            else
              model_require && (model_require.include?(@action_name_sym) || model_require.include?(:all))
            end
          end
        end
      end
    end

    def fetch_model
      if params[:id].present?
        @model = find_model_by_id
      else
        @model = self.class.get_model_class.new
      end
    end
    
    def set_model
      if need_model?
        @model = nil
        fetch_model
        if @model && !request.get?
          params_key = self.class.get_full_model_name.gsub(/\//, "_").to_sym
          @model.attributes=params[params_key] unless @model.nil? || params[params_key].nil?
        end
        # #bind @model to @#{self.class.get_model_name}
        instance_variable_set("@#{self.class.get_model_name}", @model)
      else
        @model = instance_variable_get("@#{self.class.get_model_name}")
      end
      
    end
    
    def model?
      @model_exists = (@model && @model.id) if @model_exists.nil?
    end
    
    def execute_create
      if respond_to?(:create_action)
        create_action
      else
        @model.save!
      end
    end
    
    def execute_update
      if respond_to?(:update_action)
        update_action
      else
        @model.save!
      end
    end
    
    def execute_destroy
      if respond_to?(:destroy_action)
        destroy_action
      else
        @model.destroy
      end
    end
    
    
    
    module ClassMethods
      
      def model_require(*model_require)
        options = model_require.extract_options! || {}
        klass = options.delete(:class)
        model_class(klass) unless klass.nil?
        options.each {|k, v| options[k] = [v] unless v.is_a?(Array)}
        @model_require = model_require
        @model_require_options = options
      end
      
      def get_model_require
        @model_require
      end
      def get_model_require_options
        @model_require_options
      end
      
      def need_model
        @need_model ||= {}
      end
      
      def need_model=(need)
        @need_model = need
      end
      
      # get the model_name override this if the model's name is special
      def get_model_name
        @model_name ||= self.class_simple_name.underscore[0..-12].singularize
      end

      def get_full_model_name
        @model_full_name ||= self.class_full_name.underscore[0..-12].singularize
      end
      
      def get_model_class
        @model_class ||= eval("#{get_full_model_name.camelize}")
      end
      
      def model_class(model_class)
        @model_class = model_class
        @model_name = model_class.class_simple_name.underscore
        @model_full_name = model_class.class_full_name.underscore
      end
      
      # #inheritable
      def get_default_results
        read_inheritable_attribute("default_results") || {}
      end
      
      # #inheritable
      def set_default_result(hash)
        write_inheritable_hash("default_results", hash)
      end
      
      # #inheritable
      def default_create_result(hash)
        set_default_result(:create => hash)
      end
      def default_update_result(hash)
        set_default_result(:update => hash)
      end
      def default_destroy_result(hash)
        set_default_result(:destroy => hash)
      end
      
      def set_action_result(hash)
        @action_results ||= {}
        @action_results.merge!(hash)
      end
      
      def create_result(hash)
        set_action_result(:create => hash)
      end
      def update_result(hash)
        set_action_result(:update => hash)
      end
      def destroy_result(hash)
        set_action_result(:destroy => hash)
      end
      
      def get_action_result(action)
        if @action_results
          get_default_results.merge(@action_results)[action]
        else
          get_default_results[action]
        end
      end
      
      def parse_result(result, binding)
        result.each do |k, v|
          result[k] = eval(v[4..-1], binding) if v.is_a?(String) && v[0, 4] == 'exp:'
        end
        result
      end
      
    end
  end
end
