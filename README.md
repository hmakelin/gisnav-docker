# GISNav SITL Environments

This repository contains scripts for building development, testing and demonstration SITL environments for [GISNav][1]. 
The `docker-compose.yaml` file defines the following services:

[1]: https://github.com/hmakelin/gisnav

| Name                     | Description                                                                                                                                                                                                                         |
|--------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| <nobr>`sitl`</nobr>      | SITL simulation environment: PX4 or ArduPilot, Gazebo, QGroundcontrol, and optionally GISNav (see [Overrides](#overrides)).                                                                                                         |
| <nobr>`mapserver`</nobr> | WMS server with self-hosted [NAIP][2] and [OSM Buildings][3] data covering KSQL airport.                                                                                                                                            |
| <nobr>`mapproxy`</nobr>  | WMS proxy for existing remote tile-based imagery endpoint. Alternative for `mapserver` when imagery layer needs to cover multiple flight regions (over presumedly multiple test scenarios covering too large an area to self-host). |

[2]: https://en.wikipedia.org/wiki/National_Agriculture_Imagery_Program
[3]: https://osmbuildings.org/

## Quick Start

Follow these instructions to launch the SITL simulation used in the [mock GPS demo][4].

[4]: https://github.com/hmakelin/gisnav/blob/master/README.md#mock-gps-example

### Clone

If you have an NVIDIA GPU on your host machine, make sure you have [NVIDIA Container Toolkit installed][5].

[5]: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html

Clone this repository and change to its root directory:

```bash
cd $HOME
git clone https://github.com/hmakelin/gisnav-docker.git
cd gisnav-docker
```

### Build

To build the `sitl` service, run the following command:

```bash
docker-compose -f docker-compose.yaml -f docker-compose.demo.yaml build sitl
```

### Run

**Option 1:** Run the SITL simulation with locally hosted maps:

```bash
docker-compose up -f docker-compose.yaml -f docker-compose.demo.yaml up mapserver sitl
```

**Option 2:** Run the SITL simulation with a WMS proxy:

> **Note**
> Replace the example `MAPPROXY_TILE_URL` string below with your own tile-based endpoint url (e.g. WMTS). See
> [MapProxy configuration examples][6] for more information on how to format the string.

[6]: https://mapproxy.org/docs/latest/configuration_examples.html

```bash
docker-compose build \
  --build-arg MAPPROXY_TILE_URL="https://<your-map-server-url>/tiles/%(z)s/%(y)s/%(x)s" \
  mapproxy
docker-compose -f docker-compose.yaml -f docker-compose.demo.yaml up mapproxy sitl
```

### Shutdown

```bash
docker-compose down
```

## Overrides

To launch the `sitl` service without GISNav, simply drop all the overrides used in the [Quick Start](#run):

> **Note**
> This default launch configuration for `sitl` is intended for use in local development, and in automated testing 
> where GISNav is installed by a CI pipeline

```bash
docker-compose up sitl
```

To launch the `sitl` service with ArduPilot instead of PX4, use the `docker-compose.ardupilot.yaml` override:

```bash
docker-compose -f docker-compose.yaml -f docker-compose.ardupilot.yaml up sitl
```

## Build Arguments

Provide an optional `DATE` build argument to attach a `build.date` label to the `sitl` and `mapserver` images:

```bash
docker-compose build --buildarg DATE=$(date '+%Y-%m-%d') mapserver sitl
```

## Troubleshooting

### Prebuilt Docker images
The versions of the dependencies of the Docker script are currently not fixed, and many of them are under active 
development. The script may therefore break and make building the images challenging. You can try out these pre-built 
images for the mock GPS demo:

* [gisnav-sitl][7]
* [gisnav-mapserver][8]

[7]: https://hub.docker.com/r/hmakelin/gisnav-sitl
[8]: https://hub.docker.com/r/hmakelin/gisnav-mapserver

### Expose `xhost`

If the Gazebo and QGroundControl windows do not appear on your screen soon after running your container you may need to 
expose your ``xhost`` to your Docker container as described in the [ROS GUI Tutorial][9]:

[9]: http://wiki.ros.org/docker/Tutorials/GUI

```bash
export containerId=$(docker ps -l -q)
xhost +local:$(docker inspect --format='{{ .Config.Hostname }}' $containerId)
```

### Headless mode

If you are doing automated testing ([e.g. with mavsdk][10]), you can run Gazebo in **headless mode** and not launch
QGroundControl by setting `GAZEBO_HEADLESS=1` and `LAUNCH_QGC=0`:

[10]: https://github.com/hmakelin/gisnav/blob/master/test/sitl/sitl_test_mock_gps_node.py

```bash
GAZEBO_HEADLESS=1 LAUNCH_QGC=0 docker-compose up -d mapserver sitl
```

### Set `ROS_DOMAIN_ID`

If you do not seem to be receiving any telemetry from the container to your host's ROS 2 node, ensure the
`ROS_DOMAIN_ID` environment variable on your host matches the container's *(0 by default)*:

```bash
export ROS_DOMAIN_ID=0
```

### Run shell inside container

If you need to do debugging on `sitl`, you can use the following command to run bash inside the container:

```bash
docker run -it \
  --env="DISPLAY" \
  --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
  --volume "/dev/shm:/dev/shm" \
  --volume="/dev/dri:/dev/dri" \
  --gpus all \
  --tty \
  --network host \
  --entrypoint="/bin/bash" \
  gisnav-docker_sitl
```

### Disable Fast DDS on host

> [RTPS_TRANSPORT_SHM Error] Failed init_port fastrtps_port7412: open_and_lock_file failed -> Function 
> open_port_internal

If you are not able to establish ROS communication between the container and the host when using the 
`docker-compose.dev.yaml` override and receive the above error, try disabling Fast DDS on your host. 
You can do so by creating an XML configuration (e.g. `disable_fastrtps.xml`) as described in [this comment][11] and 
restarting ROS 2 daemon with the new configuration:

[11]: https://github.com/eProsima/Fast-DDS/issues/1698#issuecomment-778039676

```bash
export FASTRTPS_DEFAULT_PROFILES_FILE=$PWD/disable_fastrtps.xml
ros2 daemon stop
ros2 daemon start
```

### Disable AppArmor for ArduPilot SITL

**Caution advised**: If QGroundControl or Gazebo do not seem to be starting when using the 
`docker-compose.ardupilot.yaml` override, you may need to run the `sitl` image with 
`--security-opt apparmor:unconfined` or `--privileged` options.

## License

This software is released under the MIT license. See the `LICENSE.md` file for more information.
