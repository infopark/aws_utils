require 'aws-sdk'

require 'infopark/aws_utils'

module Infopark
  module AwsUtils

class Env
  def initialize(profile_name = nil)
    @credentials = Aws::SharedCredentials.new(profile_name: profile_name)
    @clients = Hash.new do |clients, mod|
      mod.const_get(:Client).new(credentials: @credentials, region: 'eu-west-1')
    end
  end

  def profile_name
    @credentials.profile_name
  end

  def ecs
    @clients[Aws::ECS]
  end

  def ecr
    @clients[Aws::ECR]
  end

  def ec2
    @clients[Aws::EC2]
  end

  def as
    @clients[Aws::AutoScaling]
  end

  def alb
    @clients[Aws::ElasticLoadBalancingV2]
  end

  def aas
    @clients[Aws::ApplicationAutoScaling]
  end

  def cw
    @clients[Aws::CloudWatch]
  end

  def cwl
    @clients[Aws::CloudWatchLogs]
  end

  def sts
    @clients[Aws::STS]
  end


  def dev_account?
    sts.get_caller_identity.account == DEV_ACCOUNT_ID
  end

  def latest_base_image
    available_images = AwsUtils.gather_all(ec2, :describe_images,
        owners: [AWS_AMI_OWNER],
        filters: [
          {name: "root-device-type", values: ["instance-store"]},
          {name: "image-type", values: ["machine"]},
          {name: "virtualization-type", values: ["hvm"]},
        ]).reject {|image| image.name.include?(".rc-") || image.name.include?("-minimal-") }
    available_images.sort_by(&:creation_date).last
  end

  def find_image_by_id(id)
    AwsUtils.gather_all(ec2, :describe_images, image_ids: [id]).first
  end

  def find_image_by_name(name)
    AwsUtils.gather_all(ec2, :describe_images, owners: [DEV_ACCOUNT_ID],
        filters: [{name: "name", values: [name]}]).first
  end
end

  end
end
