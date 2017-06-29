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

  s.add_dependency "aws-sdk", ">=2.10"

  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
end
