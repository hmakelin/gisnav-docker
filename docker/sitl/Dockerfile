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
RUN sudo apt-get install libfuse2 && \
    sudo apt-get -y remove modemmanager && \
    sudo apt-get -y install gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl && \
    sudo apt-get -y install libqt5gui5 && \
    wget -P $HOME https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage && \
    chmod +x $HOME/QGroundControl.AppImage

# Clone px4_ros_com
RUN git clone https://github.com/PX4/px4_ros_com.git $HOME/colcon_ws/src/px4_ros_com

# Clone px4_msgs
RUN git clone https://github.com/PX4/px4_msgs.git $HOME/colcon_ws/src/px4_msgs

# Install PX4-Autopilot
# Install libignition-common3-core-dev and libignition-common3-av-dev separately with dpkg --force-overwrite enabled
RUN sudo apt-get -y install -o Dpkg::Options::="--force-overwrite" \
    libignition-common3-core-dev libignition-common3-av-dev
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
RUN cd $HOME/PX4-Autopilot && \
    echo "Building gazebo target..." && \
    (HEADLESS=1 make px4_sitl_rtps gazebo_typhoon_h480__ksql_airport &) | \
      grep -m 1 "Startup script returned successfully" && \
    pkill px4

COPY yaml/gscam_params.yaml /
RUN sudo mv gscam_params.yaml $HOME/

COPY yaml/camera_calibration.yaml /
RUN sudo mv camera_calibration.yaml $HOME/

COPY flight_plans/ksql_airport.plan /
RUN sudo mv ksql_airport.plan $HOME/

COPY scripts/Makefile /
RUN sudo mv Makefile $HOME/

# Launch Gazebo
CMD cd $HOME && make px4_gazebo

##################################
# ardupilot-sitl-dev BUILD STAGE #
##################################
FROM px4-sitl-dev as sitl-dev

ARG USERNAME=gisnav
USER $USERNAME

ARG ROS_DOMAIN_ID=0
ENV ROS_DOMAIN_ID=${ROS_DOMAIN_ID}

ARG LAUNCH_QGC=1
ENV LAUNCH_QGC=${LAUNCH_QGC}

# Install required and/or useful tools
RUN sudo apt-get update --fix-missing && \
    sudo apt-get -y install git gitk git-gui vim python3-pip wget curl python-is-python3 \
    ~nros-foxy-rqt* ros-foxy-gazebo-ros-pkgs && \
    pip install --upgrade pymavlink MAVProxy pexpect

# Clone ArduPilot and update submodules
RUN cd $HOME && \
    git clone https://github.com/ArduPilot/ardupilot && \
    cd ardupilot && \
    git submodule update --init --recursive

# Install ArduPilot prerequisites
# The script requires the USER env variable be set to ${USERNAME}
#RUN sudo usermod -a -G dialout $USERNAME
#RUN exec sg dialout newgrp `id -gn` && \
RUN cd $HOME/ardupilot/ && \
    export USER=$USERNAME && \
    Tools/environment_install/install-prereqs-ubuntu.sh -y && \
    . ~/.profile

# Update PATH
ENV PATH="/usr/lib/ccache:${PATH}:${HOME}/ardupilot/Tools/autotest"

# Install Gazebo plugin
RUN cd $HOME && \
    git clone https://github.com/hmakelin/ardupilot_gazebo && \
    cd ardupilot_gazebo && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j4 && \
    sudo make install

RUN echo 'source /usr/share/gazebo/setup.sh' >> ~/.bashrc && \
    echo 'export GAZEBO_MODEL_PATH=~/ardupilot_gazebo/models' >> ~/.bashrc && \
    echo 'export GAZEBO_RESOURCE_PATH=~/ardupilot_gazebo/worlds:${GAZEBO_RESOURCE_PATH}' >> ~/.bashrc

# Install MAVROS
RUN sudo apt-get -y install ros-foxy-mavros ros-foxy-mavros-extras
RUN cd $HOME && \
    wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh && \
    sudo bash ./install_geographiclib_datasets.sh

# Add KSQL airport location
# Disable GPS arming check (GPS2 will not work until already flying) and use best GPS
# Use MAVLink (14) for second GPS type
# Use 2D position only with EK2 (no velocity estimates)
RUN echo "KSQL_Airport=37.523640,-122.255122,1.7,90" >> $HOME/ardupilot/Tools/autotest/locations.txt && \
    echo "ARMING_CHECK 0" >> $HOME/ardupilot/Tools/autotest/default_params/gazebo-iris.parm && \
    echo "AHRS_EKF_TYPE 2" >> $HOME/ardupilot/Tools/autotest/default_params/gazebo-iris.parm && \
    echo "EK2_ENABLE 1" >> $HOME/ardupilot/Tools/autotest/default_params/gazebo-iris.parm && \
    echo "EK3_ENABLE 0" >> $HOME/ardupilot/Tools/autotest/default_params/gazebo-iris.parm && \
    echo "EK2_GPS_TYPE 2" >> $HOME/ardupilot/Tools/autotest/default_params/gazebo-iris.parm && \
    echo "GPS_TYPE2 14" >> $HOME/ardupilot/Tools/autotest/default_params/gazebo-iris.parm && \
    echo "SIM_GPS2_TYPE 14" >> $HOME/ardupilot/Tools/autotest/default_params/gazebo-iris.parm && \
    echo "GPS_AUTO_SWITCH 1" >> $HOME/ardupilot/Tools/autotest/default_params/gazebo-iris.parm

# Make initial build
RUN cd $HOME/ardupilot && \
    . ~/.profile && \
    $(python3 Tools/autotest/sim_vehicle.py -v ArduCopter -f gazebo-iris -L KSQL_Airport | grep -m 1 "BUILD SUMMARY") \
      || echo "Gazebo built."

COPY flight_plans/ksql_airport_ardupilot.plan /
RUN sudo mv ksql_airport_ardupilot.plan $HOME/

# Launch Gazebo
CMD cd $HOME && make px4_gazebo

####################
# sitl BUILD STAGE #
####################
FROM sitl-dev as sitl

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
CMD cd $HOME && make px4_gazebo
