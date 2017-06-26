#!/bin/bash
# kernel build script by Tkkg1994 v0.4 (optimized from apq8084 kernel source)
# Modified by djb77 / XDA Developers

# ---------
# VARIABLES
# ---------
BUILD_SCRIPT=3.00
export VERSION_NUMBER=$(<build/version)
ARCH=arm64
BUILD_CROSS_COMPILE=~/android/toolchains/aarch64-cortex_a53-linux-gnueabi/bin/aarch64-cortex_a53-linux-gnueabi-
BUILD_JOB_NUMBER=`grep processor /proc/cpuinfo|wc -l`
RDIR=$(pwd)
OUTDIR=$RDIR/.work/arch/$ARCH/boot
DTSDIR=$RDIR/.work/arch/$ARCH/boot/dts
DTBDIR=$RDIR/.work/arch/$ARCH/boot/dtb
DTCTOOL=$RDIR/.work/scripts/dtc/dtc
INCDIR=$RDIR/.work/include
PAGE_SIZE=2048
DTB_PADDING=0
KERNELNAME=TGPKernel
KERNELCONFIG=tgpkernel
ZIP_FILE_DIR=$RDIR/.work_zip/base

# ---------
# FUNCTIONS
# ---------
FUNC_CLEAN()
{
echo ""
echo "Deleting old work files ..."
echo ""
rm -rf $RDIR/.work
rm -f $RDIR/output/build.log
}

