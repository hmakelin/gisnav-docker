# GISNav SITL Simulation Environment

This repository provides Docker scripts for building and running a PX4 SITL simulation environment for testing GISNav.

## Quick Start

If you have an NVIDIA GPU on your host machine, make sure you have [NVIDIA Container Toolkit installed][1].

Clone this repository:

```bash
cd $HOME
git clone https://github.com/hmakelin/gisnav-docker.git
```

Build the Docker image:

> **Note**
> Replace the example `MAPPROXY_TILE_URL` string below with your own tile-based endpoint url (e.g. WMTS). See
> [MapProxy configuration examples][2] for more information on how to format the string.

```bash
cd gisnav-docker
docker-compose build --build-arg MAPPROXY_TILE_URL="https://<your-map-server-url>/tiles/%(z)s/%(y)s/%(x)s"
```

Run the simulation:

```bash
docker-compose up -d
```

Stop the simulation:

```bash
docker-compose down
```

## Troubleshooting

If the Gazebo and QGroundControl windows do not appear on your screen some time after running your container (may take 
several minutes the first time when it builds your image), you may need to expose your ``xhost`` to your Docker 
container as described in the [ROS GUI Tutorial][3]:

```bash
export containerId=$(docker ps -l -q)
xhost +local:$(docker inspect --format='{{ .Config.Hostname }}' $containerId)
```

If you need to do debugging, use the following command to run a bash shell inside your container:

```bash
docker run -it --env="DISPLAY" --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" --gpus all --tty --network host \
  --entrypoint="/bin/bash" gisnav-docker_px4-sitl
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

## License

This software is released under the MIT license. See the `LICENSE.md` file for more information.

[1]: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
[2]: https://mapproxy.org/docs/latest/configuration_examples.html
[3]: http://wiki.ros.org/docker/Tutorials/GUI