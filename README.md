# GISNav SITL Simulation Environment

This repository provides Docker scripts for building and running a PX4 SITL simulation environment for testing GISNav.

The following services are included:
* The `px4-sitl` service launches a PX4 SITL simulation in Gazebo along with supporting services, excluding the WMS
  endpoint.
* The `mapserver` service leverages the `camptocamp/mapserver` image on Docker Hub to add a WMS endpoint with locally 
  hosted high-resolution aerial imagery from [NAIP][1] that covers the SITL simulation area.
* The `mapproxy` service can be used as an alternative WMS endpoint for development and testing if you already have a 
  tile-based endpoint for high-resolution imagery available.

## Quick start

### Setup

If you have an NVIDIA GPU on your host machine, make sure you have [NVIDIA Container Toolkit installed][2].

Clone this repository:

```bash
cd $HOME
git clone https://github.com/hmakelin/gisnav-docker.git
```

### Option 1: With embedded maps (`mapserver` + `px4-sitl`)
Build the images:

> **Note**
> Leave out the `WITH_GISNAV` build argument if you intend to run GISNav on your host or install it separately (e.g. 
> building a base image for automated testing of latest GISNav version in a GitHub Actions workflow).

```bash
cd $HOME/gisnav-docker
docker-compose build mapserver px4-sitl --build-arg WITH_GISNAV
```

Run the containers:

```bash
docker-compose up -d mapserver px4-sitl
```

### Option 2: With MapProxy (`mapproxy` + `px4-sitl`)

Build the images:

> **Note**
> * Replace the example `MAPPROXY_TILE_URL` string below with your own tile-based endpoint url (e.g. WMTS). See
>   [MapProxy configuration examples][3] for more information on how to format the string.
> * Leave out the `WITH_GISNAV` build argument if you intend to run GISNav on your host or install it separately (e.g. 
>   building a base image for automated testing of latest GISNav version in a GitHub Actions workflow).

```bash
cd $HOME/gisnav-docker
docker-compose build mapproxy mapserver \
  --build-arg WITH_GISNAV \
  --build-arg MAPPROXY_TILE_URL="https://<your-map-server-url>/tiles/%(z)s/%(y)s/%(x)s" \
```

Run the containers:

```bash
docker-compose up -d mapproxy px4-sitl
```

### Shutdown all services

```bash
cd $HOME/gisnav-docker
docker-compose down
```

### Troubleshooting

If the Gazebo and QGroundControl windows do not appear on your screen some time after running your container (may take 
several minutes the first time when it builds your image), you may need to expose your ``xhost`` to your Docker 
container as described in the [ROS GUI Tutorial][4]:

```bash
export containerId=$(docker ps -l -q)
xhost +local:$(docker inspect --format='{{ .Config.Hostname }}' $containerId)
```

If you are trying to connect to the PX4-ROS 2 bridge inside the container from the host but it seems like the messages 
are not coming through, ensure your `ROS_DOMAIN_ID` environment variable on your host matches what is used inside the 
container *(0 by default)*:

```bash
export ROS_DOMAIN_ID=0
```

If the Gazebo simulation feels slow or you are doing automated testing, you can run it in headless mode by passing the 
`GAZEBO_HEADLESS=1` environment variable:

```bash
GAZEBO_HEADLESS=1 docker-compose up -d mapserver px4-sitl
```

If you need to do debugging on `px4-sitl`, you can use the following command to run a bash shell inside your container:

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
  gisnav-docker_px4-sitl
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
├── flight_plans
│    └── ksql_airport.plan                  # Sample flight plan for px4-sitl image
├── LICENSE.md
├── Makefile                                # Makefile used by px4-sitl (used inside container, not on host)
├── mapfiles
│    └── wms.map                            # Mapfile for setting up WMS on MapServer
├── README.md
├── scripts
│    └── configure_urtps_bridge_topics.py   # Configuration script used by px4-sitl
│    └── setup_mapserver.hs                 # Configuration script used by mapserver
└── yaml
    ├── camera_calibration.yaml             # Configuration file used by px4-sitl
    ├── gscam_params.yaml                   # Configuration file used by px4-sitl
    └── mapproxy.yaml                       # Configuration file used by mapproxy

7 directories, 13 files
```

## License

This software is released under the MIT license. See the `LICENSE.md` file for more information.

[1]: https://en.wikipedia.org/wiki/National_Agriculture_Imagery_Program
[2]: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
[3]: https://mapproxy.org/docs/latest/configuration_examples.html
[4]: http://wiki.ros.org/docker/Tutorials/GUI
