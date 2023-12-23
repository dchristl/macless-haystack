import logging
import os

PORT = 6176
CONFIG_PATH = "data"
CONFIG_FILE = "auth.json"
CERT_FILE = "certificate.pem"  # optional
KEY_FILE = "privkey.pem"  # optional


def getConfigPath():
    script_path = os.path.abspath(__file__)
    return CONFIG_PATH if os.path.isabs(CONFIG_PATH) else os.path.dirname(script_path) + '/' + CONFIG_PATH


def getConfigFile():
    return getConfigPath() + '/' + CONFIG_FILE


def getCertFile():
    return getConfigPath() + '/' + CERT_FILE


def getKeyFile():
    return getConfigPath() + '/' + KEY_FILE


logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')
