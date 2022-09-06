############################
# px4-sitl-dev BUILD STAGE #
############################
FROM px4io/px4-dev-ros2-foxy as px4-sitl-dev

# See https://docs.ros.org/en/dashing/Concepts/About-Domain-ID.html
ARG ROS_DOMAIN_ID=0
ENV ROS_DOMAIN_ID=${ROS_DOMAIN_ID}

# Launch QGroundControl by default
ARG LAUNCH_QGC=1
ENV LAUNCH_QGC=${LAUNCH_QGC}

# Need --fix-missing to get OpenGL to work, sudo for creating user below
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

# Install controller/joystick support
RUN sudo apt-get -y install joystick jstest-gtk libcanberra-gtk-module libcanberra-gtk3-module
RUN mkdir -p $HOME/.config && \
    cd "$_" && \
    sudo touch jstest-gtk

# Install useful utilities
RUN sudo sudo apt-get -y install ~nros-foxy-rqt* vim

# Install QGroundControl
RUN sudo apt-get install libfuse2
RUN sudo apt-get -y remove modemmanager
RUN sudo apt-get -y install gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl
RUN sudo apt-get -y install libqt5gui5
RUN wget -P $HOME https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage
RUN chmod +x $HOME/QGroundControl.AppImage

# Clone px4_ros_com
RUN git clone https://github.com/PX4/px4_ros_com.git $HOME/colcon_ws/src/px4_ros_com

# Clone px4_msgs
RUN git clone https://github.com/PX4/px4_msgs.git $HOME/colcon_ws/src/px4_msgs

# Install PX4-Autopilot
RUN git clone https://github.com/PX4/PX4-Autopilot.git $HOME/PX4-Autopilot --recursive && \
    bash $HOME/PX4-Autopilot/Tools/setup/ubuntu.sh --no-nuttx

# Mock GPS demo simulation configuration for typhoon_h480 build target
# In the future these should probably be made simulation parameters and not hard-coded here
RUN printf "\n\
param set-default NAV_ACC_RAD 20.0\n\
param set-default MPC_YAWRAUTO_MAX 22.5.0\n\
param set-default COM_POS_FS_DELAY 5\n\
param set-default COM_POS_FS_EPH 10\n\
param set-default EKF2_GPS_P_NOISE 10\n\
param set-default EKF2_GPS_P_GATE 7\n\
param set-default EKF2_GPS_V_NOISE 3\n\
param set-default SENS_GPS_MASK 4\n\
" >> $HOME/PX4-Autopilot/ROMFS/px4fmu_common/init.d-posix/airframes/6011_typhoon_h480

# Install pyyaml dependency and run the Python script
RUN pip3 install empy pyros-genmsg setuptools pyyaml
COPY scripts/configure_urtps_bridge_topics.py /
RUN sudo mv configure_urtps_bridge_topics.py $HOME/ && \
    python3 $HOME/configure_urtps_bridge_topics.py

# Generate topics definition file for px4_ros_com and build ROS 2 workspace
RUN cd $HOME/PX4-Autopilot/Tools && sudo ./update_px4_ros2_bridge.sh --ws_dir $HOME/colcon_ws --all
RUN cd $HOME/colcon_ws/ && \
    src/px4_ros_com/scripts/build_ros2_workspace.bash --verbose

# --symlink-install (build_ros2_workspace.bash script) does not work with gisnav so re-build here if needed
RUN if ! [ -z "$WITH_GISNAV" ]; then \
        cd $HOME/colcon_ws && \
            colcon build --packages-select gisnav; \
    fi

# Before building PX4 target:
# Use non-default gst_udp_port so that QGC does not block the video stream
# TODO: make less brittle, might break or introduce unintended effects if jinja_gen.py is changed
RUN cd $HOME/PX4-Autopilot/Tools/simulation/gazebo/sitl_gazebo/scripts && \
    sed -i '0,/5600/{s//5601/}' jinja_gen.py

# Make initial PX4 build
# Piping the output to grep will make it stop once the "px4 starting." output is observed
# The first command will exit with an error code so it is "handled" with the last command after ||
RUN cd $HOME/PX4-Autopilot && \
    echo "Building gazebo target..." && \
    make px4_sitl_rtps gazebo_typhoon_h480__ksql_airport | grep -m 1 "px4 starting." || echo "Gazebo target built."

COPY yaml/camera_calibration.yaml /
RUN sudo mv camera_calibration.yaml $HOME/

COPY yaml/gscam_params.yaml /
RUN sudo mv gscam_params.yaml $HOME/

COPY flight_plans/ksql_airport.plan /
RUN sudo mv ksql_airport.plan $HOME/

COPY scripts/Makefile /
RUN sudo mv Makefile $HOME/

# Launch Gazebo
CMD cd $HOME && make gazebo

########################
# px4-sitl BUILD STAGE #
########################
FROM px4-sitl-dev as px4-sitl

ARG USERNAME=gisnav
USER $USERNAME

ARG ROS_DOMAIN_ID=0
ENV ROS_DOMAIN_ID=${ROS_DOMAIN_ID}

ARG LAUNCH_QGC=1
ENV LAUNCH_QGC=${LAUNCH_QGC}

# Install GISNav (part 1)
RUN cd $HOME/colcon_ws/src && \
    git clone https://github.com/hmakelin/gisnav.git && \
    cd gisnav && \
    git submodule update --init gisnav/pose_estimators/third_party/LoFTR

# Install GISNav (part 2)
RUN cd $HOME/colcon_ws/src/gisnav && \
    pip3 install -r requirements.txt && \
    pip3 install -r requirements-dev.txt

# Install GISNav (part 3)
RUN cd $HOME/colcon_ws/src/gisnav && \
    pip3 install gdown && \
    mkdir weights && \
    cd weights && \
    $HOME/.local/lib/$USERNAME/gdown https://drive.google.com/uc?id=1M-VD35-qdB5Iw-AtbDBCKC7hPolFW9UY

# Build gisnav ROS 2 package
RUN cd $HOME/colcon_ws && \
    colcon build --packages-select gisnav

# Launch GISNav
CMD cd $HOME && make gazebo_with_gisnav
