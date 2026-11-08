
# Start from the official ROS 2 Jazzy image (Ubuntu 24.04 + ROS 2 + RViz + basic tools).
ARG ROS_DISTRO=jazzy
FROM osrf/ros:$ROS_DISTRO-desktop

# Settings that can be overridden at build time (docker-compose passes your real IDs).
ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=1000
# Stops apt from asking questions during the build.
ENV DEBIAN_FRONTEND=noninteractive


# Install what the base image does not have yet.
RUN apt-get update && apt-get install -y --no-install-recommends \
        # ros-gz = Gazebo Harmonic + the ROS <-> Gazebo bridge and launch tools
        ros-$ROS_DISTRO-ros-gz \
        # publishes the robot's TF tree from the URDF
        ros-$ROS_DISTRO-robot-state-publisher \
        ros-$ROS_DISTRO-rviz2 \
        # drive the robot with the keyboard (useful later)
        ros-$ROS_DISTRO-teleop-twist-keyboard \
        # the `colcon` build tool for ROS packages
        python3-colcon-common-extensions \
        # OpenGL libraries: Gazebo and RViz need them to draw 3D graphics
        mesa-utils \
        libgl1-mesa-dri \
        libglx-mesa0 \
        libegl1 \
        # tiny test program (xeyes) to check that windows can open
        x11-apps \
        ros-$ROS_DISTRO-navigation2 \
        ros-$ROS_DISTRO-nav2-bringup \
        ros-$ROS_DISTRO-slam-toolbox \
        ros-$ROS_DISTRO-turtlebot3-gazebo \
        ros-$ROS_DISTRO-turtlebot3-msgs \
        ros-$ROS_DISTRO-turtlebot3-bringup \
    && rm -rf /var/lib/apt/lists/*
 
# Create a normal (non-root) user with the SAME numeric ID as your host user.
# Why: files created inside the container (e.g. in ./src) then belong to YOU on the host,
# not to root, so you can edit and commit them without permission problems.
# (Ubuntu 24.04 images contain a default user "ubuntu" with ID 1000; we remove it first.)
RUN (userdel -r ubuntu 2>/dev/null || true) \
    && groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    # /ws is the ROS "workspace": src = your code, build/install/log = build output
    && mkdir -p /ws/src /ws/build /ws/install /ws/log \
    && chown -R ${USERNAME}:${USERNAME} /ws

# The entrypoint script runs every time the container starts (it loads the ROS environment).
COPY ros_entrypoint.sh /ros_entrypoint.sh
RUN chmod +x /ros_entrypoint.sh

# Settings so GUI programs work inside Docker:
#   QT_X11_NO_MITSHM         - avoids a shared-memory problem with the X11 display
#   QT_QPA_PLATFORM=xcb      - makes Qt (used by RViz/Gazebo) use X11, which also works on Wayland
#   ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST - ROS 2 only talks to programs on this computer,
#                            so it does not mix with other ROS users on your network
#   NVIDIA_*                 - lets NVIDIA graphics cards be used (needs nvidia-container-toolkit)
ENV QT_X11_NO_MITSHM=1 \
    QT_QPA_PLATFORM=xcb \
    ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=all \
    TURTLEBOT3_MODEL=waffle

# Load ROS automatically when you open a terminal inside the container.
RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> /home/${USERNAME}/.bashrc \
    && echo "export TURTLEBOT3_MODEL=waffle" >> /home/${USERNAME}/.bashrc \
    && echo '[ -f /ws/install/setup.bash ] && source /ws/install/setup.bash' >> /home/${USERNAME}/.bashrc

# From here on, run as the normal user and start in the workspace folder.
USER ${USERNAME}
WORKDIR /ws

# Pre-download essential Gazebo Fuel models so startup doesn't fail offline
RUN . /opt/ros/$ROS_DISTRO/setup.sh && \
    gz fuel download -v 4 -u "https://fuel.gazebosim.org/1.0/OpenRobotics/models/Ground Plane" && \
    gz fuel download -v 4 -u "https://fuel.gazebosim.org/1.0/OpenRobotics/models/Sun"

ENTRYPOINT ["/ros_entrypoint.sh"]
# Default command if none is given: open a bash terminal.
CMD ["bash"]
