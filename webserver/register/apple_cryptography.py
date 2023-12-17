#!/usr/bin/env python

import os,glob,datetime,argparse
import base64,json
import hashlib,codecs,struct
import requests
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.backends import default_backend
import sqlite3
from .pypush_gsa_icloud import icloud_login_mobileme, generate_anisette_headers

import config

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
    return {'lat': latitude, 'lon': longitude, 'conf': confidence, 'status':status}

def getAuth(regenerate=False, second_factor='sms'):
    print(config.getConfig())
    if os.path.exists(config.getConfig()) and not regenerate:
        with open(config.getConfig(), "r") as f: j = json.load(f)
    else:
        mobileme = icloud_login_mobileme(second_factor=second_factor)

        print(mobileme)
        j = {'dsid': mobileme['dsid'], 'searchPartyToken': mobileme['delegates']['com.apple.mobileme']['service-data']['tokens']['searchPartyToken']}
        with open(config.getConfig(), "w") as f: json.dump(j, f)
    return (j['dsid'], j['searchPartyToken'])


def registerDevice():

    print(f'Registering new device.')
    getAuth(regenerate=True, second_factor='trusted_device' 'sms')


