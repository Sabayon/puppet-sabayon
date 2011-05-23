# Manage gentoo services.  Start/stop is the same as InitSvc, but enable/disable
# is special.
Puppet::Type.type(:service).provide :gentoo, :parent => :init do
  desc "Gentoo's form of `init`-style service management.

  Uses `rc-update` for service enabling and disabling.

  "

  commands :update => "/sbin/rc-update"

  confine :operatingsystem => [ :gentoo, :sabayon ]

  defaultfor :operatingsystem => [ :gentoo, :sabayon ]

  def self.defpath
    superclass.defpath
  end

  def disable
      output = update :del, @resource[:name], :default
  rescue Puppet::ExecutionFailure
      raise Puppet::Error, "Could not disable #{self.name}: #{output}"
  end

  def enabled?
    begin
      output = update :show
    rescue Puppet::ExecutionFailure
      return :false
    end

    line = output.split(/\n/).find { |l| l.include?(@resource[:name]) }

    return :false unless line

    # If it's enabled then it will print output showing service | runlevel
    if output =~ /^\s*#{@resource[:name]}\s*\|\s*(boot|default)/
      return :true
    else
      return :false
    end
  end

  def enable
      output = update :add, @resource[:name], :default
  rescue Puppet::ExecutionFailure
      raise Puppet::Error, "Could not enable #{self.name}: #{output}"
  end
end
