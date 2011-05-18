#this directory variable declaration
LOCAL_PATH := $(call my-dir)/ffmpeg

#swscale module
include $(CLEAR_VARS)
LOCAL_MODULE    := swscale
LOCAL_ARM_MODE := arm
LOCAL_CFLAGS := -DHAVE_AV_CONFIG_H
LOCAL_SHARED_LIBRARIES := avutil
LOCAL_LDFLAGS := 
include $(LOCAL_PATH)/../lib$(LOCAL_MODULE)_files.mk
include $(BUILD_SHARED_LIBRARY) 
#end of swscale module

#avutil module
include $(CLEAR_VARS)
LOCAL_MODULE := avutil
LOCAL_ARM_MODE := arm
LOCAL_CFLAGS := -DHAVE_AV_CONFIG_H
include $(LOCAL_PATH)/../lib$(LOCAL_MODULE)_files.mk
include $(BUILD_SHARED_LIBRARY)
#end of avutil module

#avformat module
include $(CLEAR_VARS)
LOCAL_MODULE := avformat
LOCAL_ARM_MODE := arm
LOCAL_CFLAGS := -DHAVE_AV_CONFIG_H
include $(LOCAL_PATH)/../lib$(LOCAL_MODULE)_files.mk
LOCAL_SHARED_LIBRARIES := avutil avcodec
LOCAL_LDFLAGS := -L$(SYSROOT)/usr/lib -lz
include $(BUILD_SHARED_LIBRARY)
#end of avformat module

#avcodec module
include $(CLEAR_VARS)
LOCAL_MODULE := avcodec
LOCAL_ARM_MODE := arm
LOCAL_CFLAGS := -DHAVE_AV_CONFIG_H
include $(LOCAL_PATH)/../lib$(LOCAL_MODULE)_files.mk
LOCAL_SHARED_LIBRARIES := avutil
LOCAL_LDFLAGS := -L$(SYSROOT)/usr/lib -lz -lm
include $(BUILD_SHARED_LIBRARY)
#end of avcodec module