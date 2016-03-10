#!/bin/bash
echo create an admin account
echo hmset admin username 'administrator' password '$2a$10$3SL28R8Yw5KDQ67zbgsLCOsKHQk.m1z1qHKEun/7UPZ0QrIosHtDW' salt '$2a$10$3SL28R8Yw5KDQ67zbgsLCO' | redis-cli

echo create some folders
sudo mkdir tmp
sudo mkdir tmp/sockets
sudo mkdir tmp/pids
sudo mkdir log
