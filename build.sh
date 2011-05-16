#!/bin/bash

NDK_DIR=~/codes/android-ndk-r4-crystax
PREBUILT=$NDK_DIR/build/prebuilt/linux-x86/arm-eabi-4.4.0
PLATFORM=$NDK_DIR/build/platforms/android-8/arch-arm

list_files() {
	echo 'LOCAL_SRC_FILES := \' > $1_files.mk

	# egrep -i removes the unnecessary source files
	find ffmpeg -name '*.c' -or -name '*.S' | egrep -i "$1/" | \
	# remove some architecture files, examples, table generators and stuff
	egrep -i 'test|template|_iwmmxt|_neon|_armv6|_vfp|avisynth.c|crystalhd.c|g729dec.c|tablegen.c|example|ac3enc_|fft_float.c|mdct_float.c|dxva2|alpha/|bfin/|mlib/|ppc/|ps2/|sh4/|sparc/|x86/' --invert-match | \
	# depends on external library
	egrep -i 'libcelt|libdirac|libfaac|libgsm|libmp3lame|libschroedinger|libopenjpeg|libspeex|libtheora|libvo-amrwb|libvo-aac|libxvid|libx264|libvorbis|libvpx|libxavs|libnut.c|librtmp.c|mpegvideo_xvmc|vaapi|vdpau|w32thread' --invert-match | \
	# depends on CONFIG_NETWORK
	egrep -i 'gopher.c|http.c|mmst.c|rtmp|rtp|rtsp|rdt|sapdec.c|sapenc.c|tcp|udp|mmsh.c' --invert-match | \
	# depends on CONFIG_MUXERS
	egrep -i 'asfdec.c|avidec.c|avienc.c|dxa.c|matroskadec.c|movenchint.c|nuv.c|wtvdec.c|xwma.c|movenc.c' --invert-match | \
	# sort and format file names
	sort | sed 's/ffmpeg\///' | sed 's/\.c/.c \\/' | sed 's/\.S/.S \\/' >> $1_files.mk
	# sed 's/ffmpeg\///' removes 'ffmpeg' from the file path
	# avisynth.c - includes windows.h
}

cd jni

list_files 'libavutil'
list_files 'libavcodec'
list_files 'libavformat'
list_files 'libswscale'

cd ffmpeg
./configure --help > ../configure.options
./configure --target-os=linux \
	--disable-everything \
	--arch=arm \
	--enable-version3 \
	--enable-gpl \
	--enable-nonfree \
	--enable-protocol=file \
	--enable-encoder=flv \
	--enable-decoder=flv \
	--enable-small \
	--enable-cross-compile \
	--cc=$PREBUILT/bin/arm-eabi-gcc \
	--cross-prefix=$PREBUILT/bin/arm-eabi- \
	--nm=$PREBUILT/bin/arm-eabi-nm \
	--extra-cflags="-fPIC -DANDROID" \
	--enable-armv5te \
	--extra-ldflags="-Wl,-T,$PREBUILT/arm-eabi/lib/ldscripts/armelf.x -Wl,-rpath-link=$PLATFORM/usr/lib -L$PLATFORM/usr/lib -nostdlib $PREBUILT/lib/gcc/arm-eabi/4.4.0/crtbegin.o $PREBUILT/lib/gcc/arm-eabi/4.4.0/crtend.o -lc -lm -ldl" \
	--logfile=../configure.log
cd ../..
$NDK_DIR/ndk-build clean
$NDK_DIR/ndk-build -j 8