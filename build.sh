#!/bin/bash

#############################################################################
# Utils script for building FlipFont package
# Usage:
#    sh build.sh path-to-ttf-font "Display of the font"
#
# Author: Xupeng Yun <xupeng@xupeng.me>
# Created at: 2013-01-03
#############################################################################

APK_TEMPLATE="apk-template"
PKG_NAME_STUB="FLIPFONT_PACKAGE_STUB"
FONT_NAME_STUB="FLIPFONT_FONT_NAME_STUB"
FONT_DISPLAY_NAME_STUB="FLIPFONT_DISPLAY_NAME_STUB"

ttffont=$1
display_name=$2

if [ -z "${ttffont}" -o -z "$display_name" ]; then
    echo "Usage: $0 path-to-ttf-font \"Display of the font\""
    exit 1
fi

# name the Java package after the normalized font name
font_name=`echo ${ttffont##*/} | cut -d. -f1`
pkg_name=`echo ${font_name} | sed -e 's/[^a-zA-Z0-9]//g' | tr 'A-Z' 'a-z'`

# set up the build directory from the APK template
build_dir="build/${font_name}"
[ -d ${build_dir} ] && rm -rf ${build_dir}
mkdir -p build && cp -rf ${APK_TEMPLATE} ${build_dir}

# set the Java package name
sed -i -e "s/${PKG_NAME_STUB}/${pkg_name}/g" ${build_dir}/AndroidManifest.xml

# copy the TTF font
cp ${ttffont} ${build_dir}/assets/fonts/${pkg_name}.ttf

# process the font configuration XML
mv ${build_dir}/assets/xml/${PKG_NAME_STUB}.xml ${build_dir}/assets/xml/${pkg_name}.xml
sed -i -e "s/${FONT_NAME_STUB}/${pkg_name}.ttf/g" ${build_dir}/assets/xml/${pkg_name}.xml
sed -i -e "s/${FONT_DISPLAY_NAME_STUB}/${display_name}/g" ${build_dir}/assets/xml/${pkg_name}.xml

# set up the Java package
mv ${build_dir}/smali/com/monotype/android/font/FLIPFONT_PACKAGE_STUB ${build_dir}/smali/com/monotype/android/font/${pkg_name}
sed -i -e "s/${PKG_NAME_STUB}/${pkg_name}/g" ${build_dir}/smali/com/monotype/android/font/${pkg_name}/*

# set the font's display name (which will be displayed in the phone)
sed -i -e "s/${FONT_DISPLAY_NAME_STUB}/${display_name}/g" ${build_dir}/res/values/strings.xml

# build the APK package
java -jar utils/apktool.jar b ${build_dir} ${build_dir}.apk
# sign the package
java -jar utils/signapk.jar utils/certificate.pem utils/key.pk8 ${build_dir}.apk ${build_dir}_signed.apk
