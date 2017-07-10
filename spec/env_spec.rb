RSpec.describe Infopark::AwsUtils::Env do
  subject(:env) { Infopark::AwsUtils::Env.new }

  describe "#account_type" do
    let(:account_id) { nil }
    let(:sts) do
      instance_double(Aws::STS::Client,
        get_caller_identity: double(:caller_identity, account: account_id)
      )
    end

    before { allow(Aws::STS::Client).to receive(:new).and_return(sts) }

    subject(:account_type) { env.account_type }

    context "for profile in development account" do
      let(:account_id) { "012615398682" }

      it { is_expected.to eq("dev") }
    end

    context "for profile in production account" do
      let(:account_id) { "115379056088" }

      it { is_expected.to eq("prod") }
    end

    context "for profile in some other account" do
      let(:account_id) { "137112412989" }

      it "fails" do
        expect {
          account_type
        }.to raise_error("Could not determine account type.")
      end
    end
  end

  [
    [:aas, Aws::ApplicationAutoScaling],
    [:alb, Aws::ElasticLoadBalancingV2],
    [:as, Aws::AutoScaling],
    [:cw, Aws::CloudWatch],
    [:cwl, Aws::CloudWatchLogs],
    [:ec2, Aws::EC2],
    [:ecr, Aws::ECR],
    [:ecs, Aws::ECS],
    [:sts, Aws::STS],
  ].each do |_client, _mod|
    describe "##{_client}" do
      subject(:client) { env.send(_client) }

      it { is_expected.to be_a(_mod.const_get("Client")) }

      it "is cached" do
        expect(client).to be(env.send(_client))
      end
    end
  end
end
