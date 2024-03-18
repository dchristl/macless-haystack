## Macless Haystack Firmware for ESP32

This project contains a battery-optimzed PoC firmware for Espressif ESP32 chips (like ESP32-WROOM or ESP32-WROVER, but _not_ ESP32-S2).
After flashing our firmware, the device sends out Bluetooth Low Energy advertisements such that it can be found by [Apple's Find My network](https://developer.apple.com/find-my/).
This firmware consumes slightly more power when more than 1 key is used. The controller wakes up every 30 minutes and switches the key.

### Requirements

- [Esptool](https://docs.espressif.com/projects/esptool/en/latest/esp32/installation.html) installed *or*
- [Espressif's Flash Download Tools](https://www.espressif.com/en/support/download/other-tools) installed if you prefer a graphical way

### Deploy the Firmware

- Download and unpack the firmware
- Copy your previously generated PREFIX_keyfile in the same folder 

```bash
esptool.py write_flash 0x1000  bootloader.bin \
                0x8000  partitions.bin \
                0x10000 firmware.bin \
                0x110000 PREFIX_keyfile
```

If any problem occurs, erase flash manually before flashing:

```bash
esptool.py erase_flash
```

> [!NOTE]  
> You might need to reset your device after running the script before it starts sending advertisements.
