#!/usr/bin/env ruby -w

require "rubygems"
require "bundler/setup"
require "active_support/core_ext/array/extract_options"
require "open-uri"

#
# nDistrb - Node distribution manager on Ruby
# rewrited from nDistro
#
# nDisro Copyright (c) 2010 - TJ Holowaychuk <tj@vision-media.ca>
# Licensed MIT.
#

# VERSION="0.0.1"
# DIR=${0%/*}
ROOT=Dir.pwd
# BIN_URL="http://github.com/visionmedia/nodes/raw/master"
# GET=

# wget support
# which wget > /dev/null && GET="wget -q -O-"

# curl support
# which curl > /dev/null && GET="curl -# -L"

#
# Exit with the given <msg ...>
#

def abort(*msg)
  option = { :io => $stdout, :kernel => Kernel }
  option.merge! msg.extract_options!
  option[:io].puts "Error: #{msg.join(' ')}"
  option[:kernel]::exit(1)
end

def log(*msg)
  option = { :io => $stdout}
  option.merge! msg.extract_options!
  option[:io].puts "... #{msg.join(' ')}"
end

def usage(*args)
  option = { :io => $stdout}
  option.merge! args.extract_options!
  option[:io].puts <<-HELP

Usage: ndistrb [options] [cmd]

Commands:

  edit              Opens CWD/.ndistro in $EDITOR
  update            Update ndistro to the latest version
  <user> <distro>   Installs the given <distro> from <user>

Options:

  -V, --version   Output version number
  -h, --help      Output help information

HELP
end

#
# List <user> distros.
#

def list_user_distros(user)
  log "fetching #{user} distro list"

  open("http://github.com/api/v2/yaml/blob/all/#{user}/.ndistro/master") do |f|
    2.times do
      g.gets
    end
    f.each_line.map { |s| s.split(':')[0].strip}
  end
end

def Load_module(user, mod, version, alias_as)
  version ||= 'master'
  dest="#{ROOT}/modules/#{mod}"
  version_file="#{dest}/.ndistro_module_version"
  url="https://github.com/#{user}/#{mod}/tarball/$version"
  update_message="update with $ rm -fr modules/#{mod} && ndistrb"

    else if
    end
  else
  end
  if File.exist? dest
    if File.exist? version_file
      current_version = open(version_file) { |f| f.read }
      if current_version != version
        log "outdated module #{mod} #{current_version} (requested #{version})"
        log update_message
      else
        log "already installed #{mod} #{version}"
      end
    elsif version != 'master'
      log "already installed #{mod}, but version is unknown"
      log update_message
    end
  else
    log "installing #{mod} #{version}"
    Dir.mkdir dest
    Dir.chdir(dest) do
      && $GET $url \
      | tar -xz --strip 1 \
      && cd ../.. \
      && bin $mod \
      && build $mod \
      && lib $mod $alias_as \
      && echo "$version" > $version_file
    end
  end

end
