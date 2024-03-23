#!/bin/bash
# [DEPLOY_QT=1] deploy-linux.sh <executable>
#   (Simplified) bash re-implementation of [linuxdeploy](https://github.com/linuxdeploy).
#   Reads [executable] and copies required libraries to [AppDir]/usr/lib
#   Copies the desktop and svg icon to [AppDir]
#   Respects the AppImage excludelist
#
# Unlike linuxdeploy, this does not:
# - Copy any icon other than svg (too lazy to add that without a test case)
# - Do any verification on the desktop file
# - Run any linuxdeploy plugins
# - *Probably other things I didn't know linuxdeploy can do*
#
# It notably also does not copy unneeded libraries, unlike linuxdeploy. On a desktop system, this
# can help reduce the end AppImage's size, although in a production system this script proved
# unhelpful.
#~ set -x
export _PREFIX="/usr"
export _LIB_DIRS="lib64 lib"
export _QT_PLUGIN_PATH="${_PREFIX}/lib64/qt5/plugins"
export _EXCLUDES="ld-linux.so.2 ld-linux-x86-64.so.2 libanl.so.1 libBrokenLocale.so.1 libcidn.so.1 \
libc.so.6 libdl.so.2 libm.so.6 libmvec.so.1 libnss_compat.so.2 libnss_dns.so.2 libnss_files.so.2 \
libnss_hesiod.so.2 libnss_nisplus.so.2 libnss_nis.so.2 libpthread.so.0 libresolv.so.2 librt.so.1 \
libthread_db.so.1 libutil.so.1 libstdc++.so.6 libGL.so.1 libEGL.so.1 libGLdispatch.so.0 \
libGLX.so.0 libOpenGL.so.0 libdrm.so.2 libglapi.so.0 libgbm.so.1 libxcb.so.1 libX11.so.6 \
libasound.so.2 libfontconfig.so.1 libthai.so.0 libfreetype.so.6 libharfbuzz.so.0 libcom_err.so.2 \
libexpat.so.1 libgcc_s.so.1 libgpg-error.so.0 libICE.so.6 libp11-kit.so.0 libSM.so.6 \
libusb-1.0.so.0 libuuid.so.1 libz.so.1 libpangoft2-1.0.so.0 libpangocairo-1.0.so.0 \
libpango-1.0.so.0 libgpg-error.so.0 libjack.so.0 libxcb-dri3.so.0 libxcb-dri2.so.0 \
libfribidi.so.0 libgmp.so.10"

export _EXECUTABLE="$1"

# Get possible system library paths
export _SYSTEM_PATHS=$(echo -n $PATH | tr ":" " ")
export _SEARCH_PATHS=
for i in ${_LIB_DIRS}; do
  for j in ${_SYSTEM_PATHS}; do
    _TRY_PATH="$(readlink -e "$j/../$i" || true)"
    if [[ -n "${_TRY_PATH}" ]]; then
      _SEARCH_PATHS="${_SEARCH_PATHS} ${_TRY_PATH}"
    fi
  done
done
_SEARCH_PATHS="${_SEARCH_PATHS} $(patchelf --print-rpath $_EXECUTABLE | tr ':' ' ')"
# Get a list of only unique ones
_SEARCH_PATHS=$(echo -n "${_SEARCH_PATHS}" | sed 's/ /\n/g' | sort -u)

# find_library [library]
#  Finds the full path of partial name [library] in _SEARCH_PATHS
#  This is a time-consuming function.
_NOT_FOUND=""
function find_library {
  local _PATH=""
  for i in ${_SEARCH_PATHS}; do
    _PATH=$(find $i -regex ".*$(echo -n $1 | tr '+' '.')" -print -quit)
    if [ "$_PATH" != "" ]; then
      break
    fi
  done
  if [ "$_PATH" != "" ]; then
    echo -n $(readlink -e $_PATH)
  fi
}

# get_dep_names [object]
#  Returns a space-separated list of all required libraries needed by [object].
function get_dep_names {
  echo -n $(patchelf --print-needed $1)
}

