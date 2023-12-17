import os

PORT = 6176
CONFIG_PATH = "data/openhaystack.json"


def getConfig():
    script_path = os.path.abspath(__file__)
    return CONFIG_PATH if os.path.isabs(CONFIG_PATH) else os.path.dirname(script_path) + '/' + CONFIG_PATH
