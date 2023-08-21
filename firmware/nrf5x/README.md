## Headless Haystack Firmware for NRF51 and NRF52

This project contains an battery-optimized firmware for the Nordic NRF5x chips from [acalatrava](https://github.com/acalatrava/openhaystack-firmware). So all credits goes to him. 
After flashing our firmware, the device sends out Bluetooth Low Energy advertisements such that it can be found by [Apple's Find My network](https://developer.apple.com/find-my/).
This firmware consumes slightly more power when more than 1 key is used. The controller wakes up every 30 minutes and switches the key.

> [!WARNING]  
> Currently, only the NRF51 build has been tested, and the NRF52 build has not been tested yet, but it should work. Feedback on this is welcome. It has been tested with [this](https://www.aliexpress.com/item/1005003671695188.html?spm=a2g0o.order_list.order_list_main.55.72491802ZTaXKp) or [this](https://de.aliexpress.com/item/32860266105.html?spm=a2g0o.order_list.order_list_main.50.72491802ZTaXKp&gatewayAdapt=glo2deu) beacon from Aliexpress.

### Deploy the Firmware

- Download firmware for your device
- Copy your previously generated PREFIX_keyfile in the same folder 
- Patch the firmware with your keyfile (Change the path if necessary!)

```
# For the nrf51
xxd -p -c 100000 PREFIX_keyfile | xxd -r -p | dd of=nrf51_firmware.bin skip=1 bs=1 seek=$(grep -oba OFFLINEFINDINGPUBLICKEYHERE! nrf51_firmware.bin | cut -d ':' -f 1) conv=notrunc
```
or 
```
# For the nrf52
xxd -p -c 100000 PREFIX_keyfile | xxd -r -p | dd of=nrf52_firmware.bin skip=1 bs=1 seek=$(grep -oba OFFLINEFINDINGPUBLICKEYHERE! nrf52_firmware.bin | cut -d ':' -f 1) conv=notrunc
```

The output should be something like this, depending on the count of your keys (in this example 3 keys => 3*28=84 Bytes):
```
84+0 records in
84+0 records out
84 bytes copied, 0.00024581 s, 346 kB/s
```

- Patch the changed firmware file your firmware, i.e with openocd:
```
openocd -f openocd.cfg -c "init; halt; nrf51 mass_erase; program nrf51_firmware.bin; reset; exit"
```
(Hint: If needed, the file openocd.cfg is in the root of this folder)


> [!NOTE]  
> You might need to reset your device after running the script before it starts sending advertisements.


### Misc

If you want to compile the firmware for yourself or need further informations have a look at [project documentation](https://github.com/acalatrava/openhaystack-firmware/blob/main/apps/openhaystack-alternative/README.md)