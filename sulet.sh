#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root (use sudo)"
  exit 1
fi

# Prompt for device name
read -p "Enter the name you want for your device (e.g., my_arduino): " DEVICE_NAME

# Validate device name input
if [ -z "$DEVICE_NAME" ]; then
  echo "Error: Device name cannot be empty"
  exit 1
fi
RULES_FILE="/etc/udev/rules.d/50-usb-serial.rules"

# Check if a USB device is connected
USB_DEVICES=$(dmesg | grep ttyUSB)
if [ -z "$USB_DEVICES" ]; then
  echo "No USB serial devices detected. Please connect your device first."
  exit 1
fi

echo "Detected USB device(s):"
echo "$USB_DEVICES"
echo ""

# Get list of ttyUSB devices
TTY_DEVICES=$(ls /dev/ttyUSB*)
echo "Available ttyUSB devices:"
echo "$TTY_DEVICES"
echo ""

# Ask user to select device
read -p "Enter the device path (e.g., /dev/ttyUSB0): " DEVICE_PATH

if [ ! -e "$DEVICE_PATH" ]; then
  echo "Error: $DEVICE_PATH does not exist"
  exit 1
fi

echo "Getting device attributes for $DEVICE_PATH..."
DEVICE_INFO=$(udevadm info --name=$DEVICE_PATH --attribute-walk)

# Extract vendor ID and product ID
VENDOR_ID=$(echo "$DEVICE_INFO" | grep -m 1 "idVendor" | awk -F'"' '{print $2}')
PRODUCT_ID=$(echo "$DEVICE_INFO" | grep -m 1 "idProduct" | awk -F'"' '{print $2}')
SERIAL_NUM=$(echo "$DEVICE_INFO" | grep -m 1 "serial" | awk -F'"' '{print $2}')

if [ -z "$VENDOR_ID" ] || [ -z "$PRODUCT_ID" ]; then
  echo "Could not find vendor ID or product ID for this device"
  exit 1
fi

echo "Found device with:"
echo " - Vendor ID: $VENDOR_ID"
echo " - Product ID: $PRODUCT_ID"
if [ ! -z "$SERIAL_NUM" ]; then
  echo " - Serial Number: $SERIAL_NUM"
fi

# Create a udev rule
echo "Creating udev rule..."

# Check if we have a serial number to make the rule more specific
if [ ! -z "$SERIAL_NUM" ]; then
  RULE="SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"$VENDOR_ID\", ATTRS{idProduct}==\"$PRODUCT_ID\", ATTRS{serial}==\"$SERIAL_NUM\", SYMLINK+=\"$DEVICE_NAME\""
else
  RULE="SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"$VENDOR_ID\", ATTRS{idProduct}==\"$PRODUCT_ID\", SYMLINK+=\"$DEVICE_NAME\""
fi

# Check if the rules file exists, create if not
if [ ! -f "$RULES_FILE" ]; then
  echo "Creating new rules file: $RULES_FILE"
  touch "$RULES_FILE"
fi

# Check if rule already exists
if grep -q "$DEVICE_NAME" "$RULES_FILE"; then
  echo "Warning: A rule for $DEVICE_NAME already exists in $RULES_FILE"
  read -p "Do you want to replace it? (y/n): " REPLACE
  if [ "$REPLACE" = "y" ]; then
    sed -i "/SYMLINK+=\"$DEVICE_NAME\"/d" "$RULES_FILE"
  else
    echo "Aborted. No changes made."
    exit 0
  fi
fi

# Add the rule to the file
echo "$RULE" >> "$RULES_FILE"
echo "Rule added to $RULES_FILE"

# Apply the new rule
echo "Applying new udev rules..."
udevadm control --reload-rules
udevadm trigger

echo "Device naming setup complete!"
echo ""
echo "Your device should now be accessible at: /dev/$DEVICE_NAME"
echo "To verify, disconnect and reconnect the device, then run:"
echo "  ls -l /dev/$DEVICE_NAME"
echo ""
echo "If the link doesn't appear, reboot your system and check again."

exit 0
