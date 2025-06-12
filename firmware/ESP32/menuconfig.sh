#!/bin/bash
# This script applies modifications made with menuconfig to sdkconfig.defaults
# It runs menuconfig, but also respects changes already made with menuconfig

# create a backup of the current sdkconfig
cp sdkconfig.defaults sdkconfig.defaults.old
# user configures menuconfig
pio run -t menuconfig
# this will
# 1. create sdkconfig.esp32dev based on sdkconfig.defaults and user input
# 2. generate sdkconfig.esp32dev.old based on sdkconfig.defaults
# generate new defaults with the modified sdkconfig
grep -Fxv -f sdkconfig.esp32dev sdkconfig.esp32dev.old >> sdkconfig.defaults
# we don't need sdkconfig.esp32dev.old, it's made redundant by our own .old file
rm sdkconfig.esp32dev.old
