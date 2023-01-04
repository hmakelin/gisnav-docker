ARG USERNAME=gisnav
ARG UID=1000
ARG GID=$UID
ARG AUTOPILOT=px4
###################
# px4 BUILD STAGE #
###################
FROM px4io/px4-dev-ros2-foxy as px4

ARG USERNAME
ARG UID
ARG GID

# Set 'gisnav' as default user and add it to sudo'ers
# QGroundControl will not run as 'root', sudo needed for installing to appropriate $HOME directory
RUN apt-get update --fix-missing && \
    apt-get install sudo && \
    groupadd --gid $GID $USERNAME && useradd --uid $UID --gid $GID -m $USERNAME && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
USER $USERNAME

# Install PX4-Autopilot, pull latest commit from PX4-SITL_gazebo submodule fork main branch
RUN sudo apt-get -y install -o Dpkg::Options::="--force-overwrite" \
        libignition-common3-core-dev libignition-common3-av-dev && \
    git clone --branch hmakelin-v1.14.0-beta1 \
        https://github.com/hmakelin/PX4-Autopilot.git $HOME/PX4-Autopilot --recursive && \
    cd $HOME/PX4-Autopilot && \
    git fetch --all --tags && \
    git checkout tags/v1.14.0-1.0.1-beta1 -b gisnav && \
    git submodule update --init --recursive && \
    cd Tools/simulation/gazebo/sitl_gazebo && \
    git pull origin hmakelin-v1.14.0-beta1 && \
    cd $HOME/PX4-Autopilot && \
    bash Tools/setup/ubuntu.sh --no-nuttx

# Install PX4-ROS 2 bridge dependencies
SHELL ["/bin/bash", "-c"]
RUN mkdir -p $HOME/colcon_ws/src/ && \
    cd $_ && \
    source /opt/ros/foxy/setup.bash && \
    git clone https://github.com/PX4/px4_msgs.git && \
    git clone -b foxy https://github.com/micro-ROS/micro_ros_setup.git && \
    cd .. && \
    rosdep update && \
    rosdep install --from-paths src --ignore-src -y && \
    colcon build && \
    source install/setup.bash && \
    ros2 run micro_ros_setup create_agent_ws.sh && \
    ros2 run micro_ros_setup build_agent.sh

# Make initial PX4 build (for faster startup in the future)
RUN cd $HOME/PX4-Autopilot && \
    echo "Building Gazebo target..." && \
    (echo "y" | HEADLESS=1 make px4_sitl gazebo_typhoon_h480__ksql_airport &) | \
      grep -m 1 "Startup script returned successfully" && \
    echo "Gazebo target built, killing px4 (may show error in logs)..." && \
    pkill px4 || /bin/true

