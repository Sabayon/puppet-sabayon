Puppet::Type.type(:entropy_repo).provide(:file) do
  desc 'File provider for Entropy Repositories'

  defaultfor operatingsystem: :sabayon

  mk_resource_methods

  def type_prefix
    if @property_hash[:repo_type] == 'enman'
      'enman_'
    else
      ''
    end
  end

  def enabled=(value)
    enabled_filename = "/etc/entropy/repositories.conf.d/entropy_#{type_prefix}#{@property_hash[:name]}"
    disabled_filename = "/etc/entropy/repositories.conf.d/_entropy_#{type_prefix}#{@property_hash[:name]}"

    if ['true', :true].include?(value)
      if File.exist?(disabled_filename)
        File.rename(disabled_filename, enabled_filename)
      end
    elsif File.exist?(enabled_filename)
      File.rename(enabled_filename, disabled_filename)
    end

    @property_hash[:enabled] = value
  end

  def self.instances
    repos = Dir.entries('/etc/entropy/repositories.conf.d/')

    repos.map { |r|
      if ['.', '..'].include?(r)
        nil
      elsif r =~ %r{\.example$}
        nil
      elsif r !~ %r{^_?entropy_}
        nil
      else
        matches = %r{^(_)?entropy_(enman_)?(.*)$}.match(r)
        enabled = matches[1].nil? ? 'true' : 'false'
        type    = (matches[2] == 'enman_') ? 'enman' : 'entropy'
        name    = matches[3]

        repo = {
          name: name,
          repo_type: type,
          enabled: enabled,
          provider: :entropy_repo,
        }

        new(repo)
      end
    }.compact
  end

  def self.prefetch(resources)
    repos = instances

    resources.each do |name, _resource|
      provider = repos.find { |r| r.name == name }
      if provider
        resources[name].provider = provider
      end
    end
  end
end

# vim: set ts=2 shiftwidth=2 expandtab :
