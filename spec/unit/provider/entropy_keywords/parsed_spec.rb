require 'spec_helper'

describe Puppet::Type.type(:entropy_keywords).provider(:parsed) do
  before(:each) do
    described_class.stubs(:filetype).returns(Puppet::Util::FileType::FileTypeRam)
    described_class.stubs(:filetype=)
    @default_target = described_class.default_target
  end

  describe 'should have a default target of /etc/entropy/packages/package.keywords' do
    it do
      expect(described_class.default_target).to eq('/etc/entropy/packages/package.keywords')
    end
  end

  describe 'when parsing' do
    it 'parses out the name' do
      line = '** app-admin/foobar ## Puppet Name: foobar'
      expect(described_class.parse_line(line)[:name]).to eq('foobar')
    end

    context 'with just a package name' do
      line = '** app-admin/foobar ## Puppet Name: foobar'
      parsed = described_class.parse_line(line)

      it 'parses out the keyword' do
        expect(parsed[:keyword]).to eq('**')
      end

      it 'parses out the package name' do
        expect(parsed[:package]).to eq('app-admin/foobar')
      end

      it 'has all other parameters undefined' do
        [:operator, :version, :repo].each do |param|
          expect(parsed[param]).to be_nil
        end
      end
    end

    context 'with a versioned package' do
      line = '** app-admin/foobar-1.2.3_alpha1-r1 ## Puppet Name: foobar'
      parsed = described_class.parse_line(line)

      it 'parses out the keyword' do
        expect(parsed[:keyword]).to eq('**')
      end

      it 'parses out the package name' do
        expect(parsed[:package]).to eq('app-admin/foobar')
      end

      it 'parses out the version' do
        expect(parsed[:version]).to eq('1.2.3_alpha1-r1')
      end

      it 'has all other parameters undefined' do
        [:operator, :repo].each do |param|
          expect(parsed[param]).to be_nil
        end
      end
    end

    context 'with a package range' do
      line = '** >=app-admin/foobar-1.2.3_alpha1-r1 ## Puppet Name: foobar'
      parsed = described_class.parse_line(line)

      it 'parses out the keyword' do
        expect(parsed[:keyword]).to eq('**')
      end

      it 'parses out the package name' do
        expect(parsed[:package]).to eq('app-admin/foobar')
      end

      it 'parses out the version' do
        expect(parsed[:version]).to eq('1.2.3_alpha1-r1')
      end

      it 'parses out the operator' do
        expect(parsed[:operator]).to eq('>=')
      end

      it 'has all other parameters undefined' do
        [:repo].each do |param|
          expect(parsed[param]).to be_nil
        end
      end
    end

    context 'with a package from a specific repo' do
      line = '** app-admin/foobar repo=community ## Puppet Name: foobar'
      parsed = described_class.parse_line(line)

      it 'parses out the keyword' do
        expect(parsed[:keyword]).to eq('**')
      end

      it 'parses out the package name' do
        expect(parsed[:package]).to eq('app-admin/foobar')
      end

      it 'parses out the repo' do
        expect(parsed[:repo]).to eq('community')
      end

      it 'has all other parameters undefined' do
        [:operator, :version].each do |param|
          expect(parsed[param]).to be_nil
        end
      end
    end

    context 'with all packages from a specific repo' do
      line = 'amd64 repo=community ## Puppet Name: foobar'
      parsed = described_class.parse_line(line)

      it 'parses out the keyword' do
        expect(parsed[:keyword]).to eq('amd64')
      end

      it 'parses out the repo' do
        expect(parsed[:repo]).to eq('community')
      end

      it 'has all other parameters undefined' do
        [:package, :operator, :version].each do |param|
          expect(parsed[param]).to be_nil
        end
      end
    end

    context 'with everything' do
      line = '** >=app-admin/foobar-1.2.3a_alpha1-r1 repo=community ## Puppet Name: foobar'
      parsed = described_class.parse_line(line)

      expected = {
        name: 'foobar',
        keyword: '**',
        package: 'app-admin/foobar',
        operator: '>=',
        version: '1.2.3a_alpha1-r1',
        repo: 'community',
      }

      it 'parses out all parameters' do
        expected.each do |param, value|
          expect(parsed[param]).to eq(value)
        end
      end
    end
  end

  describe 'when flushing' do
    before :each do
      @ramfile = Puppet::Util::FileType::FileTypeRam.new(@default_target)
      File.stubs(:exist?).with(@default_target).returns(true)
      described_class.any_instance.stubs(:target_object).returns(@ramfile)
    end

    after :each do
      described_class.clear
    end

    it 'outputs a single package entry' do
      resource = {
        record_type: :parsed,
        name: 'test',
        keyword: '**',
        package: 'app-admin/foobar',
      }
      expect(described_class.to_line(resource)).to eq '** app-admin/foobar ## Puppet Name: test'
    end

    it 'outputs a versioned package entry' do
      resource = {
        record_type: :parsed,
        name: 'test',
        keyword: '**',
        package: 'app-admin/foobar',
        version: '1.2.3',
      }
      expect(described_class.to_line(resource)).to eq '** app-admin/foobar-1.2.3 ## Puppet Name: test'
    end

    it 'outputs a ranged versioned package entry' do
      resource = {
        record_type: :parsed,
        name: 'test',
        keyword: '**',
        package: 'app-admin/foobar',
        version: '1.2.3',
        operator: '>=',
      }
      expect(described_class.to_line(resource)).to eq '** >=app-admin/foobar-1.2.3 ## Puppet Name: test'
    end

    it 'outputs a repo-specific package entry' do
      resource = {
        record_type: :parsed,
        name: 'test',
        keyword: '**',
        package: 'app-admin/foobar',
        repo: 'community',
      }
      expect(described_class.to_line(resource)).to eq '** app-admin/foobar repo=community ## Puppet Name: test'
    end

    it 'outputs a whole-repo entry' do
      resource = {
        record_type: :parsed,
        name: 'test',
        keyword: '**',
        repo: 'community',
      }
      expect(described_class.to_line(resource)).to eq '** repo=community ## Puppet Name: test'
    end

    it 'outputs all fields for a package entry' do
      resource = {
        record_type: :parsed,
        name: 'test',
        keyword: '**',
        package: 'app-admin/foobar',
        operator: '>=',
        version: '1.2.3',
        repo: 'community',
      }
      expect(described_class.to_line(resource)).to eq '** >=app-admin/foobar-1.2.3 repo=community ## Puppet Name: test'
    end
  end
end