# Copy and apply configuration files
COPY px4/* ./
RUN sudo mv -t $HOME/ /ksql_airport.plan /6011_typhoon_h480 /Makefile && \
    cat $HOME/6011_typhoon_h480 >> $HOME/PX4-Autopilot/ROMFS/px4fmu_common/init.d-posix/airframes/6011_typhoon_h480

#########################
# ardupilot BUILD STAGE #
#########################
FROM osrf/ros:foxy-desktop as ardupilot

ARG USERNAME
ARG UID
ARG GID

# Set 'gisnav' as default user and add it to sudo'ers
RUN apt-get update --fix-missing && \
    apt-get install sudo && \
    groupadd --gid $GID $USERNAME && useradd --uid $UID --gid $GID -m $USERNAME && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME
USER $USERNAME

# Install required tools
RUN sudo apt-get -y install git gitk git-gui python3-pip wget python-is-python3 ros-foxy-gazebo-ros-pkgs && \
    pip install --upgrade pymavlink MAVProxy pexpect

# Install MAVROS
RUN sudo apt-get -y install ros-foxy-mavros ros-foxy-mavros-extras && \
    cd $HOME && \
    wget https://raw.githubusercontent.com/mavlink/mavros/master/mavros/scripts/install_geographiclib_datasets.sh && \
    sudo bash ./install_geographiclib_datasets.sh

# Clone ArduPilot and update submodules
RUN cd $HOME && \
    git clone https://github.com/ArduPilot/ardupilot && \
    cd ardupilot && \
    git submodule update --init --recursive

# Install ArduPilot prerequisites
# The script requires the USER env variable be set to ${USERNAME}
RUN cd $HOME/ardupilot/ && \
    export USER=$USERNAME && \
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y keyboard-configuration && \
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
    sudo make install && \
    echo 'source /usr/share/gazebo/setup.sh' >> ~/.bashrc && \
    echo 'export GAZEBO_MODEL_PATH=~/ardupilot_gazebo/models' >> ~/.bashrc && \
    echo 'export GAZEBO_RESOURCE_PATH=~/ardupilot_gazebo/worlds:${GAZEBO_RESOURCE_PATH}' >> ~/.bashrc

# Make initial build
RUN cd $HOME/ardupilot && \
    . ~/.profile && \
    $(python3 Tools/autotest/sim_vehicle.py -v ArduCopter -f gazebo-iris -L KSQL_Airport | grep -m 1 "BUILD SUMMARY") \
      || echo "Gazebo built."

# Copy and apply configuration files, add SITL simulation demo location
COPY ardupilot/* ./
RUN sudo mv -t $HOME/ /ksql_airport.plan /gazebo-iris.parm /Makefile && \
    cat $HOME/gazebo-iris.parm >> $HOME/ardupilot/Tools/autotest/default_params/gazebo-iris.parm && \
    echo "KSQL_Airport=37.523640,-122.255122,1.7,90" >> $HOME/ardupilot/Tools/autotest/locations.txt

####################
# sitl BUILD STAGE #
####################
FROM $AUTOPILOT as sitl

ARG ROS_DOMAIN_ID=0
ENV ROS_DOMAIN_ID=${ROS_DOMAIN_ID}

ARG LAUNCH_QGC
ENV LAUNCH_QGC=${LAUNCH_QGC}

ARG USERNAME
USER $USERNAME

ARG DATE

# 1. Install Gazebo plugins, 2. for OpenGL to work, 3. expect for Makefile
RUN sudo apt-get -y install ros-foxy-gazebo-ros-pkgs expect && \
    sudo apt-get -y install --reinstall xserver-xorg-video-intel libgl1-mesa-glx libgl1-mesa-dri xserver-xorg-core && \
    sudo dpkg-reconfigure xserver-xorg

# Install QGroundControl
RUN sudo usermod -a -G dialout $USERNAME && \
    sudo apt-get -y remove modemmanager && \
    sudo apt-get -y install gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl && \
    sudo apt-get -y install libqt5gui5 && \
    sudo apt-get -y install libfuse2 && \
    wget -P $HOME https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage && \
    chmod +x $HOME/QGroundControl.AppImage

# Add build date label
LABEL "build.date"=$DATE

# Launch SITL simulation
CMD cd $HOME && make gazebo

####################
# demo BUILD STAGE #
####################
from sitl as sitl-demo

ARG ROS_DOMAIN_ID
ENV ROS_DOMAIN_ID=${ROS_DOMAIN_ID}

ARG LAUNCH_QGC
ENV LAUNCH_QGC=${LAUNCH_QGC}

ARG USERNAME
USER $USERNAME

# Install debugging utilities
RUN sudo apt-get -y install ~nros-foxy-rqt*

# Install controller/joystick support
RUN sudo apt-get -y install joystick jstest-gtk libcanberra-gtk-module libcanberra-gtk3-module && \
    mkdir -p $HOME/.config && \
    cd "$_" && \
    sudo touch jstest-gtk

# Install GISNav
RUN cd $HOME/colcon_ws/src && \
    git clone --branch hmakelin-update-px4-v1.14 https://github.com/hmakelin/gisnav.git && \
    git clone https://github.com/hmakelin/gisnav_msgs.git && \
    rosdep update && \
    rosdep install --from-paths . -y --ignore-src && \
    cd gisnav && \
    git submodule update --init gisnav/pose_estimators/third_party/LoFTR && \
    pip3 install -r requirements.txt && \
    pip3 install gdown && \
    mkdir weights && \
    cd weights && \
    $HOME/.local/lib/$USERNAME/gdown https://drive.google.com/uc?id=1M-VD35-qdB5Iw-AtbDBCKC7hPolFW9UY && \
    sudo apt-get -y dist-upgrade

# Build gisnav ROS 2 package
SHELL ["/bin/bash", "-c"]
RUN cd $HOME/colcon_ws && \
    source /opt/ros/foxy/setup.bash && \
    colcon build --packages-select gisnav gisnav_msgs

# Launch SITL simulation (with GISNav)
CMD cd $HOME && make gazebo_with_gisnav
