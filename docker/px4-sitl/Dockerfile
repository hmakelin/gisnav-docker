from px4io/px4-dev-ros2-foxy

ARG NVIDIA_DRIVER_MAJOR_VERSION
ENV NVIDIA_DRIVER_MAJOR_VERSION=${NVIDIA_DRIVER_MAJOR_VERSION}

RUN apt-get --fix-missing update

# Install Nvidia driver if NVIDIA_DRIVER_MAJOR_VERSION was provided
RUN if [ -z "$NVIDIA_DRIVER_MAJOR_VERSION" ]; \
        then \
            tput setaf 3; \
            echo "\$NVIDIA_DRIVER_MAJOR_VERSION not provided - skipping driver installation."; \
            tput sgr0; \
        else \
            apt-get -y install nvidia-driver-$NVIDIA_DRIVER_MAJOR_VERSION; \
            apt-get -y install --reinstall xserver-xorg-video-intel libgl1-mesa-glx libgl1-mesa-dri xserver-xorg-core; \
            dpkg-reconfigure xserver-xorg; \
    fi

# Install PX4-Autopilot
RUN git clone https://github.com/PX4/PX4-Autopilot.git $HOME/PX4-Autopilot --recursive &&\
    bash $HOME/PX4-Autopilot/Tools/setup/ubuntu.sh

# Install gscam
RUN apt-get install -y ros-foxy-gscam

## Build ROS 2 workspace and PX4-ROS 2 bridge
RUN git clone https://github.com/PX4/px4_ros_com.git $HOME/colcon_ws/src/px4_ros_com &&\
    git clone https://github.com/PX4/px4_msgs.git $HOME/colcon_ws/src/px4_msgs
RUN cd $HOME/colcon_ws/src/px4_ros_com/scripts &&\
    ./build_ros2_workspace.bash

# Install pyyaml dependency and run the Python script
RUN pip3 install empy pyros-genmsg setuptools pyyaml
COPY scripts/configure_urtps_bridge_topics.py /
RUN mv configure_urtps_bridge_topics.py $HOME/ &&\
    python3 $HOME/configure_urtps_bridge_topics.py

# Increase typhoon_h480 build target GPS measurement noise
RUN echo "param set-default EKF2_GPS_P_NOISE 1" >> \
    $HOME/PX4-Autopilot/ROMFS/px4fmu_common/init.d-posix/airframes/6011_typhoon_h480

# Install QGroundControl
RUN apt-get install libfuse2
RUN wget -P $HOME https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage
RUN chmod +x $HOME/QGroundControl.AppImage

COPY yaml/camera_calibration.yaml /
RUN mv camera_calibration.yaml $HOME/

COPY yaml/gscam_params.yaml /
RUN mv gscam_params.yaml $HOME/

COPY Makefile /
RUN mv Makefile $HOME/

CMD cd $HOME && make gazebo