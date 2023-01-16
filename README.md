## Instructions

1. MacOS-Guest or Host: Run `generate_keypairs.py` with the number of keypairs to generate as argument (e.g. `./generate_keypairs.py -n 10 -p PREFIX`). All files will be in output-folder
2. Host: Copy the array definition in PREFIX_array.txt in Firmware (openhaystack_main.c:55)
3. Host: Compile firmware and flash ESP32
4. MacOS-Guest: Start Webserver with `./FindMy_proxy.py` (is running on port 80, but is exposed to 56176)
5. Host: Build mobile application with `flutter build apk`
6. Mobile: Install application
5. Mobile: Import PREFIX_devices.json to Android application
