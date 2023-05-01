#!/usr/bin/env python 

import argparse, json, ssl

from apple_cryptography import *

OUTPUT_FOLDER = 'output/'

if __name__ == "__main__":
    isV3 =  sys.version_info.major > 2
    print('Using python3' if isV3 else 'Using python2')
    parser = argparse.ArgumentParser()
    parser.add_argument('-H', '--hours', help='only show reports not older than these hours', type=int, default=24)
    parser.add_argument('-p', '--prefix', help='only use keyfiles starting with this prefix', default='')
    parser.add_argument('-k', '--key', help="iCloud decryption key ($ security find-generic-password -ws 'iCloud')")
    args = parser.parse_args()
    iCloud_decryptionkey = args.key if args.key else retrieveICloudKey()

    AppleDSID,searchPartyToken = getAppleDSIDandSearchPartyToken(iCloud_decryptionkey)
    machineID, oneTimePassword = getOTPHeaders()
    UTCTime, Timezone, unixEpoch = getCurrentTimes()

    request_headers = {
        'Authorization': "Basic %s" % (base64.b64encode((AppleDSID + ':' + searchPartyToken).encode('ascii')).decode('ascii')),
        'X-Apple-I-MD': "%s" % (oneTimePassword),
        'X-Apple-I-MD-RINFO': '17106176',
        'X-Apple-I-MD-M': "%s" % (machineID) ,
        'X-Apple-I-TimeZone': "%s" % (Timezone),
        'X-Apple-I-Client-Time': "%s" % (UTCTime),
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-BA-CLIENT-TIMESTAMP': "%s" % (unixEpoch)
    }

    ids = {}
    names = {}
    for keyfile in glob.glob(OUTPUT_FOLDER  + args.prefix+'*.keys'):
        # read key files generated with generate_keys.py
        with open(keyfile) as f:
            hashed_adv = ''
            priv = ''
            name = keyfile[len(args.prefix):-5]
            for line in f:
                key = line.rstrip('\n').split(': ')
                if key[0] == 'Private key':
                    priv = key[1]
                elif key[0] == 'Hashed adv key':
                    hashed_adv = key[1]

                if priv and hashed_adv:
                    ids[hashed_adv] = priv
                    names[hashed_adv] = name

    startdate = unixEpoch - 60 * 60 * args.hours
    startdate = unixEpoch - 60 * 60 * args.hours

    keys = '","'.join(ids.keys())

    data = '{"search": [{"endDate": %d, "startDate": %d, "ids":["%s"]}]}' % ((unixEpoch -978307200) *1000000, (startdate -978307200)*1000000, keys)
    print(data)
    
    conn = six.moves.http_client.HTTPSConnection('gateway.icloud.com', timeout=5, context=ssl._create_unverified_context())
    
    conn.request("POST", "/acsnservice/fetch", data, request_headers)
    response = conn.getresponse()
    print(response.status, response.reason)
    res = json.loads(response.read())['results']
    print('%d reports received.' % len(res))

    ordered = []
    found = set()
    for report in res:
        priv = bytes_to_int(base64.b64decode(ids[report['id']]))
        data = base64.b64decode(report['payload'])

        # the following is all copied from https://github.com/hatomist/openhaystack-python, thanks @hatomist!
        timestamp = bytes_to_int(data[0:4])
        if timestamp + 978307200 >= startdate:
            eph_key = ec.EllipticCurvePublicKey.from_encoded_point(ec.SECP224R1(), data[5:62])
            shared_key = ec.derive_private_key(priv, ec.SECP224R1(), default_backend()).exchange(ec.ECDH(), eph_key)
            symmetric_key = sha256(shared_key + b'\x00\x00\x00\x01' + data[5:62])
            decryption_key = symmetric_key[:16]
            iv = symmetric_key[16:]
            enc_data = data[62:72]
            tag = data[72:]

            decrypted = decrypt(enc_data, algorithms.AES(decryption_key), modes.GCM(iv, tag))
            res = decode_tag(decrypted)
            res['timestamp'] = timestamp + 978307200
            res['isodatetime'] = datetime.datetime.fromtimestamp(res['timestamp']).isoformat()
            res['key'] = names[report['id']]
            res['goog'] = 'https://maps.google.com/maps?q=' + str(res['lat']) + ',' + str(res['lon'])
            found.add(res['key'])
            ordered.append(res)
    
    print('%d reports used.' % len(ordered))
    ordered.sort(key=lambda item: item.get('timestamp'))
    for rep in ordered: print(rep)
    print('found:   ', list(found))
    print('missing: ', [key for key in names.keys() if key not in found])