FUNC_BUILD_ZIMAGE()
{
echo "Copying Files ..."
echo ""
mkdir -p $RDIR/.work/arch
mkdir -p $RDIR/.work/firmware
mkdir -p $RDIR/.work/include
mkdir -p $RDIR/.work/ramdisk
mkdir -p $RDIR/.work/scripts
cp -rf $RDIR/arch/arm/ $RDIR/.work/arch/
cp -rf $RDIR/arch/arm64/ $RDIR/.work/arch/
cp -rf $RDIR/arch/x86 $RDIR/.work/arch/
cp -rf $RDIR/firmware $RDIR/.work/
cp -rf $RDIR/include $RDIR/.work/
cp -rf $RDIR/build/ramdisk $RDIR/.work/
cp -rf $RDIR/build/aik/* $RDIR/.work/ramdisk 
cp -rf $RDIR/scripts $RDIR/.work/
cd $RDIR/.work
find . -name \.placeholder -type f -delete
cd ..
echo "Loading configuration ..."
echo ""
make -C $RDIR O=.work -s -j$BUILD_JOB_NUMBER ARCH=$ARCH \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE \
	$KERNEL_DEFCONFIG || exit -1
echo ""
echo "Compiling zImage ..."
echo ""
make -C $RDIR O=.work -s -j$BUILD_JOB_NUMBER ARCH=$ARCH \
	CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1
echo ""
}

FUNC_BUILD_DTB()
{
[ -f "$DTCTOOL" ] || {
	echo "You need to run ./build.sh first!"
	exit 1
}
case $MODEL in
herolte)
	DTSFILES="exynos8890-herolte_eur_open_00 exynos8890-herolte_eur_open_01
		exynos8890-herolte_eur_open_02 exynos8890-herolte_eur_open_03
		exynos8890-herolte_eur_open_04 exynos8890-herolte_eur_open_08
		exynos8890-herolte_eur_open_09"
	;;
hero2lte)
	DTSFILES="exynos8890-hero2lte_eur_open_00 exynos8890-hero2lte_eur_open_01
		exynos8890-hero2lte_eur_open_03 exynos8890-hero2lte_eur_open_04
		exynos8890-hero2lte_eur_open_08"
	;;
*)
	echo "Unknown device: $MODEL"
	exit 1
	;;
esac
mkdir -p $OUTDIR $DTBDIR
cd $DTBDIR || {
	echo "Unable to cd to $DTBDIR!"
	exit 1
}
rm -f ./*
echo ""
echo "Processing DTS files ..."
echo ""
for dts in $DTSFILES; do
	echo "Processing: ${dts}.dts"
	${CROSS_COMPILE}cpp -nostdinc -undef -x assembler-with-cpp -I "$INCDIR" "$DTSDIR/${dts}.dts" > "${dts}.dts"
	echo "Generating: ${dts}.dtb"
	$DTCTOOL -p $DTB_PADDING -i "$DTSDIR" -O dtb -o "${dts}.dtb" "${dts}.dts"
done
echo ""
echo "Generating dtb.img"
echo ""
$RDIR/.work/scripts/dtbTool/dtbTool -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE
}

FUNC_BUILD_RAMDISK()
{
mkdir $RDIR/.work/ramdisk/ramdisk/config
chmod 500 $RDIR/.work/ramdisk/ramdisk/config
mv $RDIR/.work/arch/$ARCH/boot/Image $RDIR/.work/ramdisk/split_img/boot.img-zImage
mv $RDIR/.work/arch/$ARCH/boot/dtb.img $RDIR/.work/ramdisk/split_img/boot.img-dtb
case $MODEL in
herolte)
	sed -i -- 's/G935/G930/g' $RDIR/.work/ramdisk/ramdisk/default.prop
	sed -i -- 's/SRPOI30A000KU/SRPOI17A000KU/g' $RDIR/.work/ramdisk/split_img/boot.img-board
	cd $RDIR/.work/ramdisk
	./repackimg.sh
	echo SEANDROIDENFORCE >> image-new.img
	;;
hero2lte)
	cd $RDIR/.work/ramdisk
	./repackimg.sh
	echo SEANDROIDENFORCE >> image-new.img
	;;
*)
	echo "Unknown device: $MODEL"
	exit 1
	;;
esac
}

FUNC_BUILD_BOOTIMG()
{
	FUNC_CLEAN
	[ ! -d "$RDIR/output" ] && mkdir output
	(
	FUNC_BUILD_ZIMAGE
	FUNC_BUILD_DTB
	FUNC_BUILD_RAMDISK
	) 2>&1	 | tee -a $RDIR/output/build.log
}

FUNC_BUILD_ZIP()
{
echo ""
echo "Building Zip File ..."
cd $ZIP_FILE_DIR
zip -gq $ZIP_NAME -r META-INF/ -x "*~"
zip -gq $ZIP_NAME -r system/ -x "*~" 
[ -f "$RDIR/.work_zip/base/boot.img" ] && zip -gq $ZIP_NAME boot.img -x "*~"
[ -f "$RDIR/.work_zip/base/boot.img" ] && zip -gq $ZIP_NAME boot.img -x "*~"
[ -f "$RDIR/.work_zip/base/g930x.img" ] && zip -gq $ZIP_NAME g930x.img -x "*~"
[ -f "$RDIR/.work_zip/base/g935x.img" ] && zip -gq $ZIP_NAME g935x.img -x "*~"
if [ -n `which java` ]; then
	echo "Java Detected, Signing Zip File"
	mv $ZIP_NAME old$ZIP_NAME
	java -Xmx1024m -jar $RDIR/build/signapk/signapk.jar -w $RDIR/build/signapk/testkey.x509.pem $RDIR/build/signapk/testkey.pk8 old$ZIP_NAME $ZIP_NAME
	rm old$ZIP_NAME
fi
chmod a+r $ZIP_NAME
mv -f $ZIP_FILE_TARGET $RDIR/output/$ZIP_NAME
cd $RDIR
}

OPTION_1()
{
MODEL=herolte
KERNEL_DEFCONFIG=$KERNELCONFIG-herolte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/output/build.log
mv -f $RDIR/.work/ramdisk/image-new.img $RDIR/output/boot.img
mv -f $RDIR/output/build.log $RDIR/output/build-g930f.log
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your boot.img in the output folder"
echo "You can now find your build-g930f.log file in the output folder"
echo ""
exit
}

OPTION_2()
{
MODEL=hero2lte
KERNEL_DEFCONFIG=$KERNELCONFIG-hero2lte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/output/build.log
mv -f $RDIR/.work/ramdisk/image-new.img $RDIR/output/boot.img
mv -f $RDIR/output/build.log $RDIR/output/build-g935f.log
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your boot.img in the output folder"
echo "You can now find your build-g935f.log file in the output folder"
echo ""
exit
}

OPTION_3()
{
MODEL=herolte
KERNEL_DEFCONFIG=$KERNELCONFIG-herolte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/output/build.log
mv -f $RDIR/.work/ramdisk/image-new.img $RDIR/output/g930f.img
mv -f $RDIR/output/build.log $RDIR/output/build-g930f.log
MODEL=hero2lte
KERNEL_DEFCONFIG=$KERNELCONFIG-hero2lte_defconfig
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/output/build.log
mv -f $RDIR/.work/ramdisk/image-new.img $RDIR/output/g935f.img
mv -f $RDIR/output/build.log $RDIR/output/build-g935f.log
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your g930f.img in the output folder"
echo "You can now find your g935f.img in the output folder"
echo "You can now find your build-g930f.log file in the output folder"
echo "You can now find your build-g935f.log file in the output folder"
echo ""
exit
}

OPTION_4()
{
[ -d "$RDIR/.work_zip" ] && rm -rf $RDIR/.work_zip
[ ! -d "$RDIR/.work_zip" ] && mkdir $RDIR/.work_zip
cp -rf $RDIR/build/zip/base $RDIR/.work_zip/
cp -rf $RDIR/build/zip/g930x/* $RDIR/.work_zip/base
MODEL=herolte
KERNEL_DEFCONFIG=$KERNELCONFIG-herolte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/output/build.log
mv -f $RDIR/.work/ramdisk/image-new.img $RDIR/.work_zip/base/boot.img
mv -f $RDIR/output/build.log $RDIR/output/build-g930f.log
ZIP_DATE=`date +%Y%m%d`
ZIP_NAME=$KERNELNAME.G930x.MM.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
[ -d "$RDIR/.work_zip" ] && rm -rf $RDIR/.work_zip
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip file in the output folder"
echo "You can now find your build-g930f.log file in the output folder"
echo ""
exit
}

OPTION_5()
{
[ -d "$RDIR/.work_zip" ] && rm -rf $RDIR/.work_zip
[ ! -d "$RDIR/.work_zip" ] && mkdir $RDIR/.work_zip
cp -rf $RDIR/build/zip/base $RDIR/.work_zip/
cp -rf $RDIR/build/zip/g935x/* $RDIR/.work_zip/base
MODEL=hero2lte
KERNEL_DEFCONFIG=$KERNELCONFIG-hero2lte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/output/build.log
mv -f $RDIR/.work/ramdisk/image-new.img $RDIR/.work_zip/base/boot.img
mv -f $RDIR/output/build.log $RDIR/build/build-g935f.log
ZIP_DATE=`date +%Y%m%d`
ZIP_NAME=$KERNELNAME.G935x.MM.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
[ -d "$RDIR/.work_zip" ] && rm -rf $RDIR/.work_zip
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip file in the output folder"
echo "You can now find your build-g935f.log file in the output folder"
echo ""
exit
}

OPTION_6()
{
[ -d "$RDIR/.work_zip" ] && rm -rf $RDIR/.work_zip
[ ! -d "$RDIR/.work_zip" ] && mkdir $RDIR/.work_zip
cp -rf $RDIR/build/zip/base $RDIR/.work_zip/
cp -rf $RDIR/build/zip/g930x/* $RDIR/.work_zip/base
MODEL=herolte
KERNEL_DEFCONFIG=$KERNELCONFIG-herolte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/output/build.log
mv -f $RDIR/.work/ramdisk/image-new.img $RDIR/.work_zip/base/boot.img
mv -f $RDIR/output/build.log $RDIR/output/build-g930f.log
ZIP_DATE=`date +%Y%m%d`
ZIP_NAME=$KERNELNAME.G930x.MM.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
[ -d "$RDIR/.work_zip" ] && rm -rf $RDIR/.work_zip
[ ! -d "$RDIR/.work_zip" ] && mkdir $RDIR/.work_zip
cp -rf $RDIR/build/zip/base $RDIR/.work_zip/
cp -rf $RDIR/build/zip/g935x/* $RDIR/.work_zip/base
MODEL=hero2lte
KERNEL_DEFCONFIG=$KERNELCONFIG-hero2lte_defconfig
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/output/build.log
mv -f $RDIR/.work/ramdisk/image-new.img $RDIR/.work_zip/base/boot.img
mv -f $RDIR/output/build.log $RDIR/output/build-g935f.log
ZIP_NAME=$KERNELNAME.G935x.MM.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
[ -d "$RDIR/.work_zip" ] && rm -rf $RDIR/.work_zip
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip files in the output folder"
echo "You can now find your build-g930f.log file in the output folder"
echo "You can now find your build-g935f.log file in the output folder"
echo ""
exit
}

OPTION_7()
{
[ -d "$RDIR/.work_zip" ] && rm -rf $RDIR/.work_zip
[ ! -d "$RDIR/.work_zip" ] && mkdir $RDIR/.work_zip
cp -rf $RDIR/build/zip/base $RDIR/.work_zip/
cp -rf $RDIR/build/zip/g93xx/* $RDIR/.work_zip/base
MODEL=herolte
KERNEL_DEFCONFIG=$KERNELCONFIG-herolte_defconfig
START_TIME=`date +%s`
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/output/build.log
mv -f $RDIR/.work/ramdisk/image-new.img $RDIR/.work_zip/base/g930x.img
mv -f $RDIR/output/build.log $RDIR/output/build-g930f.log
MODEL=hero2lte
KERNEL_DEFCONFIG=$KERNELCONFIG-hero2lte_defconfig
	(
	FUNC_BUILD_BOOTIMG
	) 2>&1	 | tee -a $RDIR/output/build.log
mv -f $RDIR/.work/ramdisk/image-new.img $RDIR/.work_zip/base/g935x.img
mv -f $RDIR/output/build.log $RDIR/output/build-g935f.log
ZIP_DATE=`date +%Y%m%d`
ZIP_NAME=$KERNELNAME.G93xx.MM.v$VERSION_NUMBER.$ZIP_DATE.zip
ZIP_FILE_TARGET=$ZIP_FILE_DIR/$ZIP_NAME
FUNC_BUILD_ZIP
[ -d "$RDIR/.work_zip" ] && rm -rf $RDIR/.work_zip
END_TIME=`date +%s`
let "ELAPSED_TIME=$END_TIME-$START_TIME"
echo ""
echo "Total compiling time is $ELAPSED_TIME seconds"
echo ""
echo "You can now find your .zip file in the output folder"
echo "You can now find your build-g930f.log file in the output folder"
echo "You can now find your build-g935f.log file in the output folder"
echo ""
exit
}

OPTION_0()
{
FUNC_CLEAN
exit
}

OPTION_00()
{
ccache -C
exit
}

# ----------------------------------
# CHECK COMMAND LINE FOR ANY ENTRIES
# ----------------------------------
if [ $1 == 0 ]; then
	OPTION_0
fi
if [ $1 == 00 ]; then
	OPTION_00
fi
if [ $1 == 1 ]; then
	OPTION_1
fi
if [ $1 == 2 ]; then
	OPTION_2
fi
if [ $1 == 3 ]; then
	OPTION_3
fi
if [ $1 == 4 ]; then
	OPTION_4
fi
if [ $1 == 5 ]; then
	OPTION_5
fi
if [ $1 == 6 ]; then
	OPTION_6
fi
if [ $1 == 7 ]; then
	OPTION_7
fi

# -------------
# PROGRAM START
# -------------
clear
echo "TGPKernel S7 Build Script v$BUILD_SCRIPT -- Kernel Version: v$VERSION_NUMBER"
echo ""
echo " 0) Clean Workspace"
echo "00) Clean CCACHE"
echo ""
echo " 1) Build TGPKernel boot.img for S7"
echo " 2) Build TGPKernel boot.img for S7 Edge"
echo " 3) Build TGPKernel boot.img for S7 + S7 Edge"
echo " 4) Build TGPKernel boot.img and .zip for S7"
echo " 5) Build TGPKernel boot.img and .zip for S7 Edge"
echo " 6) Build TGPKernel boot.img and .zip for S7 + S7 Edge (Seperate)"
echo " 7) Build TGPKernel boot.img and .zip for S7 + S7 Edge (All-In-One)"
echo ""
echo " 9) Exit"
echo ""
read -p "Please select an option " prompt
echo ""
if [ $prompt == "0" ]; then
	OPTION_0
elif [ $prompt == "00" ]; then
	OPTION_00
elif [ $prompt == "1" ]; then
	OPTION_1
elif [ $prompt == "2" ]; then
	OPTION_2
elif [ $prompt == "3" ]; then
	OPTION_3
elif [ $prompt == "4" ]; then
	OPTION_4
elif [ $prompt == "5" ]; then
	OPTION_5
elif [ $prompt == "6" ]; then
	OPTION_6
elif [ $prompt == "7" ]; then
	OPTION_7
elif [ $prompt == "9" ]; then
	exit
fi

