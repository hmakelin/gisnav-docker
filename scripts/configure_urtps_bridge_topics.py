"""Configures uORB RTPS topics

This script configures the topics in urtps_bridge_topics.yaml microRTPS bridge client definition file in the
PX4-Autopilot/msg/tools/ folder for use in GISNav SITL simulation.

Note: This script is not compatible with the older uorb_rtps_message_ids.yaml file (pre-v1.13.0).
"""
import yaml
import os

DEFINITION_FILE = f'{os.environ.get("HOME", "")}/PX4-Autopilot/msg/tools/urtps_bridge_topics.yaml'

SEND_TOPICS = ['vehicle_local_position', 'vehicle_global_position', 'vehicle_attitude', 'gimbal_device_set_attitude']
RECEIVE_TOPICS = ['sensor_gps']  # vehicle_gps_position was removed: https://github.com/PX4/PX4-Autopilot/commit/152230


def add_send_true_to_dict(d: dict):
    """Updates input dict with send: True flag if the msg key is in SEND_TOPICS."""
    if d.get('msg', None) in SEND_TOPICS:
        d.update({'send': True})
    return d


def add_receive_true_to_dict(d: dict):
    """Updates input dict with receive: True flag if the msg key is in RECEIVE_TOPICS."""
    if d.get('msg', None) in RECEIVE_TOPICS:
        d.update({'receive': True})
    return d


def configure_file(file):
    """Adds send: True and receive: True flags to appropriate topics."""
    definition = None
    with open(file, 'r') as f:
        try:
            definition = yaml.safe_load(f)
        except yaml.YAMLError as _:
            # TODO?
            raise

        topic_list = definition.get('rtps', {})

        for topic in SEND_TOPICS:
            topic_index = next((i for (i, d) in enumerate(topic_list) if d["msg"] == topic), None)
            if topic_index is not None:
                topic_list[topic_index].update({'send': True})
            else:
                topic_list.append({'msg': topic, 'send': True})

        for topic in RECEIVE_TOPICS:
            topic_index = next((i for (i, d) in enumerate(topic_list) if d["msg"] == topic), None)
            if topic_index is not None:
                topic_list[topic_index].update({'receive': True})
            else:
                topic_list.append({'msg': topic, 'receive': True})

        definition.update({'rtps': topic_list})

    with open(file, 'w') as f:
        try:
            yaml.dump(definition, f)
        except yaml.YAMLError as _:
            # TODO?
            raise


if __name__ == '__main__':
    if os.path.exists(DEFINITION_FILE):
        configure_file(DEFINITION_FILE)
    else:
        raise FileNotFoundError(f'RTPS bridge topics definition file "{DEFINITION_FILE}" not found.')
