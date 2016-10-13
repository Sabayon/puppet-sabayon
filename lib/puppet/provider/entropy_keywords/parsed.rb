require 'puppet/provider/parsedfile'
file = "/etc/entropy/packages/package.keywords"

Puppet::Type.type(:entropy_keywords).provide(:parsed,
  :parent => Puppet::Provider::ParsedFile,
  :default_target => file,
  :filetype => :flat
) do

  desc "Override keywords for entropy packages"

  defaultfor :operatingsystem => :sabayon

  text_line :blank,
    :match => /^\s*$/

  text_line :comment,
    :match      => /^\s*#/

  text_line :unmanaged,
    :match   => %r{^(\S+)\s+([<>]?=)?(?:((?:[A-Za-z0-9+_.-]+/)?[a-zA-Z0-9+_-]+)?(?:-(\d+(?:\.\d+)*[a-z]*(?:_(?:alpha|beta|pre|p|rc)\d*)?(?:-r\d+)?))?)?(?:\s*repo=([a-zA-Z0-9\._-]+))?\s*$}

  record_line :parsed,
    :fields => %w{keyword operator package version repo name},
    :match   => %r{^(\S+)\s+([<>]?=)?(?:((?:[A-Za-z0-9+_.-]+/)?[a-zA-Z0-9+_-]+)?(?:-(\d+(?:\.\d+)*[a-z]*(?:_(?:alpha|beta|pre|p|rc)\d*)?(?:-r\d+)?))?)?(?:\s*repo=([a-zA-Z0-9\._-]+))?\s+## Puppet Name: (.*)\s*$},
    :to_line => proc { |record|
      line = record[:keyword] + " "
      line += record[:operator]        if record[:operator]
      line += record[:package]         if record[:package]
      line += "-" + record[:version]   if record[:version]
      line += " "                      if record[:package] && record[:repo]
      line += "repo=" + record[:repo]  if record[:repo]
      line += " ## Puppet Name: " + record[:name]

      line
    }

end

# vim: set ts=2 shiftwidth=2 expandtab :

