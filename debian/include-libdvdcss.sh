#!/bin/bash

#includes the DVD encryption library from the host machine into the image
mkdir -p config/includes.chroot/usr/lib/x86_64-linux-gnu
cp /usr/lib/x86_64-linux-gnu/libdvdcss.* config/includes.chroot/usr/lib/x86_64-linux-gnu
