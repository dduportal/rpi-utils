
class: center, middle

# Docker-Bel Meetup
## Swarm on Raspberry Pis

---

# Agenda

* 19h: Welcome & bootstrap
* 19h30: Talk from Dieter Reuter from Hypriot
* 20h: Workshop time !
* 22h: End of the workshop + drinks and snacks

---

# Welcome to the meetup !
## How to quickly bootstrap ?

1. If not already done, flash you SD card with the 0.6.1 Hector image.

2. Connect your laptop to the shared Wifi "Dadou’s MacBook Air" (dockerbel)

3. Insert the SD card, connect the Pi to Ethernet and power it with micro-USB

4. Use `nmap 192.168.2.0/24` to locate your Pi's IP and access it with :
  ```
  ssh pi@<FOUND IP>
  ```

5. Set an hostname by editing `/boot/occidentalis.txt` and `sudo reboot now`

6. Upgrade embedded docker tools :
  ```
  $ sudo apt-get update
  $ sudo apt-get upgrade docker docker-compose
  ```
