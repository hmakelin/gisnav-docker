from px4io/px4-dev-ros2-foxy

# Need --fix-missing to get OpenGL to work
RUN apt-get --fix-missing update && apt-get -y install sudo

# Set 'gisnav' as default user and add it to sudo'ers
# QGroundControl will not run as 'root', sudo needed for installing to appropriate $HOME directory
ARG USERNAME=gisnav
ARG UID=1000
ARG GID=$UID
RUN groupadd --gid $GID $USERNAME && useradd --uid $UID --gid $GID -m $USERNAME
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
USER $USERNAME

# For OpenGL to work
RUN sudo apt-get -y install --reinstall xserver-xorg-video-intel libgl1-mesa-glx libgl1-mesa-dri xserver-xorg-core && \
    sudo dpkg-reconfigure xserver-xorg

# Install PX4-Autopilot
RUN git clone --branch v1.12.3 https://github.com/PX4/PX4-Autopilot.git $HOME/PX4-Autopilot --recursive &&\
    bash $HOME/PX4-Autopilot/Tools/setup/ubuntu.sh

# Install gscam
RUN sudo apt-get install -y ros-foxy-gscam

## Build ROS 2 workspace and PX4-ROS 2 bridge
RUN git clone https://github.com/PX4/px4_ros_com.git $HOME/colcon_ws/src/px4_ros_com &&\
    git clone https://github.com/PX4/px4_msgs.git $HOME/colcon_ws/src/px4_msgs
RUN cd $HOME/colcon_ws/src/px4_ros_com/scripts &&\
    ./build_ros2_workspace.bash

# Install pyyaml dependency and run the Python script
RUN pip3 install empy pyros-genmsg setuptools pyyaml
COPY scripts/configure_urtps_bridge_topics.py /
RUN sudo mv configure_urtps_bridge_topics.py $HOME/ &&\
    python3 $HOME/configure_urtps_bridge_topics.py

# Increase typhoon_h480 build target GPS measurement noise
RUN echo "param set-default EKF2_GPS_P_NOISE 1" >> \
    $HOME/PX4-Autopilot/ROMFS/px4fmu_common/init.d-posix/airframes/6011_typhoon_h480

# Install QGroundControl
RUN sudo apt-get install libfuse2
RUN wget -P $HOME https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage
RUN chmod +x $HOME/QGroundControl.AppImage

COPY yaml/camera_calibration.yaml /
RUN sudo mv camera_calibration.yaml $HOME/

COPY yaml/gscam_params.yaml /
RUN sudo mv gscam_params.yaml $HOME/

COPY Makefile /
RUN sudo mv Makefile $HOME/

# Run check to make subsequent builds faster
RUN cd $HOME/PX4-Autopilot && \
    make check_px4_sitl_rtps gazebo_typhoon_h480__ksql_airport

CMD cd $HOME && make HOME=$HOME gazebo
