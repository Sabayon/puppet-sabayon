require 'spec_helper'

describe Puppet::Type.type(:entropy_repo).provider(:file) do
  describe 'when fetching existing resources' do
    let(:instances) do
      described_class.instances
    end

    let(:repos) do
      [
        { name: 'sabayonlinux.org', type: 'entropy', enabled: 'true' },
        { name: 'sabayon-limbo',    type: 'entropy', enabled: 'false' },
        { name: 'community',        type: 'enman',   enabled: 'true' },
      ]
    end

    before(:each) do
      Dir.stubs(:entries).with('/etc/entropy/repositories.conf.d/').returns([
                                                                              '.', '..', 'README',
                                                                              'entropy_sabayonlinux.org',
                                                                              '_entropy_sabayon-limbo',
                                                                              'entropy_enman_community',
                                                                              'entropy_foobar.example'
                                                                            ])
    end

    it 'identifies the correct number of repos' do
      expect(instances.size).to eq(repos.size)
    end

    it 'identifies the correct repo name' do
      repos.each_with_index do |repo, index|
        expect(instances[index].name).to eq(repo[:name])
      end
    end

    it 'identifies the correct enabled state' do
      repos.each_with_index do |repo, index|
        expect(instances[index].enabled).to eq(repo[:enabled])
      end
    end
  end

  describe 'when enabling a repository' do
    it 'enables a disabled repository' do
      File.stubs(:exist?).with('/etc/entropy/repositories.conf.d/entropy_sabayonlinux.org').returns(true).once
      File.stubs(:rename).with('/etc/entropy/repositories.conf.d/entropy_sabayonlinux.org', '/etc/entropy/repositories.conf.d/_entropy_sabayonlinux.org').once
      instance = described_class.new(name: 'sabayonlinux.org', enabled: 'true', type: 'entropy')
      instance.enabled = 'false'
    end
  end

  describe 'when disabling a repository' do
    it 'disables an enabled repository' do
      File.stubs(:exist?).with('/etc/entropy/repositories.conf.d/_entropy_sabayon-limbo').returns(true).once
      File.stubs(:rename).with('/etc/entropy/repositories.conf.d/_entropy_sabayon-limbo', '/etc/entropy/repositories.conf.d/entropy_sabayon-limbo').once
      instance = described_class.new(name: 'sabayon-limbo', enabled: 'false', type: 'entropy')
      instance.enabled = 'true'
    end
  end
end
