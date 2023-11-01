#!/bin/bash
if [ -z ${IS_IN_CONTAINER+x} ]; then
    echo "This script expect to be run inside a docker container" 1>&2
    exit 1
fi

if [ -z ${PACKAGE_ARCH+x} ]; then
    echo "PACKAGE_ARCH is undefined. Please find and set you package arch:" 1>&2
    echo "https://www.synology.com/en-global/knowledgebase/DSM/tutorial/Compatibility_Peripherals/What_kind_of_CPU_does_my_NAS_have" 1>&2
    exit 2
fi

if [ -z ${DSM_VER+x} ]; then
    echo "DSM_VER is undefined. This should a version number like 6.2" 1>&2
    exit 3
fi

# Ensure that we are working directly in the root file system. Though this
# should always be the case in containers.
cd /

# Make the script quit if there are errors
set -e

export DD_DVB_VERSION=$(wget -q --header "accept:application/json" "https://github.com/DigitalDevices/dddvb/refs?type=tag" -O - | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)

echo "DD DVB version: $DD_DVB_VERSION"
echo

# Fetch Synology toolchain
if [[ ! -d /pkgscripts-ng ]] || [ -z "$(ls -A /pkgscripts-ng)" ]; then
    clone_args=""
    # If the DSM version is 7.2+, use the DSM7.2 branch of pkgscripts-ng
    if [[ "$DSM_VER" =~ ^7\.[2-9]+$ ]]; then
        clone_args="-b DSM7.2"
        export PRODUCT="DSM"
    # If the DSM version is 7.0, use the DSM7.0 branch of pkgscripts-ng
    elif [[ "$DSM_VER" =~ ^7\.[0-1]+$ ]]; then
        clone_args="-b DSM7.0"
        export PRODUCT="DSM"
    fi
    git clone ${clone_args} https://github.com/SynologyOpenSource/pkgscripts-ng
else
    echo "Existing pkgscripts-ng repo found. Pulling latest from origin."
    cd /pkgscripts-ng
    git pull origin
    cd /
fi

# Configure the package according to the DSM version
if [[ "$DSM_VER" =~ ^7\.[0-9]+$ ]]; then
    os_min_ver="7.0-40000"
    pkgscripts_args=""

    # Synology has added a strict requirement on DSM 7.0 to prevent packages
    # not signed by Synology from running with root privileges.
    # Change the permission to run the package to lower in order
    # to successfully install the package.
    run_as="package"
else
    os_min_ver="6.0-5941"
    run_as="root"
    pkgscripts_args="-S"
fi

package_dir=`dirname $0`
cp -p "$package_dir/template/INFO.sh" "$package_dir/INFO.sh" && sed -i "s/OS_MIN_VER/$os_min_ver/" "$package_dir/INFO.sh"
cp -p "$package_dir/template/conf/privilege" "$package_dir/conf/privilege" && sed -i "s/RUN_AS/$run_as/" "$package_dir/conf/privilege"
cp -p "$package_dir/template/SynoBuildConf/depends" "$package_dir/SynoBuildConf/depends" && sed -i "s/DSM_VER/$DSM_VER/" "$package_dir/SynoBuildConf/depends"

# Install the toolchain for the given package arch and DSM version
build_env="/build_env/ds.$PACKAGE_ARCH-$DSM_VER"

if [ ! -d "$build_env" ]; then
    if [ -f "/toolkit_tarballs/base_env-$DSM_VER.txz" ] && [ -f "/toolkit_tarballs/ds.$PACKAGE_ARCH-$DSM_VER.env.txz" ] && [ -f "/toolkit_tarballs/ds.$PACKAGE_ARCH-$DSM_VER.dev.txz" ]; then
        pkgscripts-ng/EnvDeploy -p $PACKAGE_ARCH -v $DSM_VER -t /toolkit_tarballs
    else
        pkgscripts-ng/EnvDeploy -p $PACKAGE_ARCH -v $DSM_VER
    fi

    # Ensure the installed toolchain has support for CA signed certificates.
    # Without this wget on https:// will fail
    cp /etc/ssl/certs/ca-certificates.crt "$build_env/etc/ssl/certs/"
    
    # Add patched version of DST Root CA X3 certificate
    wget -O DSTRootCAX3_Extended.crt "https://crt.sh/?d=8395"
    sed -i "s/xMDkzMDE0MDExNVow/0MDkzMDE4MTQwM1ow/g" DSTRootCAX3_Extended.crt
    cat DSTRootCAX3_Extended.crt >> "$build_env/etc/ssl/certs/ca-certificates.crt"
fi

# Disable quit if errors to allow printing of logfiles
set +e

# Build packages
#   -p              package arch
#   -v              DSM version
#   -S              no signing
#   --build-opt=-J  prevent parallel building (required)
#   --print-log     save build logs
#   -c dddvb    project path in /source
pkgscripts-ng/PkgCreate.py \
    -p $PACKAGE_ARCH \
    -v $DSM_VER \
    ${pkgscripts_args} \
    --build-opt=-J \
    --print-log \
    -c dddvb

# Save package builder exit code. This allows us to print the logfiles and give
# a non-zero exit code on errors.
pkg_status=$?

# Clean up the build environment
rm "$package_dir/INFO.sh" "$package_dir/conf/privilege" "$package_dir/SynoBuildConf/depends"

echo "Build log"
echo "========="
cat "$build_env/logs.build"
echo

echo "Install log"
echo "==========="
cat "$build_env/logs.install"
echo

exit $pkg_status
