require 'spec_helper'
describe 'sabayon' do
  context 'with default values for all parameters' do
    it { is_expected.to contain_class('sabayon') }
    it { is_expected.to contain_package('app-admin/enman') }
  end
end
