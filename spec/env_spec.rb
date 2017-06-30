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
end
