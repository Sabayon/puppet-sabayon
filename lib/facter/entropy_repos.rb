Facter.add('entropy_repos') do
  confine operatingsystem: :Sabayon

  setcode do
    # Use the types/providers to do the heavy lifting here
    repos = {}

    Puppet::Type.type(:entropy_repo).provider(:file).instances.each do |repo|
      Facter.debug(repo.enabled)
      r = {
        repo_type: repo.repo_type,
        enabled: repo.enabled,
      }

      repos[repo.name] = r
    end

    repos
  end
end
