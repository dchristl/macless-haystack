#!/bin/bash
# This script applies modifications made with menuconfig to sdkconfig.defaults
# It runs menuconfig, but also respects changes already made with menuconfig

# create a backup of the current sdkconfig
mv sdkconfig.defaults sdkconfig.defaults.old
# move potentially modified sdkconfig out of the way
mv sdkconfig.esp32dev sdkconfig.esp32dev.new
# generate a vanilla sdkconfig.esp32dev in a vacuum, with no modifications
# by pressing 'q' repeatedly using the yes command, the interaction is skipped
# (since there are no modifications, this will not create its own .old file)
yes q | pio run -t menuconfig
# move the new sdkconfig to a temporary file
mv sdkconfig.esp32dev sdkconfig.esp32dev.vanilla || exit 1
# restore potentially modified sdkconfig
mv sdkconfig.esp32dev.new sdkconfig.esp32dev
# restore original sdkconfig.defaults, while keeping the backup
cp sdkconfig.defaults.old sdkconfig.defaults
# user configures menuconfig
# this will
# 1. create sdkconfig.esp32dev based on sdkconfig.defaults and user input
# 2 option a. generate sdkconfig.esp32dev.old based on sdkconfig.defaults
# 2 option b. copy any existing sdkconfig.esp32dev to sdkconfig.esp32dev.old
# 2 option c. create no sdkconfig.esp32dev.old if no changes were made and
#             there is already an existing sdkconfig.esp32dev that was generated
#             from sdkconfig.defaults with no modifications
pio run -t menuconfig
# generate new defaults with the modified sdkconfig
grep -Fxv -f sdkconfig.esp32dev.vanilla sdkconfig.esp32dev \
    > sdkconfig.defaults || exit 1
# we don't need sdkconfig.esp32dev.old, it's made redundant by our own .old file
rm sdkconfig.esp32dev.old sdkconfig.esp32dev.vanilla
