#!/sbin/sh

sed -i /timaversion/d /system/build.prop
sed -i /security.mdpp.mass/d /system/build.prop
sed -i /ro.hardware.keystore/d /system/build.prop
rm -rf /system/app/TuiService /system/app/mcRegistry /system/*info*

