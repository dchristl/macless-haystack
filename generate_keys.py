#!/usr/bin/env python
import sys
import base64
import hashlib
import random
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.backends import default_backend
import argparse
import shutil
import os
import string
from string import Template
import struct

OUTPUT_FOLDER = 'output/'
TEMPLATE = Template('{'
                    '\"id\": $id,'
                    '\"colorComponents\": ['
                    '    0,'
                    '    1,'
                    '    0,'
                    '    1'
                    '],'
                    '\"name\": \"$name\",'
                    '\"privateKey\": \"$privateKey\",'
                    '\"icon\": \"\",'
                    '\"isDeployed\": true,'
                    '\"colorSpaceName\": \"kCGColorSpaceExtendedSRGB\",'
                    '\"usesDerivation\": false,'
                    '\"isActive\": false,'
                    '\"additionalKeys\": [$additionalKeys]'
                    '}')


def int_to_bytes(n, length, endianess='big'):
    h = '%x' % n
    s = ('0'*(len(h) % 2) + h).zfill(length*2).decode('hex')
    return s if endianess == 'big' else s[::-1]


def to_C_byte_array(adv_key, isV3):
    out = '{'
    for element in range(0, len(adv_key)):
        e = adv_key[element] if isV3 else ord(adv_key[element])
        out = out + "0x{:02x}".format(e)
        if element != len(adv_key)-1:
            out = out + ','

    out = out + '}'
    return out


def sha256(data):
    digest = hashlib.new("sha256")
    digest.update(data)
    return digest.digest()


parser = argparse.ArgumentParser()
parser.add_argument(
    '-n', '--nkeys', help='number of keys to generate', type=int, default=1)
parser.add_argument('-p', '--prefix', help='prefix of the keyfiles')
parser.add_argument(
    '-y', '--yaml', help='yaml file where to write the list of generated keys')
parser.add_argument(
    '-v', '--verbose', help='print keys as they are generated', action="store_true")
parser.add_argument(

    '-tinfs', '--thisisnotforstalking', help=argparse.SUPPRESS)   

args = parser.parse_args()

MAX_KEYS = 1

if (args.thisisnotforstalking == 'i_agree'):
    MAX_KEYS = 50

 
if args.nkeys < 1 or args.nkeys > MAX_KEYS:
    raise argparse.ArgumentTypeError(
        "Number of keys out of range (between 1 and " + str(MAX_KEYS) + ")")


current_directory = os.getcwd()
final_directory = os.path.join(current_directory, OUTPUT_FOLDER)

if os.path.exists(OUTPUT_FOLDER):
    shutil.rmtree(OUTPUT_FOLDER)

os.mkdir(final_directory)


prefix = ''

if args.prefix is None:
    prefix = ''.join(random.choice(string.ascii_uppercase +
                     string.digits) for _ in range(6))
else:
    prefix = args.prefix

if args.yaml:
    yaml = open(OUTPUT_FOLDER + prefix + '_' + args.yaml + '.yaml', 'w')
    yaml.write('  keys:\n')


keyfile = open(OUTPUT_FOLDER + prefix + '_keyfile', 'wb')

keyfile.write(struct.pack("B", args.nkeys))

devices = open(OUTPUT_FOLDER + prefix + '_devices.json', 'w')
devices.write('[\n')

fname = '%s.keys' % (prefix)
keys = open(OUTPUT_FOLDER + fname, 'w')


isV3 = sys.version_info.major > 2
print('Using python3' if isV3 else 'Using python2')
print(f'Output will be written to {OUTPUT_FOLDER}')
additionalKeys = []
i = 0
while i < args.nkeys:
    priv = random.getrandbits(224)
    adv = ec.derive_private_key(priv, ec.SECP224R1(
    ), default_backend()).public_key().public_numbers().x
    if isV3:
        priv_bytes = priv.to_bytes(28, 'big')
        adv_bytes = adv.to_bytes(28, 'big')
    else:
        priv_bytes = int_to_bytes(priv, 28)
        adv_bytes = int_to_bytes(adv, 28)

    priv_b64 = base64.b64encode(priv_bytes).decode("ascii")
    adv_b64 = base64.b64encode(adv_bytes).decode("ascii")
    s256_b64 = base64.b64encode(sha256(adv_bytes)).decode("ascii")

    if '/' in s256_b64[:7]:
        print(
            'Key skipped and regenerated, because there was a / in the b64 of the hashed pubkey :(')
        continue
    else:
        i += 1

    keyfile.write(base64.b64decode(adv_b64))

    if i < args.nkeys:
        additionalKeys.append(priv_b64)  # The last one is the leading one

    if args.verbose:
        print('%d)' % (i+1))
        print('Private key: %s' % priv_b64)
        print('Advertisement key: %s' % adv_b64)
        print('Hashed adv key: %s' % s256_b64)

    if '/' in s256_b64[:7]:
        print(
            'no key file written, there was a / in the b64 of the hashed pubkey :(')
    else:
        keys.write('Private key: %s\n' % priv_b64)
        keys.write('Advertisement key: %s\n' % adv_b64)
        keys.write('Hashed adv key: %s\n' % s256_b64)
        if args.yaml:
            yaml.write('    - "%s"\n' % adv_b64)

addKeysS = ''
if (len(additionalKeys) > 0):
    addKeysS = "\"" + "\",\"".join(additionalKeys) + "\""


devices.write(TEMPLATE.substitute(name=prefix,
                                  id=str(random.choice(
                                      range(0, 10000000))),
                                  privateKey=priv_b64,
                                  additionalKeys=addKeysS
                                  ))

devices.write(']')
