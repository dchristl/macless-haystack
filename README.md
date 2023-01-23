## Introduction

This project tries to unify several projects for simpler handling of custom BT-devices with Apple's FindMy network. The goal is to run a headless MacOS without the need to have a real Mac and have to install mail plugins or openhaystack itself. The other goal is to bypass tracking protection features by apple. 

***This is project is just a playground for checking technical feasibility and should not be used otherwise.***

Included projects are (Credits goes to them for the hard work):
- The original [Openhaystack](https://github.com/seemoo-lab/openhaystack)
    - Android application 
    - ESP32 firmware
- [Biemster's FindMy](https://github.com/biemster/FindMy)
    - The standalone python webserver for fetching the FindMy reports
- [Positive security's Find you](https://github.com/positive-security/find-you)
    - ESP32 firmware customization for stealth BT devices
- Optional: Dockerized MacOS by [Sickcodes](https://github.com/sickcodes/Docker-OSX) 


## Changes to the original projects

### Openhaystack

Stripped down to the mobile application (Android) and ESP32 firmware. ESP32 firmware unified with FindYou project (rotating keys) and optinizations in power usage. 
 

### Biemster's FindMy

Customization in keypair generator to output an array for the ESP32 firmware and a json for import in the Android application. 

## Requirements

- MacOS (virtual or real). Checkout [dockerized Catalina](https://github.com/sickcodes/Docker-OSX#run-catalina-pre-installed-) 
- Valid Apple ID and signed in MacOS.
- Installed [ESP-IDF](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/index.html) for building the customized ESP32 framework
- Installed [Flutter](https://docs.flutter.dev/get-started/install/linux) and [Android SDK](https://developer.android.com/about/versions/13/setup-sdk#install-sdk) for the Android application

## Instructions

- Host or MacOS-Guest: Run `generate_keypairs.py` with the number of keypairs to generate as argument (e.g. `./generate_keypairs.py -n 10 -p PREFIX`). All files will be in output-folder (All keys as information, PREFIX_keyfile for ESP32 and PREFIX_devices.json for import in application)
- Host: Compile firmware and flash ESP32
- Host: Flash the keyfile to the ESP32 at PREFIX_keyfile at address 0x110000 with `esptool.py write_flash 0x110000 PREFIX_keyfile`
- MacOS-Guest: Start Webserver with `./FindMy_proxy.py` (is running on port 80, but is exposed to 56176)
- Host: Change the host in `openhaystack-mobile/lib/findMy/reports_fetcher.dart` to your Host-IP or DNS name
- Host: Build mobile application with `flutter build apk`
- Mobile: Install application
- Mobile: Import PREFIX_devices.json to Android application

