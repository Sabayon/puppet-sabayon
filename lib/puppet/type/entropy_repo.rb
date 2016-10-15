require 'puppet/property/boolean'

Puppet::Type.newtype(:entropy_repo) do
  @desc = "Manages Entropy Repositories"
  
  newparam(:name) do
    desc "Name of the Entropy Repository"
  end

  newproperty(:repo_type, :readonly => true) do
    desc "What type of repository this is (enman or entropy)"
  end

  newproperty(:enabled) do
    desc "Whether the repository is enabled or not"
    newvalues('true', 'false')
  end

end

# vim: set ts=2 shiftwidth=2 expandtab :

