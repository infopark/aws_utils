require_relative 'lib/infopark/aws_utils/version'

Gem::Specification.new do |s|
  s.name = 'infopark-aws_utils'
  s.version = Infopark::AwsUtils::VERSION
  s.summary = 'A utility lib to ease the use of the AWS SDK'
  s.description = s.summary
  s.authors = ['Tilo Prütz']
  s.email = 'tilo@infopark.de'
  s.files = `git ls-files -z`.split("\0")
  s.license = 'UNLICENSED'

  s.add_dependency "aws-sdk-applicationautoscaling", "~> 1"
  s.add_dependency "aws-sdk-autoscaling", "~> 1"
  s.add_dependency "aws-sdk-cloudwatch", "~> 1"
  s.add_dependency "aws-sdk-cloudwatchlogs", "~> 1"
  s.add_dependency "aws-sdk-ec2", "~> 1"
  s.add_dependency "aws-sdk-ecr", "~> 1"
  s.add_dependency "aws-sdk-ecs", "~> 1"
  s.add_dependency "aws-sdk-elasticloadbalancingv2", "~> 1"

  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
end
