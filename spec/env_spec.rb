RSpec.describe Infopark::AwsUtils::Env do
  let(:account_id) { nil }
  let(:sts) do
    Aws::STS::Client.new(region: "eu-west-1").tap do |client|
      allow(client).to receive(:get_caller_identity)
          .and_return(double(:caller_identity, account: account_id))
    end
  end

  before { allow(Aws::STS::Client).to receive(:new).and_return(sts) }

  subject(:env) { Infopark::AwsUtils::Env.new }

  describe ".profile" do
    let(:requested_profile) { "foo" }
    let(:env_var) { "AWS_#{requested_profile.upcase}_PROFILE" }

    subject { Infopark::AwsUtils::Env.profile(requested_profile) }

    before do
      allow(Aws::SharedCredentials).to receive(:new).with(profile_name: requested_profile)
        .and_return(
          instance_double(
            Aws::SharedCredentials,
            profile_name: requested_profile,
            credentials: instance_double(Aws::Credentials),
          ),
        )
      allow(Aws.shared_config).to receive(:region).with(profile: requested_profile)
        .and_return("eu-west-1")
    end

    it { is_expected.to be_a(Infopark::AwsUtils::Env) }

    it "uses credentials for the requested profile" do
      expect(subject.ecs.config.credentials.profile_name).to eq(requested_profile)
    end

    context "when requested profile does not exist" do
      before do
        allow(Aws::SharedCredentials).to receive(:new).with(profile_name: requested_profile).
            and_raise(Aws::Errors::NoSuchProfileError, "does not exist")
      end

      it "raises an error, asking for an environment variable specifiying the profile" do
        expect {
          subject
        }.to raise_error("AWS profile “#{requested_profile}” not found."\
                         " Please provide the #{requested_profile} profile via #{env_var}.")
      end
    end

    context "when requested profile has no credentials configured" do
      before do
        allow(Aws::SharedCredentials).to receive(:new).with(profile_name: requested_profile)
          .and_return(
            instance_double(
              Aws::SharedCredentials,
              profile_name: requested_profile,
              credentials: nil,
            ),
          )
      end

      it "raises an error, asking for the credentials to be configured" do
        expect {
          subject
        }.to raise_error("No credentials for AWS profile “#{requested_profile}” found."\
                         " Please provide them via ~/.aws/credentials.")
      end
    end

    context "when requested profile has no region configured" do
      before do
        allow(Aws.shared_config).to receive(:region).with(profile: requested_profile)
          .and_return(nil)
      end

      it "raises an error, asking for the region to be configured" do
        expect {
          subject
        }.to raise_error("No region for AWS profile “#{requested_profile}” found."\
                         " Please provide them via ~/.aws/config.")
      end
    end

    context "when environment variable is set" do
      let(:value) { "#{requested_profile}_by_env" }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with(env_var).and_return(value)
        allow(Aws::SharedCredentials).to receive(:new).with(profile_name: value).and_return(
          instance_double(
            Aws::SharedCredentials,
            profile_name: value,
            credentials: instance_double(Aws::Credentials),
          ),
        )
        allow(Aws.shared_config).to receive(:region).with(profile: value)
          .and_return("eu-west-1")
      end

      it "uses credentials for this profile" do
        expect(subject.ecs.config.credentials.profile_name).to eq(value)
      end

      context "when profile does not exist" do
        before do
          allow(Aws::SharedCredentials).to receive(:new).with(profile_name: value).
              and_raise(Aws::Errors::NoSuchProfileError, "does not exist")
        end

        it "raises an error, asking for correct environment variable" do
          expect {
            subject
          }.to raise_error("AWS profile “#{value}” not found."\
                           " Please provide the #{requested_profile} profile via #{env_var}.")
        end
      end
    end
  end

  describe "#account_type" do
    before do
      allow(Aws::SharedCredentials).to receive(:new).and_return(
        instance_double(
          Aws::SharedCredentials,
          profile_name: "foo",
          credentials: instance_double(Aws::Credentials),
        ),
      )
      allow(Aws.shared_config).to receive(:region).and_return("eu-west-1")
    end

    subject(:account_type) { env.account_type }

    context "for profile in development account" do
      let(:account_id) { "the_dev_account" }

      it { is_expected.to eq("dev") }
    end

    context "for profile in production account" do
      let(:account_id) { "the_prod_account" }

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

  describe "#dev_account?" do
    before do
      allow(Aws::SharedCredentials).to receive(:new).and_return(
        instance_double(
          Aws::SharedCredentials,
          profile_name: "foo",
          credentials: instance_double(Aws::Credentials),
        ),
      )
      allow(Aws.shared_config).to receive(:region).and_return("eu-west-1")
    end

    subject { env.dev_account? }

    context "for development account" do
      let(:account_id) { "the_dev_account" }

      it { is_expected.to be true }
    end

    context "for production account" do
      let(:account_id) { "the_prod_account" }

      it { is_expected.to be false }
    end

    context "for some other account" do
      let(:account_id) { "137112412989" }

      it { is_expected.to be false }
    end
  end

  describe "#prod_account?" do
    before do
      allow(Aws::SharedCredentials).to receive(:new).and_return(
        instance_double(
          Aws::SharedCredentials,
          profile_name: "foo",
          credentials: instance_double(Aws::Credentials),
        ),
      )
      allow(Aws.shared_config).to receive(:region).and_return("eu-west-1")
    end

    subject { env.prod_account? }

    context "for development account" do
      let(:account_id) { "the_dev_account" }

      it { is_expected.to be false }
    end

    context "for production account" do
      let(:account_id) { "the_prod_account" }

      it { is_expected.to be true }
    end

    context "for some other account" do
      let(:account_id) { "137112412989" }

      it { is_expected.to be false }
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
      before do
        allow(Aws::SharedCredentials).to receive(:new).and_return(
          instance_double(
            Aws::SharedCredentials,
            profile_name: "foo",
            credentials: instance_double(Aws::Credentials),
          ),
        )
        allow(Aws.shared_config).to receive(:region).and_return("eu-west-1")
      end

      subject(:client) { env.send(_client) }

      it { is_expected.to be_a(_mod.const_get("Client")) }

      it "is cached" do
        expect(client).to be(env.send(_client))
      end
    end
  end
end
