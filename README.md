# TGPKernel S7

A Custom Kernel for Samsung Galaxy S7 / S7 Edge.

The main purpose of this Kernel is to have a stock-like Kernel that runs on S7 and S7E
variants, but capable of running S7E and S8 Port Firmwares.

* URL (S7 Forum): http://forum.xda-developers.com/showthread.php?t=3462897
* URL (S7 Edge Forum): http://forum.xda-developers.com/showthread.php?t=3501571


Compiled using my own built custom toolchain

* URL: https://github.com/djb77/aarch64-cortex_a53-linux-gnueabi

## How to use
- Adjust the toolchain path in build.sh and Makefile to match the path on your system. 
- Run build.sh and follow the prompts, alternatively you can use a command line:

-	./build.sh 0  will perform Clean Workspace
-	./build.sh 00 will perform Clean CCACHE
-	./build.sh 1  will perform Build TGPKernel boot.img for S7
-	./build.sh 2  will perform Build TGPKernel boot.img for S7 Edge
-	./build.sh 3  will perform Build TGPKernel boot.img for S7 + S7 Edge
-	./build.sh 4  will perform Build TGPKernel boot.img and .zip for S7
-	./build.sh 5  will perform Build TGPKernel boot.img and .zip for S7 Edge
-	./build.sh 6  will perform Build TGPKernel boot.img and .zip for S7 + S7 Edge (Seperate)
-	./build.sh 7  will perform Build TGPKernel boot.img and .zip for S7 + S7 Edge (All-In-One)

- When finished, the new .img or .zip file will be created in the output directory.
- If Java is installed, the .zip files will be automatically signed.


## Credit and Thanks to the following:
- Samsung Open Source Release Center for the Source code (http://opensource.samsung.com)
- The Linux Kernel Archive for the Linux Patches (https://www.kernel.org)
- @Tkkg1994 for all his help and numerous code samples from his source
- @osm0sis for Android Image Kitchen
- @jesec for the Fingerprint Fix for MM
- @arter97, @lyapota, @morogoku and others for their commits

