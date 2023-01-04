SHELL:=/bin/bash

# Entrypoint for sitl-demo image
gazebo_with_gisnav: gisnav sim_vehicle

# Entrypoint for sitl image
gazebo: gz_server_client mavros
	cd ${HOME}/ardupilot && \
	source /opt/ros/foxy/setup.bash && \
	source ~/.profile && \
	python3 Tools/autotest/sim_vehicle.py -v ArduCopter -f gazebo-iris -L KSQL_Airport \
		-m '--cmd="module load GPSInput"'

gz_server_client: qgc
	cd ${HOME} && \
	source /opt/ros/foxy/setup.bash && \
	source /usr/share/gazebo/setup.sh && \
	source ~/.profile && \
	if [ -z ${GAZEBO_HEADLESS} ]; then \
		echo "Launching Gazebo client & server..."; \
		nohup gazebo --verbose worlds/ksql_airport.world & \
	else \
		echo "Launching Gazebo in headless mode..."; \
		nohup gzserver --verbose worlds/ksql_airport.world & \
	fi

gisnav:
	echo "Running GISNav for ArduPilot (ArduCopter)." && \
	nvidia-smi && \
	source /opt/ros/foxy/setup.bash && \
	source ${HOME}/colcon_ws/install/setup.bash && \
	cd ${HOME}/colcon_ws && \
	nohup ros2 launch gisnav ardupilot.launch.py &

qgc:
	if [ ${LAUNCH_QGC} -gt 0 ]; \
		then \
			echo "Launching QGC."; \
			nohup ${HOME}/QGroundControl.AppImage --appimage-extract-and-run & \
		else \
			echo "Skipping QGC launch."; \
	fi

mavros:
	cd ${HOME} && \
	source /opt/ros/foxy/setup.bash && \
	source /usr/share/gazebo/setup.sh && \
	source ~/.profile && \
	ros2 run mavros mavros_node --ros-args --param fcu_url:=udp-b://127.0.0.1:14551@14555 &
