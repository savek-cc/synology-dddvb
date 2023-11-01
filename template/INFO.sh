#!/bin/bash
source /pkgscripts-ng/include/pkg_util.sh

package="DigitalDevices DVB Drivers"
version="$DD_DVB_VERSION"
displayname="DD DVB"
os_min_ver="OS_MIN_VER"
maintainer="Timm Korte"
arch="$(pkg_get_platform)"
description="Adds DigitalDevices DVB cards support for your Synology NAS."
[ "$(caller)" != "0 NULL" ] && return 0
pkg_dump_info
