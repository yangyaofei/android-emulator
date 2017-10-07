#!/bin/bash
/etc/init.d/ssh start

ip=$(ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')
socat tcp-listen:5037,bind=$ip,fork tcp:127.0.0.1:5037 &
socat tcp-listen:5554,bind=$ip,fork tcp:127.0.0.1:5554 &
socat tcp-listen:5555,bind=$ip,fork tcp:127.0.0.1:5555 &

echo "no" | /root/android-sdk-linux/tools/android create avd  -t 'android-22' -b armeabi-v7a -n android-5.1.1 
echo "no" | /root/android-sdk-linux/tools/emulator64-arm -avd android-5.1.1 -noaudio -no-window -gpu off -verbose -qemu -usbdevice tablet -vnc :0
#-no-boot-ani -noaudio -no-window -gpu off -verbose -qemu -usbdevice tablet -vnc :0
