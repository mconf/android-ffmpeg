#!/bin/bash

# using the unofficial Crystax NDK
NDK_DIR=~/Codes/android-ndk-r4-crystax
PREBUILT=$NDK_DIR/build/prebuilt/linux-x86/arm-eabi-4.4.0
PLATFORM=$NDK_DIR/build/platforms/android-8/arch-arm

# if you prefer to use the official Android NDK, uncomment the following commands
#NDK_DIR=~/Codes/android-ndk-r6b
#PREBUILT=$NDK_DIR/toolchains/arm-eabi-4.4.0/prebuilt/linux-x86
#PLATFORM=$NDK_DIR/platforms/android-8/arch-arm

#cp $PLATFORM/../../android-3/arch-arm/usr/include/linux/errno.h $PLATFORM/usr/include/linux/
#cp $PLATFORM/../../android-3/arch-arm/usr/include/linux/posix_types.h $PLATFORM/usr/include/linux/
#cp $PLATFORM/../../android-3/arch-arm/usr/include/linux/limits.h $PLATFORM/usr/include/linux/
#cp $PLATFORM/../../android-3/arch-arm/usr/include/linux/stddef.h $PLATFORM/usr/include/linux/
#cp $PLATFORM/../../android-3/arch-arm/usr/include/linux/fcntl.h $PLATFORM/usr/include/linux/
#cp $PLATFORM/../../android-3/arch-arm/usr/include/linux/capability.h $PLATFORM/usr/include/linux/
#cp $PLATFORM/../../android-3/arch-arm/usr/include/linux/stat.h $PLATFORM/usr/include/linux/
#cp $PLATFORM/../../android-3/arch-arm/usr/include/linux/sockios.h $PLATFORM/usr/include/linux/
#cp $PLATFORM/../../android-3/arch-arm/usr/include/linux/in.h $PLATFORM/usr/include/linux/
#cp $PLATFORM/../../android-3/arch-arm/usr/include/linux/in6.h $PLATFORM/usr/include/linux/

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

	# point corrections
	if [ $1 = 'libavcodec' ];
	then
		echo 'libavcodec/rawdec.c' >> ../$1_source.tmp
	fi

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
			mkdir -p `dirname ../ffmpeg_headers/$filename`
			cp $filename ../ffmpeg_headers/$filename > /dev/null 2>&1
		fi
	done
}

clean
cd jni/ffmpeg

./configure --target-os=linux \
	--disable-everything \
	--disable-postproc \
	--disable-avfilter \
	--disable-network \
	--disable-ffmpeg \
	--disable-ffprobe \
	--arch=arm \
	--enable-version3 \
	--enable-gpl \
	--enable-nonfree \
	--enable-cross-compile \
	--enable-encoder=flv \
	--enable-decoder=flv \
	--cc=$PREBUILT/bin/arm-eabi-gcc \
	--cross-prefix=$PREBUILT/bin/arm-eabi- \
	--nm=$PREBUILT/bin/arm-eabi-nm \
	--extra-cflags="-fPIC -DANDROID -I$PLATFORM/usr/include" \
	--enable-armv5te \
	--extra-ldflags="-Wl,-T,$PREBUILT/arm-eabi/lib/ldscripts/armelf.x -Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib -nostdlib $PREBUILT/lib/gcc/arm-eabi/4.4.0/crtbegin.o $PREBUILT/lib/gcc/arm-eabi/4.4.0/crtend.o -lc -lm -ldl" \
	--logfile=../configure.log

rm -rf ../built_headers
mkdir ../built_headers

list_files 'libavutil'
list_files 'libavcodec'
list_files 'libavformat'
list_files 'libswscale'

cd ../..

$NDK_DIR/ndk-build clean
$NDK_DIR/ndk-build -j 8
clean