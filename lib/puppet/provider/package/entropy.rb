require 'puppet/provider/package'
require 'fileutils'

Puppet::Type.type(:package).provide :entropy, :parent => Puppet::Provider::Package do
  desc "Provides packaging support for Sabayon's entropy system."

  has_feature :versionable

  commands :equo => "/usr/bin/equo"

  #confine :operatingsystem => [ :gentoo, :sabayon ]

  defaultfor :has_entropy => true

  def self.instances
    result_format = /^(\S+)\/(\S+)-([\.\d]+(?:_(?:alpha|beta|pre|rc|p)\d+)?(?:-r\d+)?)$/
    result_fields = [:category, :name, :version_available]

    begin
      search_output = equo "query", "installed", "--nocolor", "--quiet"

      packages = []
      search_output.each do |search_result|
        match = result_format.match(search_result)

        if match
          package = {}
          result_fields.zip(match.captures) do |field, value|
            package[field] = value unless !value or value.empty?
          end
          package[:provider] = :entropy

          print package.to_yaml,"\n" if package[:name]=='htop' || package[:name]=='openssh'

          packages << new(package)
        end
      end

      return packages
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error.new(detail)
    end
  end

  def install
    should = @resource.should(:ensure)
    name = package_name
    unless should == :present or should == :latest
      # We must install a specific version
      name = "=#{name}-#{should}"
    end
    equo "install", name
  end

  # The common package name format.
  def package_name
    @resource[:category] ? "#{@resource[:category]}/#{@resource[:name]}" : @resource[:name]
  end

  def uninstall
    equo "remove", package_name
  end

  def update
    self.install
  end

  def query
    result_format = /@@\s*Package:\s*(\S+)\/(\S+)-[\.\d]+(?:_(?:alpha|beta|pre|rc|p)\d+)?(?:-r?\d+)?\s*branch:\s*\d+,\s*\[\S+\]\s*\n>>\s+Available:\s+version:\s+(\S+)\s+.*?\n>>\s+Installed:\s+version:\s+(Not installed|\S+)\s+/im
    result_fields = [:category, :name, :version_available, :ensure]

    match = package_name.match(/^(?:(.*)\/)?(.*)$/)
    search = {}
    search[:category] = match.captures[0]
    search[:name]     = match.captures[1]

    begin
      search_output = equo "search", "--nocolor", package_name

      packages = []
      search_output.scan(result_format) { |match|

        match_fields = Hash[result_fields.zip(match)]

        # skip packages that don't match exactly (equo search uses fuzzy matching)
        if search[:name] == match_fields[:name] && ( ! search[:category] || search[:category].empty? || search[:category] == match_fields[:category])

           package = {}
           match_fields.each do |field, value|
             package[field] = value unless !value or value.empty?
           end
           package[:ensure] = :absent if package[:ensure] == 'Not installed'
           packages << package
        end
      }

      case packages.size
        when 0
          not_found_value = "#{@resource[:category] ? @resource[:category] : "<unspecified category>"}/#{@resource[:name]}"
          raise Puppet::Error.new("No package found with the specified name [#{not_found_value}]")
        else
          packages.each do |candidate|
            if (! search[:category] || search[:category].empty?) && search[:name] == candidate[:name]
              return candidate
            elsif search[:category] == candidate[:category] && search[:name] == candidate[:name]
              return candidate
            end
            Puppet::Error.new("No exact matches for package '#{package_name}' in entropy db")
          end
        end
    rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error.new(detail)
    end
  end

  def latest
    self.query[:version_available]
  end
end
