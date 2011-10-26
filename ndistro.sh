#!/usr/bin/env sh

#
# nDistro - Node distribution manager
#
# Copyright (c) 2010 - TJ Holowaychuk <tj@vision-media.ca>
# Licensed MIT.
#

# Library version

VERSION="0.4.0"
DIR=${0%/*}
ROOT=$(pwd)
BIN_URL="http://github.com/visionmedia/nodes/raw/master"
GET=

# wget support
which wget > /dev/null && GET="wget -q -O-"

# curl support
which curl > /dev/null && GET="curl -# -L"

#
# Exit with the given <msg ...>
#

abort() {
  echo "Error: $@" && exit 1
}

# Ensure we have curl or wget

test -z "$GET" && abort "curl or wget required"

#
# Log the given <msg ...>
#

log() {
  echo "... $@"
}

#
# Install <user> <mod> [version] [version]
#

module() {
  local user=$1
  local mod=$2
  local version=${3-master}
  local alias_as=$4
  local dest="$ROOT/modules/$mod"
  local version_file=$dest/.ndistro_module_version
  local url="https://github.com/$user/$mod/tarball/$version"
  local update_message="update with $ rm -fr modules/$mod && ndistro"

  if test -d $dest; then
    if test -f $version_file; then
      if test "$(cat $version_file)" != "$version"; then
        log "outdated module $mod $(cat $version_file) (requested $version)"
        log $update_message
      else
        log "already installed $mod $version"
      fi
    elif test "$version" != "master"; then
      log "already installed $mod, but version is unknown"
      log $update_message
    fi
  else
    log "installing $mod $version"
    mkdir -p $dest
    cd $dest \
      && $GET $url \
      | tar -xz --strip 1 \
      && cd ../.. \
      && bin $mod \
      && build $mod \
      && lib $mod $alias_as \
      && echo "$version" > $version_file
  fi
}

#
# Install <mod> binaries.
#
#  - alters shebang to $ROOT/bin/node
#

bin() {
  if test -d $ROOT/modules/$mod/bin; then
    cd $ROOT/bin
    for bin in ../modules/$mod/bin/*; do
      local name=${bin##*/}
      log "installing bin/$name"
      local shebang=$(head -n 1 $bin)
      if test "$shebang" = "#!/usr/bin/env node"; then
        sed "s|/usr/bin/env node|$ROOT/bin/node|" $bin \
          > ./$name \
          && chmod a+x ./$name
      else
        ln -sf $bin ./$name
      fi
    done
    cd ..
  fi
}

#
# Maybe build <mod>.
#

build() {
  local mod=$1
  if test -f $ROOT/modules/$mod/wscript; then
    log "building $mod"
    cd $ROOT/modules/$mod \
      && node-waf configure build
  fi
}

#
# Install <mod> library.
#

lib() {
  local mod=$1
  local alias_as=$2
  local moddir=$mod

  if test -n "$alias_as"; then
    moddir=$alias_as
  fi

  mkdir -p $ROOT/lib/node
  if test -f $ROOT/modules/$mod/index.js; then
    cd $ROOT/lib/node
    ln -sf ../../modules/$mod ./$moddir
    cd ../..
  elif test -d $ROOT/modules/$mod/lib; then
    cd $ROOT/lib/node
    if test "$moddir" != "$mod"; then
      moddir="./$moddir"
    else
      moddir="./"
    fi
    ln -sf ../../modules/$mod/lib/* $moddir
    cd ../..
  fi
}

#
# Install node binary <version> for <machine>.
#

install_node() {
  local version=$1
  local machine=$2
  local url="$BIN_URL/$version-$machine"
  log "installing node-$version-$machine"
  $GET $url > bin/node && chmod 0755 bin/node
}

#
# Install node <version>, where version may
# be a semver such as "0.1.102", or "latest".
#

node() {
  if test $2; then
    local machine=$2
  else
    local machine=$(uname -m)
  fi
  if test $1 = "latest"; then
    log "fetching latest node"
    local latest=$($GET "$BIN_URL/latest" 2> /dev/null)
    if test -f $ROOT/bin/node; then
      local version=$($ROOT/bin/node --version)
      if test $version = "v$latest"; then
        log "already up to date"
      else
        log "updating $version to v$latest"
        install_node $latest $machine
      fi
    else
      install_node $latest $machine
    fi
  else
    if test -f $ROOT/bin/node; then
      local version=$($ROOT/bin/node --version)
      if test "$version" = "v$1"; then
        log "already installed node $1"
      else
        log "updating from node $version"
        install_node $1 $machine
      fi
    else
      install_node $1 $machine
    fi
  fi
}

#
# Install distro.
#

install() {
  mkdir -p $ROOT/bin
  if test -f $ROOT/.ndistro; then
    . $ROOT/.ndistro
    log "installation complete"
  else
    abort ".ndistro not found in this directory"
  fi
}

#
# Install <user> <distro>
#

install_user_distro() {
  local user=$1
  local distro=$2
  log "fetching $user $distro"
  $GET "http://github.com/$user/.ndistro/raw/master/$distro" > .ndistro \
    && install
}

#
# List <user> distros.
#

list_user_distros() {
  local user=$1
  log "fetching $user distro list"
  $GET "http://github.com/api/v2/yaml/blob/all/$user/.ndistro/master" \
    2> /dev/null \
    | tail -n +3 \
    | cut -d ':' -f 1
}

#
# Output usage information.
#

usage() {
  cat <<-HELP

Usage: ndistro [options] [cmd]

Commands:

  edit              Opens CWD/.ndistro in $EDITOR
  update            Update ndistro to the latest version
  <user> <distro>   Installs the given <distro> from <user>

Options:

  -V, --version   Output version number
  -h, --help      Output help information

HELP
}

# Handle arguments

if test $# -eq 0; then
  install
else
  case $1 in
    -h|--help)
      usage && exit 1
      ;;
    -V|--version)
      echo $VERSION && exit 1
      ;;
    update)
      log "updating $0"
      rm -fr /tmp/ndistro \
        && git clone --depth 1 -q git://github.com/visionmedia/ndistro.git /tmp/ndistro \
        && cp /tmp/ndistro/bin/ndistro $0 \
        && log "updated $VERSION to" $($0 --version) \
        && exit
      ;;
    edit)
      $EDITOR $ROOT/.ndistro
      ;;
    *)
      test $# -eq 1 && list_user_distros $1
      test $# -eq 2 && install_user_distro $1 $2
      ;;
  esac
fi