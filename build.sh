#!/bin/bash

NDK_DIR=~/Codes/android-ndk-r6b

if [ ! -d "$NDK_DIR" ]; then
	echo "Please set correctly your Android Native Development Kit path"
	echo "Current path: $NDK_DIR"
	return
fi

if [ `cat $NDK_DIR/RELEASE.TXT | grep 'r6b' | wc -l` -eq 0 ]; then
	echo "This script is prepared to compile FFmpeg using the NDK version r6b"
	echo "Please download the right version of NDK"
	return
fi

PREBUILT=$NDK_DIR/toolchains/arm-linux-androideabi-4.4.3/prebuilt/linux-x86
PLATFORM=$NDK_DIR/platforms/android-8/arch-arm

clean() {
	rm -f jni/*.tmp
	rm -f jni/*_files.mk
}

list_files() {
	rm -f ../$1_source.tmp

	# run a fake make
	make --dry-run | \
	# select the just the files from the wanted library
	egrep -i "$1/" | \
	# select all the occurrences of .c and .S filenames
	grep "[^ ]*\.[cS]" -o | \
	# put the result on .mk file
	sort >> ../$1_source.tmp

	echo 'LOCAL_SRC_FILES := \' > ../$1_files.mk
	cat ../$1_source.tmp | \
	# put a \ at the end of each line
	sed -e 's:$: \\:g' >> ../$1_files.mk

	cat ../$1_source.tmp > ../base.tmp
	rm -f ../$1_header.tmp; touch ../$1_header.tmp

	while [ `cat ../base.tmp | wc -l` -gt 0 ]
	do
		rm -f ../include.tmp

		for filename in `cat ../base.tmp`
		do
			if [ -e $filename ]
			then
				folder=`dirname $filename`
				cat $filename | \
				# keeps the lines with #include "<anything>"
#				grep '^#include "[^"]*"' | \
				grep '^#include "[^"]*"' >> ../include.tmp
				# keeps only the header name
#				sed -e 's:\([^"]*\)\"\([^"]*\)\".*:\2:' | \
				# include the folder name (in case it is not already there)
#				sed -e "/^lib/!s/.*/\0\n$folder\/\0/g" >> ../include.tmp
			fi
		done
		# keeps only the header name
		sed -i 's:\([^"]*\)\"\([^"]*\)\".*:\2:' ../include.tmp 
		# include the folder name (in case it is not already there)
		sed -i "/^lib/!s/.*/\0\n$folder\/\0/g" ../include.tmp 

		rm -f ../base.tmp; touch ../base.tmp
		for filename in `cat ../include.tmp`
		do
			if [ -e $filename ]
			then
				if [ `cat ../$1_header.tmp | grep "$filename" | wc -l` -eq 0 ]
				then
					echo $filename >> ../$1_header.tmp
					echo $filename >> ../base.tmp
				fi
			fi
		done
	done

	# copy all the headers to a specific folder
	for filename in `cat ../$1_header.tmp`
	do
		if [ -e $filename ]
		then
			mkdir -p `dirname ../built_headers/$filename`
			cp $filename ../built_headers/$filename > /dev/null 2>&1
		fi
	done
}

clean
cd jni/ffmpeg

./configure --target-os=linux \
	--disable-ffmpeg \
	--disable-ffprobe \
	--arch=arm \
	--enable-version3 \
	--enable-gpl \
	--enable-nonfree \
	--enable-cross-compile \
	--cc=$PREBUILT/bin/arm-linux-androideabi-gcc \
	--cross-prefix=$PREBUILT/bin/arm-linux-androideabi- \
	--nm=$PREBUILT/bin/arm-linux-androideabi-nm \
	--extra-cflags="-fPIC -DANDROID -I$PLATFORM/usr/include" \
	--enable-armv5te \
	--extra-ldflags="-Wl,-T,$PREBUILT/arm-linux-androideabi/lib/ldscripts/armelf_linux_eabi.x -Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib -nostdlib $PREBUILT/lib/gcc/arm-linux-androideabi/4.4.3/crtbegin.o $PREBUILT/lib/gcc/arm-linux-androideabi/4.4.3/crtend.o -lc -lm -ldl" \
	--logfile=../configure.log

rm -rf ../built_headers
mkdir ../built_headers

list_files 'libavutil'
list_files 'libavcodec'
list_files 'libavformat'
list_files 'libswscale'
#list_files 'libavdevice'
#list_files 'libpostproc'
#list_files 'libavfilter'

cd ../..

$NDK_DIR/ndk-build clean
$NDK_DIR/ndk-build -j 8
clean