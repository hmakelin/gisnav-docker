SHELL:=/bin/bash

gazebo: gscam micrortps_agent qgc
	cd ${HOME}/PX4-Autopilot && \
	make HEADLESS=${GAZEBO_HEADLESS} px4_sitl_rtps gazebo_typhoon_h480__ksql_airport

gscam:
	source /opt/ros/foxy/setup.bash && \
	source $HOME/colcon_ws/install/setup.bash && \
	cd ${HOME}/colcon_ws && \
	nohup ros2 run gscam gscam_node --ros-args --params-file ${HOME}/gscam_params.yaml \
		-p camera_info_url:=file://${HOME}/camera_calibration.yaml &

micrortps_agent:
	source /opt/ros/foxy/setup.bash && \
	source $HOME/colcon_ws/install/setup.bash && \
	cd ${HOME}/colcon_ws && \
	nohup micrortps_agent -t UDP &

qgc:
	nohup ${HOME}/QGroundControl.AppImage --appimage-extract-and-run &