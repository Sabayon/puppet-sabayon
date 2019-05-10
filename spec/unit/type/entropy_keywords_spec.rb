describe Puppet::Type.type(:entropy_keywords) do
  before(:each) do
    provider = stub 'provider'
    provider.stubs(:name).returns(:parsed)
    provider.stubs(:ancestors).returns([Puppet::Provider::ParsedFile])
    provider.stubs(:default_target).returns('defaulttarget')
    described_class.stubs(:defaultprovider).returns(provider)
  end

  it 'is an instance of Puppet::Type::Entropy_keywords' do
    expect(described_class.new(name: 'test', package: 'app-admin/dummy')).to be_an_instance_of Puppet::Type::Entropy_keywords
  end

  describe 'when validating attributes' do
    params     = [:name]
    properties = [:package, :operator, :version, :repo, :target]

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

  it 'has name as the namevar' do
    expect(described_class.key_attributes).to eq [:name]
  end

  describe 'when validating the target property' do
    it "defaults to the provider's default target" do
      expect(described_class.new(name: 'test', package: 'app-admin/dummy').should(:target)).to eq 'defaulttarget'
    end
  end

  describe 'when validating required properties' do
    it 'raises an error when a version is passed with no package' do
      expect {
        described_class.new(name: 'test', repo: 'test', version: '1.2.3')
      }.to raise_error(Puppet::Error, %r{Package is required})
    end

    it 'raises an error when an operator is passed with no version' do
      expect {
        described_class.new(name: 'test', package: 'app-admin/dummy', operator: '<=')
      }.to raise_error(Puppet::Error, %r{Version is required})
    end
  end

  describe 'when the catalog includes a matching package' do
    it 'has an autobefore relationship' do
      resource = described_class.new(name: 'test', package: 'app-admin/dummy')
      package = Puppet::Type.type(:package).new(title: 'app-admin/dummy')

      catalog = Puppet::Resource::Catalog.new
      catalog.add_resource package
      catalog.add_resource resource

      befores = resource.autobefore
      expect(befores.size).to eq 1
      expect(befores[0].source).to eq resource
      expect(befores[0].target).to eq package
    end
  end
end
