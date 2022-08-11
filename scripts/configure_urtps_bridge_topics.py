"""Configure uORB RTPS message IDs

This script configures the topics in either the uorb_rtps_message_ids.yaml or urtsp_bridge_topics.yaml microRTPS bridge
client definition file in the PX4-Autopilot/msg/tools/ folder for use in GISNav SITL simulation.
"""
import yaml
import os

# Note: the urtps_bridge_topics.yaml file used to be called uorb_rtps_message_ids.yaml, format has also changed
DEFINITION_FILE_NEW = f'{os.environ.get("HOME", "")}/PX4-Autopilot/msg/tools/urtps_bridge_topics.yaml'
DEFINITION_FILE_OLD = f'{os.environ.get("HOME", "")}/PX4-Autopilot/msg/tools/uorb_rtps_message_ids.yaml'

SEND_TOPICS = ['vehicle_local_position', 'vehicle_global_position', 'vehicle_attitude', 'gimbal_device_set_attitude']
RECEIVE_TOPICS = ['vehicle_gps_message']


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

        if file == DEFINITION_FILE_NEW:
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

        elif file == DEFINITION_FILE_OLD:
            topic_list = list(map(add_send_true_to_dict, topic_list))
            topic_list = list(map(add_receive_true_to_dict, topic_list))

        definition.update({'rtps': topic_list})

    with open(file, 'w') as f:
        try:
            yaml.dump(definition, f)
        except yaml.YAMLError as _:
            # TODO?
            raise


if __name__ == '__main__':
    if os.path.exists(DEFINITION_FILE_NEW):
        configure_file(DEFINITION_FILE_NEW)
    elif os.path.exists(DEFINITION_FILE_OLD):
        configure_file(DEFINITION_FILE_OLD)
    else:
        raise FileNotFoundError(f'RTPS bridge topics definition file not found in {os.environ.get("HOME", "")}/PX4'
                                f'-Autopilot/msg/tools/.')
