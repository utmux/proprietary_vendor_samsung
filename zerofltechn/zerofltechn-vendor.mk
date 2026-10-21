# Copyright (C) 2026
# SPDX-License-Identifier: Apache-2.0

VENDOR_PATH := vendor/samsung/zerofltechn

# Reuse the universal7420 vendor tree's recursive blob mapper.  Expand this
# list immediately: zero-common reuses the global VENDOR_PATH variable later,
# and a deferred += expansion would silently turn these entries into common
# blobs.  Keeping PRODUCT_COPY_FILES simple also lets the common mapper see
# and skip destinations already supplied by ERK2.
include vendor/samsung/zero-common/find-vendor-blobs.mk

# libsecril-client is built from the Android 10 source tree with the two ERK2
# client-data extensions.  Do not let the retained stock reference blob
# replace that ABI-compatible source build in the system image.
PRODUCT_COPY_FILES := $(PRODUCT_COPY_FILES) \
    $(filter-out \
        vendor/samsung/zerofltechn/proprietary/system/lib64/libsecril-client.so:system/lib64/libsecril-client.so, \
        $(call find-vendor-blobs,vendor/samsung/zerofltechn/proprietary))

# Samsung's rc invokes irsc_util with /etc/sec_config while ERK2 ships the
# carrier-neutral file as sec_config_oem.
PRODUCT_COPY_FILES += \
    $(VENDOR_PATH)/proprietary/system/etc/sec_config_oem:system/etc/sec_config
