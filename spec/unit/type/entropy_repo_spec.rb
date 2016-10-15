describe Puppet::Type.type(:entropy_repo) do
  before do
    @provider = stub 'provider'
    @provider.stubs(:name).returns(:file)
    described_class.stubs(:defaultprovider).returns(@provider)
  end

  it "should be an instance of Puppet::Type::Entropy_repo" do
    expect(described_class.new(:name => "test")).to be_an_instance_of Puppet::Type::Entropy_repo
  end

  describe "when validating attributes" do
    params     = [:name]
    properties = [:repo_type, :enabled]

    params.each do |param|
      it "should have the #{param} param" do
        expect(described_class.attrtype(param)).to eq :param
      end
    end

    properties.each do |property|
      it "should have the #{property} property" do
        expect(described_class.attrtype(property)).to eq :property
      end
    end
  end

  it "should have name as the namevar" do
    expect(described_class.key_attributes).to eq [:name]
  end
end
