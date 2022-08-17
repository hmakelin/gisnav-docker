from px4io/px4-dev-ros2-foxy

# Get a combination of commits that works together
# In the past there have been breaking changes concerning microRTPS bridge generation
# See e.g. https://github.com/PX4/PX4-Autopilot/pull/18052
ARG PX4_AUTOPILOT_COMMIT=deb938fceaa79b927ae0f622d8b2b8c4ad10d391
ARG PX4_ROS_COM_COMMIT=90538d841a383fe9631b7046096f9aa808a43121
ARG PX4_MSGS_COMMIT=7f89976091235579633935b7ccaab68b2debbe19

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

# Install gscam
RUN sudo apt-get install -y ros-foxy-gscam

# Install QGroundControl
RUN sudo apt-get install libfuse2
RUN wget -P $HOME https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage
RUN chmod +x $HOME/QGroundControl.AppImage

# Clone px4_ros_com
RUN git clone https://github.com/PX4/px4_ros_com.git $HOME/colcon_ws/src/px4_ros_com && \
    cd $HOME/colcon_ws/src/px4_ros_com && \
    git checkout $PX4_ROS_COM_COMMIT

# Clone px4_msgs
RUN git clone https://github.com/PX4/px4_msgs.git $HOME/colcon_ws/src/px4_msgs && \
    cd $HOME/colcon_ws/src/px4_msgs && \
    git checkout $PX4_MSGS_COMMIT

# Install PX4-Autopilot
RUN git clone https://github.com/PX4/PX4-Autopilot.git $HOME/PX4-Autopilot --recursive && \
    cd $HOME/PX4-Autopilot && \
    git checkout $PX4_AUTOPILOT_COMMIT && \
    bash $HOME/PX4-Autopilot/Tools/setup/ubuntu.sh --no-nuttx

# Mock GPS demo simulation configuration for typhoon_h480 build target
# In the future these should probably be made simulation parameters and not hard-coded here
RUN printf "\n\
param set-default NAV_ACC_RAD 20.0\n\
param set-default MPC_YAWRAUTO_MAX 10.0\n\
param set-default COM_POS_FS_DELAY 5\n\
param set-default EKF2_GPS_P_NOISE 10\n\
param set-default EKF2_GPS_V_NOISE 3\n\
param set-default SENS_GPS_MASK 2\n\
" >> $HOME/PX4-Autopilot/ROMFS/px4fmu_common/init.d-posix/airframes/6011_typhoon_h480

# Install pyyaml dependency and run the Python script
RUN pip3 install empy pyros-genmsg setuptools pyyaml
COPY scripts/configure_urtps_bridge_topics.py /
RUN sudo mv configure_urtps_bridge_topics.py $HOME/ &&\
    python3 $HOME/configure_urtps_bridge_topics.py

# Generate topics definition file for px4_ros_com and build ROS 2 workspace
RUN cd $HOME/PX4-Autopilot/Tools && sudo ./update_px4_ros2_bridge.sh --ws_dir $HOME/colcon_ws --all
RUN cd $HOME/colcon_ws/src/px4_ros_com/scripts &&\
    ./build_ros2_workspace.bash

# Make initial PX4 build
RUN cd $HOME/PX4-Autopilot && \
    make px4_sitl_rtps

COPY yaml/camera_calibration.yaml /
RUN sudo mv camera_calibration.yaml $HOME/

COPY yaml/gscam_params.yaml /
RUN sudo mv gscam_params.yaml $HOME/

COPY Makefile /
RUN sudo mv Makefile $HOME/

CMD cd $HOME && make HOME=$HOME gazebo
