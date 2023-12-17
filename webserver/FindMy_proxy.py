#!/usr/bin/env python

import json
import ssl
import sys
import six
import os
import requests
from datetime import datetime
import time
# import logging
import config
from http.client import HTTPConnection
import base64
from collections import OrderedDict

from register import apple_cryptography, pypush_gsa_icloud

# HTTPConnection.debuglevel = 1
# logging.basicConfig()
# logging.getLogger().setLevel(logging.DEBUG)
# requests_log = logging.getLogger("requests.packages.urllib3")
# requests_log.setLevel(logging.DEBUG)
# requests_log.propagate = True


class ServerHandler(six.moves.SimpleHTTPServer.SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200, "ok")
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header("Access-Control-Allow-Headers", "X-Requested-With")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_POST(self):
        if hasattr(self.headers, 'getheader'):
            content_len = int(self.headers.getheader('content-length', 0))
        else:
            content_len = int(self.headers.get('content-length'))

        post_body = self.rfile.read(content_len)

        print('Getting with post: ' + str(post_body))
        body = json.loads(post_body)
        if "days" in body:
            days = body['days']
        else:
            days = 7
        print('Querying for ' + str(days) + ' days')
        unixEpoch = int(datetime.now().strftime('%s'))
        startdate = unixEpoch - (60 * 60 * 24 * days)

        dt_object = datetime.fromtimestamp(startdate)

        print(dt_object.strftime('%Y-%m-%d %H:%M:%S'))
        # Date is always one, because it has no effect
        data = {"search": [
            {"startDate": 1, "ids": list(body['ids'])}]}

        try:
            r = requests.post("https://gateway.icloud.com/acsnservice/fetch",  auth=getAuth(regenerate=False, second_factor='sms'),
                              headers=pypush_gsa_icloud.generate_anisette_headers(),
                              json=data)
            print(r.status_code)

            result = json.loads(r.content.decode())
            results = result['results']

            latestTimestamp = None
            newResults = OrderedDict()

            for idx, entry in enumerate(results):
                data = base64.b64decode(entry['payload'])
                timestamp = int.from_bytes(data[0:4], 'big') + 978307200
                if (timestamp > startdate):
                    newResults[timestamp] = entry
                if latestTimestamp is None or latestTimestamp < timestamp:
                    latestTimestamp = timestamp
                    newResults.clear()
                    newResults[timestamp] = entry

            sorted_map = OrderedDict(sorted(newResults.items(), reverse=True))
            for key, value in sorted_map.items():
                dt_object = datetime.fromtimestamp(key)
                human_readable_format = dt_object.strftime('%Y-%m-%d %H:%M:%S')
                print(f"Key: {human_readable_format}")
                
                
            result["results"] = list(sorted_map.values())
            self.send_response(200)
            # send response headers
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            

            # send the body of the response
            responseBody = json.dumps(result)
            self.wfile.write(responseBody.encode())

            # print(responseBody)
        except requests.exceptions.ConnectTimeout:
            print("Timeout to " + anisette +
                  ", is your anisette running and accepting Connections?")
            self.send_response(504)

    def getCurrentTimes(self):
        clientTime = datetime.utcnow().replace(microsecond=0).isoformat() + 'Z'
        clientTimestamp = int(datetime.now().strftime('%s'))
        return clientTime, time.tzname[1], clientTimestamp


def getAuth(regenerate=False, second_factor='sms'):
    if os.path.exists(config.getConfig()) and not regenerate:
        with open(config.getConfig(), "r") as f:
            j = json.load(f)
    else:
        mobileme = pypush_gsa_icloud.icloud_login_mobileme(
            second_factor=second_factor)
        print('Mobileme' + mobileme)
        j = {'dsid': mobileme['dsid'], 'searchPartyToken': mobileme['delegates']
             ['com.apple.mobileme']['service-data']['tokens']['searchPartyToken']}
        with open(config.getConfig(), "w") as f:
            json.dump(j, f)
    return (j['dsid'], j['searchPartyToken'])


if __name__ == "__main__":

    script_directory = os.path.dirname(os.path.abspath(__file__))

    os.chdir(script_directory)

    if not os.path.exists(config.getConfig()):
        print(f'No token found.')
        apple_cryptography.registerDevice()

    anisette = os.environ.get("ANISETTE_IP", "localhost")
    port = os.environ.get("ANISETTE_PORT", "6969")

    Handler = ServerHandler

    httpd = six.moves.socketserver.TCPServer(("", config.PORT), Handler)
    cert = 'certificate.pem'
    if os.path.isfile(cert):
        print("Certificate file " + cert + " exists, so using SSL")
        httpd.socket = ssl.wrap_socket(
            httpd.socket, certfile=cert, server_side=True)
        print("serving at port " + str(config.PORT) + " over HTTPS")
    else:
        print("Certificate file " + cert + " not found, so not using SSL")
        print("serving at port " + str(config.PORT) + " over HTTP")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()
        print('Server stopped')
