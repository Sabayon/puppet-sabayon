require 'puppet/provider/parsedfile'
file = '/etc/entropy/packages/package.splitdebug.mask'

Puppet::Type.type(:entropy_splitdebug_mask).provide(:parsed,
                                                    parent: Puppet::Provider::ParsedFile,
                                                    default_target: file,
                                                    filetype: :flat) do

  desc 'File splitdebug mask provider for entropy packages'

  defaultfor operatingsystem: :sabayon

  text_line :blank,
            match: %r{^\s*$}

  text_line :comment,
            match: %r{^\s*#}

  text_line :unmanaged,
            match: %r{
              ^([<>]?=)?
              ((?:[A-Za-z0-9+_.-]+/)?[a-zA-Z0-9+_-]+)?
              (?:-(\d+(?:\.\d+)*[a-z]*(?:_(?:alpha|beta|pre|p|rc)\d*)?(?:-r\d+)?))?
              (?::([a-zA-Z0-9\._-]+))?
              (?:\[([^\]]*)\])?
              (?:\#([a-zA-Z0-9._-]+))?
              (?:::([a-zA-Z0-9._-]+))?
              \s*$
            }x

  record_line :parsed,
              fields: ['operator', 'package', 'version', 'slot', 'use', 'tag', 'repo', 'name'],
              match: %r{
                ^([<>]?=)?
                ((?:[A-Za-z0-9+_.-]+/)?[a-zA-Z0-9+_-]+)?
                (?:-(\d+(?:\.\d+)*[a-z]*(?:_(?:alpha|beta|pre|p|rc)\d*)?(?:-r\d+)?))?
                (?::([a-zA-Z0-9._-]+))?(?:\[([^\]]*)\])?
                (?:\#([a-zA-Z0-9._-]+))?
                (?:::([a-zA-Z0-9._-]+))?
                \s+\#+\s+Puppet\s+Name:\s+(.*)
                \s*$
              }x,
              to_line: proc { |record|
                line = ''
                line += record[:operator]        if record[:operator]
                line += record[:package]         if record[:package]
                line += '-' + record[:version]   if record[:version]
                line += ':' + record[:slot]      if record[:slot]
                line += '[' + record[:use] + ']' if record[:use]
                line += '#' + record[:tag]       if record[:tag]
                line += '::' + record[:repo]     if record[:repo]
                line += ' ## Puppet Name: ' + record[:name]

                line
              }
end

# vim: set ts=2 shiftwidth=2 expandtab :
