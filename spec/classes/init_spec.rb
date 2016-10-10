require 'spec_helper'
describe 'sabayon' do
  context 'with default values for all parameters' do
    it { should contain_class('sabayon') }
    it { should contain_package('app-admin/enman') }
  end
end
