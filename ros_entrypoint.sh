#!/bin/bash
# ros_entrypoint.sh - runs first whenever the container starts, then runs your command.
set -e   # stop immediately if any command fails

# Optional fallback: if you have graphics problems, SOFTWARE_RENDER=1 (set in .env)
# makes the CPU draw the 3D graphics instead of the GPU. Slower, but works everywhere.
if [ "${SOFTWARE_RENDER:-0}" = "1" ]; then
  export LIBGL_ALWAYS_SOFTWARE=1
fi

# "Source" the ROS 2 installation: this makes commands like `ros2` available.
source /opt/ros/jazzy/setup.bash

# If our own workspace has been built, load it too, so ROS can find the simple_bot package.
if [ -f /ws/install/setup.bash ]; then
  source /ws/install/setup.bash
fi

# Finally run whatever command was given (e.g. the launch command from docker-compose.yml).
exec "$@"
