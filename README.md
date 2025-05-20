# Setting Static Device Names for USB Serial Adapters on Ubuntu

## Identify Device Codes

1. Connect the USB adapter and open Terminal
2. Find device assignment:
   ```bash
   dmesg | grep ttyUSB
   ```
3. Get device attributes:
   ```bash
   udevadm info --name=/dev/ttyUSB0 --attribute-walk
   ```
4. Note the `idProduct` and `idVendor` values (e.g., `ea60` and `10c4`)

## Create udev Rule

1. Create rule file:
   ```bash
   sudo nano /etc/udev/rules.d/50-usb-serial.rules
   ```
2. Add this line (replace with your values):
   ```
   SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", SYMLINK+="my_device_name"
   ```

## Apply and Verify

1. Apply the rule:
   ```bash
   sudo udevadm trigger
   ```
   (or restart computer)

2. Verify with:
   ```bash
   ls -l /dev/my_device_name
   ```

Your device now has a static name that persists across reboots and reconnections.
