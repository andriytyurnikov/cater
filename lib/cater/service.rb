require 'active_support/concern'
require 'active_support/callbacks'

module Cater
  class ServiceError < Exception; end

  module Service
    extend ActiveSupport::Concern

    included do
      include ActiveSupport::Callbacks

      attr_accessor :message

      define_callbacks :call, :success, :error

      def success?
        fail "Service was not called yet" if @_service_success.nil?
        @_service_success
      end

      def error!(message=nil)
        message = message
        raise ServiceError
      end

      def error?
        !success?
      end

      private
      
      def _service_success=(result)
        @_service_success = result
      end
    end

    class_methods do
      def after_call(*filters, &blk)
        set_callback(:call, :after, *filters, &blk)
      end

      def around_call(*filters, &blk)
        set_callback(:call, :around, *filters, &blk)
      end

      def before_call(*filters, &blk)
        set_callback(:call, :before, *filters, &blk)
      end

      def after_success(*filters, &blk)
        set_callback(:success, :after, *filters, &blk)
      end

      def after_error(*filters, &blk)
        set_callback(:error, :after, *filters, &blk)
      end

      def call(*args)
        instance = self.new
        instance.run_callbacks :call do
          begin
            instance.call(*args)
            instance.send(:_service_success=, true)
            instance.run_callbacks :success
          rescue ServiceError
            instance.send(:_service_success=, false)
            instance.run_callbacks :error
          end
        end
        
        return instance
      end
    end

  end
end