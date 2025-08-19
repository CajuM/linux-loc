#!/bin/sh

TAP=$1

ip link add name br-exp type bridge || true
ip link set dev br-exp up || true
ip link set dev ${TAP} master br-exp
ip link set dev ${TAP} up
