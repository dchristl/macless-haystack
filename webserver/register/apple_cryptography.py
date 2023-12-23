#!/usr/bin/env python

import os
import glob
import datetime
import argparse
import base64
import json
import hashlib
import codecs
import struct
import requests
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.backends import default_backend
import sqlite3
from .pypush_gsa_icloud import icloud_login_mobileme, generate_anisette_headers

import config
import logging
logger = logging.getLogger()


def sha256(data):
    digest = hashlib.new("sha256")
    digest.update(data)
    return digest.digest()


def decrypt(enc_data, algorithm_dkey, mode):
    decryptor = Cipher(algorithm_dkey, mode, default_backend()).decryptor()
    return decryptor.update(enc_data) + decryptor.finalize()


def decode_tag(data):
    latitude = struct.unpack(">i", data[0:4])[0] / 10000000.0
    longitude = struct.unpack(">i", data[4:8])[0] / 10000000.0
    confidence = int.from_bytes(data[8:9])
    status = int.from_bytes(data[9:10])
    return {'lat': latitude, 'lon': longitude, 'conf': confidence, 'status': status}


def getAuth(regenerate=False, second_factor='sms'):
    if os.path.exists(config.getConfigFile()) and not regenerate:
        with open(config.getConfigFile(), "r") as f:
            j = json.load(f)
    else:
        mobileme = icloud_login_mobileme(second_factor=second_factor)

        logger.warn('Answer from icloud login')
        logger.warn(mobileme)
        
        j = {'dsid': mobileme['dsid'], 'searchPartyToken': mobileme['delegates']
             ['com.apple.mobileme']['service-data']['tokens']['searchPartyToken']}
        with open(config.getConfigFile(), "w") as f:
            json.dump(j, f)
    return (j['dsid'], j['searchPartyToken'])


def registerDevice():

    logger.info(f'Trying to register new device.')
    getAuth(regenerate=True, second_factor='trusted_device' 'sms')
