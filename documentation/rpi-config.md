# Pre-configuration of raspberries

## Set hostname

Seen that the default hostname is "black-pearl" for all freshly booted Hypriot images, we should set a custom one.

Edit (as root) the file ```/boot/occidentalis.txt``` at the line beginning with ```hostname```:
```bash
$ cat /boot/occidentalis.txt 
# hostname for your Hypriot Raspberry Pi:
hostname=your-name

# basic wireless networking options:
# wifi_ssid=your-ssid
# wifi_password=your-presharedkey
```

Note that a reboot is required. We'll do that at the end of the pre-configurations.

## Run the pre-configuration script

The script will be downloaded and ran from the gateway :
```bash
$ curl -L -o /tmp/pi-config.sh http://SHACK_IP/pi-config.sh
$ sudo sh /tmp/pi-config.sh
```

Optionaly you can change the default gateway IP if 192.168.2.1 does not fit to your need ;
```bash
$ sudo sh /tmp/pi-config.sh 10.0.5.1 # Or whatever IP it is
```

It should do :
* Configuring apt-get to use an http caching proxy, located in the shack machine
* Ensuring packages are up to date, in safe manner (no kernel update)
* Install LXDE, git, curl and chromium for easying the session
* Configure the Pi to use X interface by default
* Pre-configure your docker daemon to :
  - Use the "shack machine" as docker mirror registry
  - Enable the HTTP protocol when using this private registry (instead of HTTP**S**)
  - Listen to the 2375 port on all interfaces of your host
* Disable verbose output of the kernel on the tty

## Reboot your Raspberry

Simple as a ```sudo reboot```
