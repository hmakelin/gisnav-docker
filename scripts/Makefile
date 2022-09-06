SHELL:=/bin/bash

gazebo: gscam micrortps_agent qgc
	cd ${HOME}/PX4-Autopilot && \
	make HEADLESS=${GAZEBO_HEADLESS} px4_sitl_rtps gazebo_typhoon_h480__ksql_airport

gazebo_with_gisnav: gscam micrortps_agent qgc gisnav
	cd ${HOME}/PX4-Autopilot && \
	make HEADLESS=${GAZEBO_HEADLESS} px4_sitl_rtps gazebo_typhoon_h480__ksql_airport

gisnav:
	echo "Running GISNav." && \
	echo "nvidia-smi output:" && \
	nvidia-smi && \
	source /opt/ros/foxy/setup.bash && \
	source ${HOME}/colcon_ws/install/setup.bash && \
	cd ${HOME}/colcon_ws && \
	nohup ros2 run gisnav mock_gps_node --ros-args --log-level info \
	  --params-file src/gisnav/config/typhoon_h480__ksql_airport.yaml &

gscam:
	source /opt/ros/foxy/setup.bash && \
	source ${HOME}/colcon_ws/install/setup.bash && \
	cd ${HOME}/colcon_ws && \
	nohup ros2 run gscam gscam_node --ros-args --params-file ${HOME}/gscam_params.yaml \
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
