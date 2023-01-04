SHELL:=/bin/bash

# Entrypoint for sitl-demo image
gazebo_with_gisnav: gisnav gazebo

# Entrypoint for sitl image
gazebo: qgc micro_ros_agent
	cd ${HOME}/PX4-Autopilot && \
	expect -c \
		"set timeout -1; \
		spawn make HEADLESS=${GAZEBO_HEADLESS} px4_sitl gazebo_typhoon_h480__ksql_airport; \
		expect \"Hit 'y' and <ENTER> to continue the build with this version. Hit <ENTER> to resolve manually.\"; \
		send \"y\n\"; \
		interact"

gisnav:
	echo "Running GISNav for PX4." && \
	nvidia-smi && \
	source /opt/ros/foxy/setup.bash && \
	source ${HOME}/colcon_ws/install/setup.bash && \
	cd ${HOME}/colcon_ws && \
	nohup ros2 launch gisnav px4.launch.py &

qgc:
	if [ ${LAUNCH_QGC} -gt 0 ]; \
		then \
			echo "Launching QGC."; \
			nohup ${HOME}/QGroundControl.AppImage --appimage-extract-and-run & \
		else \
			echo "Skipping QGC launch."; \
	fi

micro_ros_agent:
	source /opt/ros/foxy/setup.bash && \
	source ${HOME}/colcon_ws/install/setup.bash && \
	nohup ros2 run micro_ros_agent micro_ros_agent udp4 --port 8888 &
