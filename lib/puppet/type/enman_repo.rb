Puppet::Type.newtype(:enman_repo) do
  @desc = "foo"
  
  ensurable
  
  newparam(:name) do
    desc "Name of the Enman Repository"
    isnamevar
  end
  
end
