SHELL:=/bin/bash

ardupilot_gazebo: qgc mavros
	cd ${HOME} && \
	source /opt/ros/foxy/setup.bash && \
	if [ -z ${GAZEBO_HEADLESS} ]; then \
		gazebo --verbose worlds/ksql_airport.world & \
	else \
		gzserver --verbose worlds/ksql_airport.world & \
	fi

px4_gazebo: gscam micrortps_agent qgc gisnav
	cd ${HOME}/PX4-Autopilot && \
	make HEADLESS=${GAZEBO_HEADLESS} px4_sitl_rtps gazebo_typhoon_h480__ksql_airport

gisnav:
	echo "Running GISNav." && \
	echo "nvidia-smi output:" && \
	nvidia-smi && \
	source /opt/ros/foxy/setup.bash && \
	source ${HOME}/colcon_ws/install/setup.bash && \
	cd ${HOME}/colcon_ws && \
	ros2 run gisnav mock_gps_node --ros-args --log-level info \
	  --params-file src/gisnav/config/typhoon_h480__ksql_airport.yaml &

gscam:
	source /opt/ros/foxy/setup.bash && \
	source ${HOME}/colcon_ws/install/setup.bash && \
	cd ${HOME}/colcon_ws && \
	ros2 run gscam gscam_node --ros-args --params-file ${HOME}/gscam_params.yaml \
		-p camera_info_url:=file://${HOME}/camera_calibration.yaml &

micrortps_agent:
	source /opt/ros/foxy/setup.bash && \
	source ${HOME}/colcon_ws/install/setup.bash && \
	cd ${HOME}/colcon_ws && \
	nohup micrortps_agent -t UDP &

qgc:
	if [ ${LAUNCH_QGC} -gt 0 ]; \
		then \
			echo "Launching QGC."; \
			nohup ${HOME}/QGroundControl.AppImage --appimage-extract-and-run & \
		else \
			echo "Skipping QGC launch."; \
	fi

sim_vehicle: ardupilot_gazebo
	cd ${HOME}/ardupilot && \
	source /opt/ros/foxy/setup.bash && \
	. ~/.profile && \
	sim_vehicle.py -v ArduCopter -f gazebo-iris -L KSQL_Airport

mavros:
	cd ${HOME} && \
	source /opt/ros/foxy/setup.bash && \
	. ~/.profile && \
	ros2 run mavros mavros_node --ros-args --param fcu_url:=udp://0.0.0.0:14551@14555 &
