# SM-G9200 ERK2 device blobs

These files were extracted from the user's stock
`G9200ZCU2ERK2` system image.  The directory contains only the ELF dependency
closure rooted at the external-modem daemons and both 32/64-bit Samsung RIL
libraries, plus `sec_config_oem` and a device-specific 64-bit sensors HAL.

The intended runtime path is MDM9635M over PCIe/MHI: `mdm_helper`, `qmuxd`,
two `rild` instances, `/dev/mhi_pipe_*`, and `rmnet_mhi0`.

The G9200 `libsec-ril` and `libsec-ril-dsds` binaries are installed below
`system/vendor/lib{,64}` because the LineageOS 17.1 universal7420 rild loads
them through `/vendor/lib64`; the remaining ERK2 dependencies retain their
stock system/vendor destinations.

`tools/elf_closure.py` in the port workspace can be used to reproduce and
audit the selected dependency closure.

The running Android 10 sensors service is 64-bit and loads
`system/lib64/hw/sensors.universal7420.so`; the 32-bit blob is left to
`zero-common`.  The device override is the 64-bit HAL extracted from the
G9200ZCU2ERK2 stock image.  Its original SHA-256 is
`d00cb51a6f9cb98b09ed63eae359c81f790bc2908beb07a0866117b4057efc94`.

Android 10 calls the legacy HAL `batch()`/`setDelay()` path before activating
an on-change sensor and rejects a non-zero result.  ERK2's `LightSensor` and
`ProximitySensor` `setDelay()` entry points are therefore patched to return
success; these IIO sensors do not need a polling delay, and their real
enable/read paths are unchanged.  The resulting 64-bit blob SHA-256 is
`aaed199c825df74e086d3e8646f2b7985d769a0e2b6049b4f8962f19749928cf`.

This HAL matches the G9200 sensor BOM (BMP280, TMD4903 and AK09911C).  On the
device it provides live light, proximity and pressure events without the
pressure EINVAL busy loop seen with the shared zero-common HAL, whose sensor
list instead identifies LPS25H, TMD49XX and YAS537 parts.

The G9200 NFC controller is an NXP PN547/PN548-family part exposed as
`/dev/pn547`; it is not the Samsung S3FWRN5 used by the shared zero-common
`SecHAL`.  The stock legacy HAL can initialize the controller, but Android 10
eventually blocks in `applyRouting()`.  The final device configuration instead
uses the source-built NXP `android.hardware.nfc@1.1-service`, together with the
ERK2 NXP/RF configuration and `libpn548ad_fw.so` firmware image.  The shared
Samsung `libnfc-nci.conf` is also replaced by NXP's NCI 1.0 configuration;
its Samsung-only polling mask and `/dev/sec-nfc` settings caused the PN66T to
reject `RF_DISCOVER` and trigger the framework watchdog.  The NXP HIDL path
was validated by a complete off/on cycle: it identified PN66T firmware
10.1.22, completed routing and polling, and reached `dumpsys nfc` state `on`.

PN66T also rejects an RF discovery list containing the Kovio proprietary
technology mode (`0xFF`) with NCI status `0x05`.  Android's default NXP polling
mask `0x6F` enables that mode through bit `0x20`, causing the apparent
`applyRouting` watchdog loop.  The device configuration uses `0x4F` instead,
retaining NFC-A/B/F, ISO15693, active polling and the normal `0x45` P2P listen
mask.  A live disable/enable cycle completed without restarting `NfcNci`.

`at_distributor` also needs ERK2's `libatparser.so`.  The shared Android 10
`libsecril-client` originally lacked the private `GetClientData` and
`SetClientData` exports used by the G9200 binary.  Their stock behavior was
recovered from the ERK2 library and added to the source implementation, while
keeping the normal 32/64-bit Android 10 build for its audio and GPS clients.
The patched source library was tested live on the phone: the daemon stayed
running, connected to the RIL socket, and opened `/dev/ttySAC1` instead of
entering init's five-second restart loop.  The retained stock library is only
a reference/fallback blob and is filtered out of `PRODUCT_COPY_FILES`.
