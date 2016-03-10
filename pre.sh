#!/bin/bash
echo create an admin account
echo hmset admin username administrator password password | redis-cli

echo create some folders
sudo mkdir tmp
sudo mkdir tmp/sockets
sudo mkdir tmp/pids
sudo mkdir log
