Puppet::Type.newtype(:enman_repo) do
  @desc = 'Manages Sabayon Community Repositories'
  @doc = %{Installs or removes an additional entropy package repository
    using the enman tool. Sabayon-maintained projects can be added by
    name. Third party repositories can be added by URL (in which case
    the name parameter must match the name of the repository pointed
    at by the URL).

    If used, the URL should point at the base directory which contains
    the `standard/<repo_name>/database` tree.

    Example:

        enman_repo {'community':
          ensure => present,
        }

        enman_repo {'community':
          ensure => present,
          url    => 'https://example.com/myrepo'
        }
  }

  ensurable

  newparam(:name) do
    desc 'Name of the Enman Repository'
    isnamevar
  end

  newparam(:url) do
    desc 'URL of the Enman Repository'
    validate do |value|
      unless value =~ %r{^https?://.*}
        raise ArgumentError, '%s is not a valid repo url' % value
      end
    end
  end

  autorequire(:package) do
    ['enman']
  end
end

# vim: set ts=2 shiftwidth=2 expandtab :
