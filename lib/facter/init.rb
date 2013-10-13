# init.rb
# Determine the init system in use on Sabayon/Gentoo systems


Facter.add("init") do
    setcode do
        %x{/usr/bin/eselect sysvinit list | /bin/grep '\\[' | /bin/grep '\\*' | /usr/bin/awk '{print $2}'}.chomp
    end
end

