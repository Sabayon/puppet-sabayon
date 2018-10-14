require 'puppet/provider/package'
require 'fileutils'

Puppet::Type.type(:package).provide(:entropy, :parent => Puppet::Provider::Package) do
  desc "Provides packaging support for Sabayon's entropy system."

  has_feature :versionable
  has_feature :installable
  has_feature :uninstallable
  has_feature :upgradeable

  has_command(:equo, "equo") do
    locale = Facter.value(:locale)
    environment({
      :LANG => locale,
      :LC_ALL => locale,
      :LANGUAHE => locale,
    })
  end

  # Require the locale fact exist
  confine :false => Facter.value(:locale).nil?
  confine :osfamily => :Gentoo
  
  defaultfor :operatingsystem => :Sabayon

  def self.instances
    result_format = /^(\S+)\/(\S+)-([\.\d]+(?:_?(?:a(?:lpha)?|b(?:eta)?|pre|pre_pre|rc|p)\d*)?(?:-r\d+)?)(?:#(\S+))?$/
    result_fields = [:category, :name, :ensure]

    begin
      search_output = equo("query", "list", "installed", "--quiet", "--verbose").chomp

      packages = []
      search_output.each_line do |search_result|
        match = result_format.match(search_result)

        if match
          package = {}
          result_fields.zip(match.captures) do |field, value|
            package[field] = value unless !value or value.empty?
          end
          package[:provider] = :entropy

          packages << new(package)
        end
      end

      return packages
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error.new(detail.message)
    end
  end

  def install
    should = @resource.should(:ensure)
    name = package_name
    unless should == :present or should == :latest
      # We must install a specific version
      name = "=#{name}-#{should}"
    end
    begin
      equo "install", name
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error.new(detail.message)
    end
  end

  # The common package name format.
  def package_name
    if @resource[:category]
      "#{@resource[:category]}/#{@resource[:name]}"
    else
      @resource[:name]
    end
  end

  def uninstall
    begin
      equo "remove", package_name
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error.new(detail.message)
    end
  end

  def update
    self.install
  end

  def query
    result_format = /^(\S+)\/(\S+)-([\.\d]+(?:_(?:alpha|beta|pre_pre|pre|rc|p)\d+)?(?:-r\d+)?)(?::[^#]+)?(?:#(\S+))?$/
    result_fields = [:category, :name, :version_available]

    begin
      # Look for an installed package from a known repository
      search_output = equo("match", "--quiet", "--verbose", package_name).chomp

      search_match = search_output.match(result_format)
      if search_match
        package = {}
        result_fields.zip(search_match.captures).each do |field, value|
          package[field] = value unless !value or value.empty?
        end


        begin
          installed_output = equo('match', '--quiet', '--verbose', '--installed', package_name).chomp
          installed_match = installed_output.match(result_format)

          if installed_match
            installed_match_fields = Hash[result_fields.zip(installed_match.captures)]
            package[:ensure] = installed_match_fields[:version_available]
          else
            package[:ensure] = :absent
          end
        rescue Puppet::ExecutionFailure
          package[:ensure] = :absent
        end

        return package

      else
        # List all installed packages and try and find if it's installed from outside a repository
        # If so, assume the installed version is the latest available
        all_installed = equo("query", "list", "installed", "--quiet", "--verbose").chomp

        all_installed.split("\n").each do |installed_package|
        
          search_match = installed_package.match(result_format)
          if search_match
            search_captures = search_match.captures
          
            if (search_captures[0] == @resource[:category] and search_captures[1] == @resource[:name]) or "#{search_captures[0]}/#{search_captures[1]}" == package_name

              package = {
                :ensure => search_captures[2]
              }

              result_fields.zip(search_captures).each do |field, value|
                package[field] = value unless !value or value.empty?
              end

              return package
            
            end
          end
        end

        raise Puppet::Error.new("No package found with the specified name [#{package_name}]")
      end
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error.new(detail.message)
    end
  end

  def latest
    self.query[:version_available]
  end
end
