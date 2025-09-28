#!/bin/bash

#run as root

rm /var/netboot/pxelinux.cfg/* /var/netboot/live/*
cp pxelinux.cfg/* /var/netboot/pxelinux.cfg/
cp binary/live/* /var/netboot/live/
