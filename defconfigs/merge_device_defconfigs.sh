#!/bin/sh
# Merge hybris.config with device defconfig

appname=${0##*/}
appdir=$(realpath "$0")
appdir=${appdir%/*}
version_defaults=$ANDROID_ROOT/build/core/version_defaults.mk

usage()
{
    cat <<EOF
$appname - help
usage: $appname -t <kernel_tree> -d <device defconfig> [-v <version_major>]

-t       Kernel tree
-d       Device defconfig
-v       Android major version
EOF
}

args=t:d:hv:
while getopts $args arg ; do
    case $arg in
        t) kernel_tree="$OPTARG";;
        d) device_defconfig="$OPTARG" ;;
        v) android_version_major="$OPTARG" ;;
        h|?) usage ;;
    esac
done

shift $(( OPTIND - 1 ))


kernel_tree="$(realpath "$kernel_tree")"

# check if android source exists
if [ ! -e "$ANDROID_ROOT" ]; then
    echo "Cannot merge device defconfig: '$ANDROID_ROOT' does not exist." >&2
    exit 1
fi

if [ -z "$PORT_ARCH" ] ; then
    # shellcheck disable=2016
    # Note: We wan't show the variable name with the $ in front.
    echo 'Error $PORT_ARCH not defined' >&2
    exit 1
else
    # Map PORT_ARCH naming to kernel naming scheme
    case "$PORT_ARCH" in
        aarch64) PORT_ARCH=arm64 ;;
        arm7*|arm8*) PORT_ARCH=arm ;;
    esac
fi

# In case one of the version number is missing,
# try to extract if from the version_defaults.mk
if [ -z "$android_version_major" ]; then

    if [ ! -f "$version_defaults" ]; then
        echo "$version_defaults not found" >&2
        exit 1
    fi

    IFS="." read -r android_version_major <<EOF
$(IFS="." awk '/PLATFORM_VERSION[A-Z0-9.]* := ([0-9.]+)/ { print $3; }' < "$version_defaults")
EOF
fi


# Extract VERSION and PATCHLEVEL from kernel
version=$(grep -E '^VERSION\ =\ .*' "$kernel_tree"/Makefile |sed -e 's/VERSION \=\ //')
patchlevel=$(grep -E '^PATCHLEVEL\ =\ .*' "$kernel_tree"/Makefile |sed -e 's/PATCHLEVEL \=\ //')


cd "$appdir" || exit 1

./merge_config_fragment.sh \
    $android_version_major/$version.$patchlevel/hybris.config > "$kernel_tree"/hybris.config

cd "$kernel_tree" || exit 1




ARCH="$PORT_ARCH" ./scripts/kconfig/merge_config.sh -m\
    arch/$PORT_ARCH/configs/${device_defconfig}_defconfig \
    hybris.config

make ARCH=$PORT_ARCH savedefconfig
mv defconfig ./arch/$PORT_ARCH/configs/${device_defconfig}_defconfig
make mrproper
