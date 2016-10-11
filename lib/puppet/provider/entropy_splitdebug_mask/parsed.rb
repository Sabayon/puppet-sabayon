require 'puppet/provider/parsedfile'
file = "/etc/entropy/packages/package.splitdebug.mask"

Puppet::Type.type(:entropy_splitdebug).provide(:parsed,
  :parent => Puppet::Provider::ParsedFile,
  :default_target => file,
  :filetype => :flat
) do

  desc "File splitdebug mask provider for entropy packages"

  defaultfor :operatingsystem => :sabayon

  text_line :blank,
    :match => /^\s*$/

  text_line :comment,
    :match      => /^\s*#/

  text_line :unmanaged,
    :match   => %r{^([<>]?=)?([a-zA-Z+\/-]*)(?:-(\d+(?:\.\d+)*[a-z]*(?:_(?:alpha|beta|pre|p|rc)\d*)?(?:-r\d+)?))?(?::(\w+))?(?:\[([^\]]*)\])?(?:#(\w+))?(?:::(\w+))?\s*$}

  record_line :parsed,
    :fields => %w{operator package version slot use tag repo name},
    :match   => %r{^([<>]?=)?([a-zA-Z+\/-]*)(?:-(\d+(?:\.\d+)*[a-z]*(?:_(?:alpha|beta|pre|p|rc)\d*)?(?:-r\d+)?))?(?::(\w+))?(?:\[([^\]]*)\])?(?:#(\w+))?(?:::(\w+))?\s+# Puppet Name: (.*)\s*$},
    :block_eval => :instance do

    def to_line(record)
      line = ""
      line += record[:operator]        if record[:operator]
      line += record[:package]
      line += "-" + record[:version]   if record[:version]
      line += ":" + record[:slot]      if record[:slot]
      line += "[" + record[:use] + "]" if record[:use]
      line += "#" + record[:tag]       if record[:tag]
      line += "::" + record[:repo]     if record[:repo]
      line += " # Puppet Name: " + record[:name]

      line
    end

  end
   
end

# vim: set ts=2 shiftwidth=2 expandtab :

