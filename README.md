# GISNav Docker Scripts

This repository provides Docker scripts for building portable SITL development, testing and demonstration 
environments for [GISNav][1]. The `docker-compose.yaml` file defines the following services:

| Service name                 | Description                                                                                                                                                                                                                         |
|------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| <nobr>`sitl`</nobr>          | SITL simulation environment: PX4/ArduPilot, Gazebo and QGroundcontrol, GISNav optional (see [overrides](#overrides)).                                                                                                  |
| <nobr>`mapserver`</nobr>     | WMS server with embedded [NAIP][3] and [OSM Buildings][4] data covering KSQL airport.                                                                                                                                               |
| <nobr>`mapproxy`</nobr>      | WMS proxy for existing remote tile-based imagery endpoint. Alternative for `mapserver` when imagery layer needs to cover multiple flight regions (over presumedly multiple test scenarios covering too large an area to host locally). |

## Quick Start

Follow these instructions to build the Docker images that are needed to run the [mock GPS demo][2].

### Setup

If you have an NVIDIA GPU on your host machine, make sure you have [NVIDIA Container Toolkit installed][5].

Clone this repository and change to its root directory:

```bash
cd $HOME
git clone https://github.com/hmakelin/gisnav-docker.git
cd gisnav-docker
```

### Run

**Option 1:** Run the SITL simulation with locally hosted maps:

```bash
docker-compose up -d mapserver sitl
```

**Option 2:** Run the SITL simulation with a WMS proxy:

> **Note**
> Replace the example `MAPPROXY_TILE_URL` string below with your own tile-based endpoint url (e.g. WMTS). See
> [MapProxy configuration examples][6] for more information on how to format the string.

```bash
docker-compose build \
  --build-arg MAPPROXY_TILE_URL="https://<your-map-server-url>/tiles/%(z)s/%(y)s/%(x)s" \
  mapproxy
docker-compose up mapproxy sitl
```

### Shutdown

```bash
docker-compose down
```

### Overrides

To launch the SITL simulation with ArduPilot instead of PX4, use the `docker-compose.ardupilot.yaml` overrides:

```bash
docker-compose -f docker-compose.yaml -f docker-compose.ardupilot.yaml up -d sitl
```

To build the `sitl` image without GISNav (for use in e.g. automated testing where GISNav is installed by a CI pipeline), use the `docker-compose.dev.yaml` overrides:

```bash
docker-compose -f docker-compose.yaml -f docker-compose.dev.yaml build -d sitl
```

## Troubleshooting

If the Gazebo and QGroundControl windows do not appear on your screen soon after running your container you may need to 
expose your ``xhost`` to your Docker container as described in the [ROS GUI Tutorial][7]:

```bash
export containerId=$(docker ps -l -q)
xhost +local:$(docker inspect --format='{{ .Config.Hostname }}' $containerId)
```

If you do not seem to be receiving any telemetry from the container to your host's ROS 2 node, ensure the
`ROS_DOMAIN_ID` environment variable on your host matches the container's *(0 by default)*:

```bash
export ROS_DOMAIN_ID=0
```

If you are doing automated testing ([e.g. with mavsdk][8]), you can run Gazebo in headless mode and not launch 
QGroundControl by setting `GAZEBO_HEADLESS=1` and `LAUNCH_QGC=0`:

```bash
GAZEBO_HEADLESS=1 LAUNCH_QGC=0 docker-compose up -d mapserver sitl
```

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

## Repository Structure

This repository is structured as follows:

```
.
├── docker
│   ├── mapproxy
│   │    └── Dockerfile                     # Dockerfile for a standalone MapProxy server
│   └── sitl
│        └── Dockerfile                     # Dockerfile for the Gazebo simulation & dependencies
├── docker-compose.ardupilot.yaml           # docker-compose ArduPilot entrypoint override
├── docker-compose.dev.yaml                 # docker-compose sitl-dev build target
├── docker-compose.yaml                     # docker-compose base configuration
├── flight_plans
│    └── ksql_airport.plan                  # Sample flight plan for SITL
├── LICENSE.md
├── mapfiles
│    └── wms.map                            # Mapfile for setting up WMS on MapServer
├── mapproxy
│    └── mapproxy.yaml                      # Configuration file used by mapproxy
├── README.md
├── scripts
│    └── configure_urtps_bridge_topics.py   # Configuration script used by px4-sitl-dev
│    └── Makefile                           # Makefile used by SITL images
│    └── setup_mapserver.sh                 # Configuration script used by mapserver
└── yaml
    ├── camera_calibration.yaml             # Configuration file used by px4-sitl-dev
    └── gscam_params.yaml                   # Configuration file used by px4-sitl-dev

8 directories, 15 files
```

## License

This software is released under the MIT license. See the `LICENSE.md` file for more information.

[1]: https://github.com/hmakelin/gisnav
[2]: https://github.com/hmakelin/gisnav/blob/master/README.md#mock-gps-example
[3]: https://en.wikipedia.org/wiki/National_Agriculture_Imagery_Program
[4]: https://osmbuildings.org/
[5]: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
[6]: https://mapproxy.org/docs/latest/configuration_examples.html
[7]: http://wiki.ros.org/docker/Tutorials/GUI
[8]: https://github.com/hmakelin/gisnav/blob/master/test/sitl/sitl_test_mock_gps_node.py
