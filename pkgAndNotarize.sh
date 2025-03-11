#!/bin/zsh

# pkgAndNotarize.sh

# this script will
# - build the swift package project executable
# - sign the binary
# - create a signed pkg installer file
# - submit the pkg for notarization
# - staple the pkg

# more detail here:
# https://scriptingosx.com/2023/08/build-a-notarized-package-with-a-swift-package-manager-executable/

# by Armin Briegel - Scripting OS X

# Permission is granted to use this code in any way you want.
# Credit would be nice, but not obligatory.
# Provided "as is", without warranty of any kind, express or implied.


# modify these variables for your project

# Developer ID Installer cert name
developer_name_and_id="Armin Briegel (JME5BW3F3R)"
installer_sign_cert="Developer ID Installer: ${developer_name_and_id}"
application_sign_cert="Developer ID Application: ${developer_name_and_id}"

# profile name used with `notarytool --store-credentials`
credential_profile="notary-scriptingosx"

# build info
product_name="utiluti"
binary_names=( "utiluti" )

# pkg info
pkg_name="$product_name"
identifier="com.scriptingosx.${product_name}"
min_os_version="11.5"
install_location="/usr/local/bin/"


# don't modify below here


# calculated variables
SRCROOT=$(dirname ${0:A})
build_dir="$SRCROOT/.build"

date +"%F %T"

# build the binary

#swift package clean
echo
echo "### building $product_name"
if ! swift build --configuration release \
                 --arch arm64 --arch x86_64
then
    echo "error building binary"
    exit 2
fi

if [[ ! -d $build_dir ]]; then
    echo "couldn't find .build directory"
    exit 3
fi


binary_source_path="${build_dir}/apple/Products/Release/${binary_names[1]}"

if [[ ! -e $binary_source_path ]]; then
    echo "cannot find binary at $binary_source_path"
    exit 4
fi

# get version from binary
version=$($binary_source_path --version)

if [[ $version == "" ]]; then
    echo "could not get version"
    exit 5
fi

component_path="${build_dir}/${pkg_name}.pkg"
product_path="${build_dir}/${pkg_name}-${version}.pkg"
pkgroot="${build_dir}/pkgroot"

echo
echo "### Signing, Packaging and Notarizing '$product_name'"
echo "Version:         $version"
echo "Identifier:      $identifier"
echo "Min OS Version:  $min_os_version"
echo "Developer ID:    $developer_name_and_id"

pkgroot="$build_dir/pkgroot"
if [[ ! -d $pkgroot ]]; then
    mkdir -p $pkgroot
fi

for binary in ${binary_names}; do
  binary_source_path="${build_dir}/apple/Products/Release/${binary}"

  if [[ ! -f $binary_source_path ]]; then
      echo "can't find binary at $binary_path"
      exit 6
  fi

  cp $binary_source_path $pkgroot
  #scripts_dir="$SRCROOT/scripts"

  binary_path=$pkgroot/$binary

  # sign the binary
  echo
  echo "### signing '${binary}'"
  if ! codesign --sign $application_sign_cert \
           --options runtime \
           --runtime-version $min_os_version \
           --timestamp \
           $binary_path
  then
      echo "error signing binary '${binary}'"
      exit 7
  fi

done

# create the component pkg
echo
echo "### building component pkg file"

if ! pkgbuild --root $pkgroot \
         --identifier $identifier \
         --version $version-$build_number \
         --install-location $install_location \
         --min-os-version $min_os_version \
         --compression latest \
         $component_path

#         --scripts "$scripts_dir" \
then
  echo "error building component"
  exit 8
fi

# create the distribution pkg
echo
echo "### building distribution pkg file"

if ! productbuild --package "$component_path" \
                  --identifier "$identifier" \
                  --version "$version-$build_number" \
                  --sign "$installer_sign_cert" \
                  "$product_path"
then
  echo "error building distribution archive"
  exit 9
fi

# notarize
echo
echo "### submitting for notarization"
if ! xcrun notarytool submit "$product_path" \
                 --keychain-profile "$credential_profile" \
                 --wait
then
    echo "error notarizing pkg"
    echo "use 'xcrun notarylog <submission-id> --keychain-profile \"$credential_profile\"' for more detail"
    exit 10
fi

# staple
echo
echo "### staple"
if ! xcrun stapler staple "$product_path"
then
    echo "error stapling pkg"
    exit 11
fi

# clean up component pkg
rm "$component_path"

# clean up pkgroot
rm -rf $pkgroot

echo
# show result path
echo "### complete"
echo "$product_path"

exit 0
