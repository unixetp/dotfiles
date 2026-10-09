#!/usr/bin/env bash

killall -9 wl-paste 2>/dev/null

wl-paste --watch cliphist store &
wl-paste --type image --watch cliphist store &
