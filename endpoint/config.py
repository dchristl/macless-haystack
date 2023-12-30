import logging
import os
import configparser


CONFIG_PATH = "data"
CONFIG_FILE = "auth.json"
CERT_FILE = "certificate.pem"  # optional
KEY_FILE = "privkey.pem"  # optional


def getConfigPath():
    script_path = os.path.abspath(__file__)
    return CONFIG_PATH if os.path.isabs(CONFIG_PATH) else os.path.dirname(script_path) + '/' + CONFIG_PATH


config = configparser.ConfigParser()
config.read(getConfigPath() + '/config.ini')


def getAnisetteServer():
    return config.get('Settings', 'anisette_url', fallback='http://anisette:6969')

def getPort():
    return int(config.get('Settings', 'port', fallback='6176'))

def getUser():
    return config.get('Settings', 'user', fallback=None)


def getPass():
    return config.get('Settings', 'pass', fallback=None)



def getConfigFile():
    return getConfigPath() + '/' + CONFIG_FILE


def getCertFile():
    return getConfigPath() + '/' + CERT_FILE


def getKeyFile():
    return getConfigPath() + '/' + KEY_FILE


def getLogLevel():
    logLevel = config.get('Settings', 'loglevel', fallback='INFO')
    return logging.getLevelName(logLevel)


logging.basicConfig(level=getLogLevel(),
                    format='%(asctime)s - %(levelname)s - %(message)s')
