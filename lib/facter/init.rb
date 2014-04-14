# init.rb
# Determine the init system in use on Sabayon/Gentoo systems


Facter.add("init") do
    setcode do
        init = %x{/usr/bin/stat -c '%N' /sbin/init | /usr/bin/awk '{print $3}'}.chomp
        if /systemd/.match(init)
            'systemd'
        else
            'sysvinit'
        end
    end
end

