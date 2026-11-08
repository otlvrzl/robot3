#!/usr/bin/env bash
# setup.sh - one-time helper that you run on your HOST computer:   bash setup.sh
# It does two things:
#   1. writes a .env file with your user/group IDs (so files made in Docker belong to you)
#   2. allows programs in Docker to open windows (Gazebo, RViz) on your screen

set -e                          # stop if any command fails
cd "$(dirname "$0")"            # work inside the folder where this script lives

# Only create .env if it does not exist yet, so we never overwrite your own edits
# (for example SOFTWARE_RENDER=1).
if [ ! -f .env ]; then
  cat > .env <<EOF
HOST_UID=$(id -u)
HOST_GID=$(id -g)
VIDEO_GID=$(getent group video | cut -d: -f3)
RENDER_GID=$(getent group render | cut -d: -f3)
SOFTWARE_RENDER=0
GZ_IP=127.0.0.1
GZ_PARTITION=default
DISPLAY=:0 xhost +local:docker
DISPLAY=:1 xhost +local:docker
EOF
  echo "Created .env"
else
  echo ".env already exists, leaving it as is"
fi



# By default the display server refuses connections from Docker. "xhost" tells it to
# accept them from local programs. Needed again after each reboot.
if xhost +local:docker >/dev/null 2>&1; then
  echo "Docker containers may now open windows on your display"
else
  echo "WARNING: 'xhost' failed. Are you in a desktop session? (needs: sudo apt install x11-xserver-utils)"
fi
