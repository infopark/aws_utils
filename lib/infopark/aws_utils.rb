require 'infopark/aws_utils/env'
require 'json'

module Infopark
  module AwsUtils
    AWS_AMI_OWNER = "137112412989"

    class << self
      def gather_all(client, method, **options)
        @gather_cache ||= {}
        cache_key = [client, method, options]
        return @gather_cache[cache_key] if @gather_cache[cache_key]

        result = []
        loop do
          response = client.send(method, **options)
          key = (response.members - [:next_token, :failures]).first
          if response.members.include?(:failures) && !response.failures.empty?
            raise "Failed gathering all #{method}: #{response.failures}"
          end
          result += response[key]
          unless options[:next_token] = response.members.include?(:next_token) && response.next_token
            break
          end
        end
        @gather_cache[cache_key] = result
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
    end

    DEV_ACCOUNT_ID = ENV['INFOPARK_AWS_DEV_ACCOUNT_ID'] || self.local_config['dev_account_id']
    PROD_ACCOUNT_ID = ENV['INFOPARK_AWS_PROD_ACCOUNT_ID'] || self.local_config['prod_account_id']

    puts "WARN: The Infopark AWS development account ID is not configured." unless DEV_ACCOUNT_ID
    puts "WARN: The Infopark AWS production account ID is not configured." unless PROD_ACCOUNT_ID
  end
end
