module Infopark
  module AwsUtils
    AWS_AMI_OWNER = "137112412989"
    DEV_ACCOUNT_ID = "012615398682"
    PROD_ACCOUNT_ID = "115379056088"

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
    end
  end
end
