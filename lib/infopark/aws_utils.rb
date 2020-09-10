require 'infopark/aws_utils/env'
require 'json'

module Infopark
  module AwsUtils
    AWS_AMI_OWNER = "137112412989"

    class << self
      def gather_all(client:, method:, response_key:, **options)
        unless block_given?
          @gather_cache ||= {}
          cache_key = [client, method, options]
          return @gather_cache[cache_key] if @gather_cache[cache_key]
        end

        result = []
        loop do
          response = retry_on_throttle { client.send(method, **options) }
          if response.members.include?(:failures) && !response.failures.empty?
            raise "Failed gathering all #{method}: #{response.failures}"
          end
          if block_given?
            response[response_key].each {|entity| retry_on_throttle { yield entity } }
          else
            result += response[response_key]
          end
          unless options[:next_token] = response.members.include?(:next_token) && response.next_token
            break
          end
        end
        @gather_cache[cache_key] = result unless block_given?
      end

      def wait_for(progress, client, waiter, delay: 2, max_attempts: 60, **waiter_params)
        client.wait_until(waiter, waiter_params) do |w|
          w.delay = delay
          w.max_attempts = max_attempts
          w.before_wait { progress.increment }
        end
      end

      protected

      def local_config
        @local_config ||= (
          path = "#{Dir.home}/.config/infopark/aws_utils.json"
          if File.exists?(path)
            JSON.parse(File.read(path))
          else
            {}
          end
        )
      end

      private

      def retry_on_throttle
        yield
      rescue => e
        if e.class.name =~ /Throttl/
          sleep 0.1
          retry
        end
        raise
      end
    end

    DEV_ACCOUNT_ID = ENV['INFOPARK_AWS_DEV_ACCOUNT_ID'] || self.local_config['dev_account_id']
    PROD_ACCOUNT_ID = ENV['INFOPARK_AWS_PROD_ACCOUNT_ID'] || self.local_config['prod_account_id']

    puts "WARN: The Infopark AWS development account ID is not configured." unless DEV_ACCOUNT_ID
    puts "WARN: The Infopark AWS production account ID is not configured." unless PROD_ACCOUNT_ID
  end
end
