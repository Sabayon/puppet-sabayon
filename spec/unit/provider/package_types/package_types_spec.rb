require 'spec_helper'
require 'puppet/type/entropy_mask'
require 'puppet/type/entropy_unmask'
require 'puppet/type/entropy_splitdebug'
require 'puppet/type/entropy_splitdebug_mask'

types = {
  :entropy_mask            => Puppet::Type::Entropy_mask,
  :entropy_unmask          => Puppet::Type::Entropy_unmask,
  :entropy_splitdebug      => Puppet::Type::Entropy_splitdebug,
  :entropy_splitdebug_mask => Puppet::Type::Entropy_splitdebug_mask,
}

default_targets = {
  :entropy_mask            => '/etc/entropy/packages/package.mask',
  :entropy_unmask          => '/etc/entropy/packages/package.unmask',
  :entropy_splitdebug      => '/etc/entropy/packages/package.splitdebug',
  :entropy_splitdebug_mask => '/etc/entropy/packages/package.splitdebug.mask',
}

types.each do |type_name, type|
  describe Puppet::Type.type(type_name).provider(:parsed) do
    before do
      described_class.stubs(:filetype).returns(Puppet::Util::FileType::FileTypeRam)
      described_class.stubs(:filetype=)
      @default_target = described_class.default_target
    end

    describe "should have a default target of #{default_targets[type_name]}" do
      it do
        expect(described_class.default_target).to eq(default_targets[type_name])
      end
    end

    describe "when parsing" do
      it "should parse out the name" do
        line = 'app-admin/foobar ## Puppet Name: foobar'
        expect(described_class.parse_line(line)[:name]).to eq('foobar')
      end

      context "with just a package name" do
        line = 'app-admin/foobar ## Puppet Name: foobar'
        parsed = described_class.parse_line(line)

        it "should parse out the package name" do
          expect(parsed[:package]).to eq('app-admin/foobar')
        end

        it "should have all other parameters undefined" do
          [:operator, :version, :slot, :use, :tag, :repo].each do |param|
            expect(parsed[param]).to be_nil
          end
        end
      end

      context "with a versioned package" do
        line = 'app-admin/foobar-1.2.3_alpha1-r1 ## Puppet Name: foobar'
        parsed = described_class.parse_line(line)

        it "should parse out the package name" do
          expect(parsed[:package]).to eq('app-admin/foobar')
        end

        it "should parse out the version" do
          expect(parsed[:version]).to eq('1.2.3_alpha1-r1')
        end

        it "should have all other parameters undefined" do
          [:operator, :slot, :use, :tag, :repo].each do |param|
            expect(parsed[param]).to be_nil
          end
        end
      end

      context "with a package range" do
        line = '>=app-admin/foobar-1.2.3_alpha1-r1 ## Puppet Name: foobar'
        parsed = described_class.parse_line(line)

        it "should parse out the package name" do
          expect(parsed[:package]).to eq('app-admin/foobar')
        end

        it "should parse out the version" do
          expect(parsed[:version]).to eq('1.2.3_alpha1-r1')
        end

        it "should parse out the operator" do
          expect(parsed[:operator]).to eq('>=')
        end

        it "should have all other parameters undefined" do
          [:slot, :use, :tag, :repo].each do |param|
            expect(parsed[param]).to be_nil
          end
        end
      end

      context "with a slotted package" do
        line = 'app-admin/foobar:1.1 ## Puppet Name: foobar'
        parsed = described_class.parse_line(line)

        it "should parse out the package name" do
          expect(parsed[:package]).to eq('app-admin/foobar')
        end

        it "should parse out the slot" do
          expect(parsed[:slot]).to eq('1.1')
        end

        it "should have all other parameters undefined" do
          [:operator, :version, :use, :tag, :repo].each do |param|
            expect(parsed[param]).to be_nil
          end
        end
      end

      context "with a package with use restrictions" do
        line = 'app-admin/foobar[-foo,bar] ## Puppet Name: foobar'
        parsed = described_class.parse_line(line)

        it "should parse out the package name" do
          expect(parsed[:package]).to eq('app-admin/foobar')
        end

        it "should parse out the use" do
          expect(parsed[:use]).to eq('-foo,bar')
        end

        it "should have all other parameters undefined" do
          [:operator, :version, :slot, :tag, :repo].each do |param|
            expect(parsed[param]).to be_nil
          end
        end
      end

      context "with a tagged package" do
        line = 'app-admin/foobar#server ## Puppet Name: foobar'
        parsed = described_class.parse_line(line)

        it "should parse out the package name" do
          expect(parsed[:package]).to eq('app-admin/foobar')
        end

        it "should parse out the tag" do
          expect(parsed[:tag]).to eq('server')
        end

        it "should have all other parameters undefined" do
          [:operator, :version, :slot, :use, :repo].each do |param|
            expect(parsed[param]).to be_nil
          end
        end
      end

      context "with a package from a specific repo" do
        line = 'app-admin/foobar::community ## Puppet Name: foobar'
        parsed = described_class.parse_line(line)

        it "should parse out the package name" do
          expect(parsed[:package]).to eq('app-admin/foobar')
        end

        it "should parse out the repo" do
          expect(parsed[:repo]).to eq('community')
        end

        it "should have all other parameters undefined" do
          [:operator, :version, :slot, :use, :tag].each do |param|
            expect(parsed[param]).to be_nil
          end
        end
      end

      context "with everything" do
        line = '>=app-admin/foobar-1.2.3a_alpha1-r1:1[-foo]#server::community ## Puppet Name: foobar'
        parsed = described_class.parse_line(line)

        expected = {
          :name     => 'foobar',
          :operator => '>=',
          :package  => 'app-admin/foobar',
          :version  => '1.2.3a_alpha1-r1',
          :slot     => '1',
          :use      => '-foo',
          :tag      => 'server',
          :repo     => 'community',
        }

        it "should parse out all parameters" do
          expected.each do |param, value|
            expect(parsed[param]).to eq(value)
          end
        end
      end

    end
  end
end
