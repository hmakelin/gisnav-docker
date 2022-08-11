# GISNav SITL Environment

This repository provides Docker scripts for building and running the PX4 SITL environment for testing GISNav.

> **Note**
>
> Work-in-progress: These containers may not yet build

## Quick Start

Clone this repository:

```bash
cd $HOME
git clone https://github.com/hmakelin/gisnav-docker.git
```

Build the Docker image:

```bash
cd gisnav-docker
NVIDIA_DRIVER_MAJOR_VERSION=$(nvidia-smi |grep -oP 'Driver Version: \K[\d{3}]+')
docker-compose build \
    --build-arg MAPPROXY_TILE_URL="https://example.server.com/tiles/%(z)s/%(y)s/%(x)s" \
    --build-arg NVIDIA_DRIVER_MAJOR_VERSION=$NVIDIA_DRIVER_MAJOR_VERSION
```

Replace the example string used below for `MAPPROXY_TILE_URL` with your own tile-based endpoint url (e.g. WMTS). See
[MapProxy configuration examples](https://mapproxy.org/docs/latest/configuration_examples.html) for more information on
how to format the string.

If you have an Nvidia GPU you should also add a build argument with the major version number of a driver that is
compatible with your hardware, such as `--build-arg NVIDIA_DRIVER_MAJOR_VERSION=470`, to the build command below or 
look it up with `nvidia-smi`. You can also search for available drivers with `apt search nvidia-driver`.

Run the simulation:

```
docker-compose up -d
```

Stop the simulation:

```
docker-compose down
```

### Troubleshooting

If the Gazebo and QGroundControl windows do not appear on your screen some time after running your container (may take 
several minutes the first time when it builds your image), you may need expose your ``xhost`` to your Docker container 
as described in the [ROS GUI Tutorial](http://wiki.ros.org/docker/Tutorials/GUI):

```bash
export containerId=$(docker ps -l -q)
xhost +local:$(docker inspect --format='{{ .Config.Hostname }}' $containerId)
```

## Repository Structure

This repository is structured as follows:

```
.
├── docker
│   ├── mapproxy
│   │    └── Dockerfile                     # Dockerfile for a standalone MapProxy server
│   └── px4-sitl
│        └── Dockerfile                     # Dockerfile for the PX4 Gazebo simulator & dependencies
├── docker-compose.yaml
├── LICENSE.md
├── Makefile                                # Makefile used by px4-sitl (used inside container, not on host)
├── README.md
├── scripts
│    └── configure_urtps_bridge_topics.py   # Configuration script used by px4-sitl
└── yaml
    ├── camera_calibration.yaml             # Configuration file used by px4-sitl
    ├── gscam_params.yaml                   # Configuration file used by px4-sitl
    └── mapproxy.yaml                       # Configuration file used by mapproxy

5 directories, 10 files
```

# License

This software is released under the MIT license. See the `LICENSE.md` file for more information.
