#!/bin/bash
# This script applies modifications made with menuconfig to sdkconfig.defaults
# It runs menuconfig, but also respects changes already made with menuconfig

ENV=esp32dev

# create a backup of the current sdkconfig
mv sdkconfig.defaults sdkconfig.defaults.old
# move potentially modified sdkconfig out of the way
mv sdkconfig.$ENV sdkconfig.$ENV.new
# generate a vanilla sdkconfig.$ENV in a vacuum, with no modifications
# by pressing 'q' repeatedly using the yes command, the interaction is skipped
# (since there are no modifications, this will not create its own .old file)
yes q | pio run -e "$ENV" -t menuconfig
# move the new sdkconfig to a temporary file
mv sdkconfig.$ENV sdkconfig.$ENV.vanilla || exit 1
# restore potentially modified sdkconfig
mv sdkconfig.$ENV.new sdkconfig.$ENV
# restore original sdkconfig.defaults, while keeping the backup
cp sdkconfig.defaults.old sdkconfig.defaults
# user configures menuconfig
# this will
# 1. create sdkconfig.$ENV based on sdkconfig.defaults and user input
# 2 option a. generate sdkconfig.$ENV.old based on sdkconfig.defaults
# 2 option b. copy any existing sdkconfig.$ENV to sdkconfig.$ENV.old
# 2 option c. create no sdkconfig.$ENV.old if no changes were made and
#             there is already an existing sdkconfig.$ENV that was generated
#             from sdkconfig.defaults with no modifications
pio run -e "$ENV" -t menuconfig
# generate new defaults with the modified sdkconfig
grep -Fxv -f sdkconfig.$ENV.vanilla sdkconfig.$ENV \
    > sdkconfig.defaults || exit 1
# we don't need sdkconfig.$ENV.old, it's made redundant by our own .old file
rm sdkconfig.$ENV.old sdkconfig.$ENV.vanilla