# get_deps [object] [library_path]
#  Finds and installs all libraries required by [object] to [library_path].
#  This is a recursive function that also depends on find_library.
function get_deps {
  local _DEST=$2
  for i in $(get_dep_names $1); do
    _EXCL=`echo "$_EXCLUDES" | tr ' ' '\n' | grep $i`
    if [ "$_EXCL" != "" ]; then
      #>&2 echo "$i is on the exclude list... skipping"
      continue
    fi
    if [ -f $_DEST/$i ]; then
      continue
    fi
    local _LIB=$(find_library $i)
    if [ -z $_LIB ]; then
      echo -n "$i:"
      continue
    fi
    >&2 cp -v $_LIB $_DEST/$i &
    get_deps $_LIB $_DEST
  done
}

export -f get_deps
export -f get_dep_names
export -f find_library

_ERROR=0
if [ -z "$_EXECUTABLE" ]; then
  _ERROR=1
fi

if [ "$_ERROR" -eq 1 ]; then
  >&2 echo "usage: $0 <executable> [AppDir]"
  exit 1
fi

LIB_DIR="$(readlink -m $(dirname $_EXECUTABLE)/../lib)"
mkdir -p $LIB_DIR
_NOT_FOUND=$(get_deps $_EXECUTABLE $LIB_DIR)

if [ "${DEPLOY_QT}" == "1" ]; then
  # Find Qt path from search paths
  for i in ${_SEARCH_PATHS}; do
    _QT_CORE_LIB=$(find ${i} -type f -regex '.*/libQt5Core\.so.*' | head -n 1)
    if [ -n "${_QT_CORE_LIB}" ]; then
      _QT_PATH=$(dirname ${_QT_CORE_LIB})/../
      break
    fi
  done
  
  _QT_PLUGIN_PATH=$(readlink -e $(find ${_QT_PATH} -type d -regex '.*/plugins/platforms' | head -n 1)/../)

  for i in audio bearer imageformats mediaservice platforminputcontexts platformthemes xcbglintegrations platforms wayland-decoration-client wayland-graphics-integration-client wayland-graphics-integration-server wayland-shell-integration; do
    mkdir -p ${LIB_DIR}/../plugins/${i}
    cp -rnv ${_QT_PLUGIN_PATH}/${i}/*.so ${LIB_DIR}/../plugins/${i}
    find ${LIB_DIR}/../plugins/ -type f -regex '.*\.so' -exec patchelf --set-rpath '$ORIGIN/../../lib:$ORIGIN' {} ';'
    # Find any remaining libraries needed for Qt libraries
    _NOT_FOUND+=$(find ${LIB_DIR}/../plugins/${i} -type f -exec bash -c "get_deps {} $LIB_DIR" ';')
  done
  
  _QT_CONF=${LIB_DIR}/../bin/qt.conf
  echo "[Paths]" > ${_QT_CONF}
  echo "Prefix = ../" >> ${_QT_CONF}
  echo "Plugins = plugins" >> ${_QT_CONF}
  echo "Imports = qml" >> ${_QT_CONF}
  echo "Qml2Imports = qml" >> ${_QT_CONF}
fi

# Fix rpath of libraries and executable so they can find the packaged libraries
find ${LIB_DIR} -type f -exec patchelf --set-rpath '$ORIGIN' {} ';'
patchelf --set-rpath '$ORIGIN/../lib' $_EXECUTABLE

_APPDIR=$2
cd ${_APPDIR}

cp -nvs $(find -type f -regex '.*/icons/.*\.svg' || head -n 1) ./
cp -nvs $(find -type f -regex '.*/applications/.*\.desktop' || head -n 1) ./

if [ "${_NOT_FOUND}" != "" ]; then
  >&2 echo "WARNING: failed to find the following libraries:"
  >&2 echo "$(echo -n $_NOT_FOUND | tr ':' '\n' | sort -u)"
fi
