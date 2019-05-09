Puppet::Type.type(:enman_repo).provide(:enman) do
  desc 'Enman provider for Enman Repositories'

  defaultfor operatingsystem: :sabayon

  commands(enman: 'enman')

  mk_resource_methods

  def create
    enman('add', resource[:name])
    @property_hash[:ensure] = :present
  end

  def destroy
    enman('remove', resource[:name])
    @property_hash[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def self.instances
    all_installed = enman('list', '--quiet', '--installed').chomp.split
    all_available = enman('list', '--quiet', '--available').chomp.split

    all_available.map do |available_repo|
      repo = {
        name: available_repo,
        ensure: all_installed.include?(available_repo) ? :present : :absent,
        provider: :enman_repo,
      }

      Puppet.debug(repo)
      new(repo)
    end
  end

  def self.prefetch(resources)
    available_repos = instances

    resources.each do |name, _resource|
      if provider = available_repos.find { |r| r.name == name }
        resources[name].provider = provider
      end
    end
  end
end

# vim: set ts=2 shiftwidth=2 expandtab :
