#!/usr/bin/env python

import json
import ssl
import sys
import os
import requests
from datetime import datetime
import time
import config
from http.client import HTTPConnection
import base64
from collections import OrderedDict

from http.server import BaseHTTPRequestHandler, HTTPServer

from register import apple_cryptography, pypush_gsa_icloud

import logging
logger = logging.getLogger()


class ServerHandler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200, "ok")
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header("Access-Control-Allow-Headers", "X-Requested-With")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        self.send_response(404)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b"Nothing to see here")

    def do_POST(self):
        if hasattr(self.headers, 'getheader'):
            content_len = int(self.headers.getheader('content-length', 0))
        else:
            content_len = int(self.headers.get('content-length'))

        post_body = self.rfile.read(content_len)

        logger.debug('Getting with post: ' + str(post_body))
        body = json.loads(post_body)
        if "days" in body:
            days = body['days']
        else:
            days = 7
        logger.debug('Querying for ' + str(days) + ' days')
        unixEpoch = int(datetime.now().strftime('%s'))
        startdate = unixEpoch - (60 * 60 * 24 * days)

        dt_object = datetime.fromtimestamp(startdate)

        # Date is always 1, because it has no effect
        data = {"search": [
            {"startDate": 1, "ids": list(body['ids'])}]}

        try:
            r = requests.post("https://gateway.icloud.com/acsnservice/fetch",  auth=getAuth(regenerate=False, second_factor='sms'),
                              headers=pypush_gsa_icloud.generate_anisette_headers(),
                              json=data)
            logger.debug('Return from fetch service:')
            result = json.loads(r.content.decode())
            logger.debug(result)
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

            result["results"] = list(sorted_map.values())
            self.send_response(200)
            # send response headers
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()

            # send the body of the response
            responseBody = json.dumps(result)
            self.wfile.write(responseBody.encode())

        except requests.exceptions.ConnectTimeout:
            logger.error("Timeout to " + anisette +
                         ", is your anisette running and accepting Connections?")
            self.send_response(504)

    def getCurrentTimes(self):
        clientTime = datetime.utcnow().replace(microsecond=0).isoformat() + 'Z'
        clientTimestamp = int(datetime.now().strftime('%s'))
        return clientTime, time.tzname[1], clientTimestamp


def getAuth(regenerate=False, second_factor='sms'):
    if os.path.exists(config.getConfigFile()) and not regenerate:
        with open(config.getConfigFile(), "r") as f:
            j = json.load(f)
    else:
        mobileme = pypush_gsa_icloud.icloud_login_mobileme(username=config.USER, password= config.PASS,
            second_factor=second_factor)
        logger.debug('Mobileme result: ' + mobileme)
        j = {'dsid': mobileme['dsid'], 'searchPartyToken': mobileme['delegates']
             ['com.apple.mobileme']['service-data']['tokens']['searchPartyToken']}
        with open(config.getConfigFile(), "w") as f:
            json.dump(j, f)
    return (j['dsid'], j['searchPartyToken'])


if __name__ == "__main__":

    logging.debug(f'Searching for token at ' + config.getConfigFile())
    if not os.path.exists(config.getConfigFile()):
        logging.info(f'No auth-token found.')
        apple_cryptography.registerDevice()

    anisette = os.environ.get("ANISETTE_IP", "localhost")
    port = os.environ.get("ANISETTE_PORT", "6969")

    Handler = ServerHandler
    httpd = HTTPServer(('localhost', config.PORT), Handler)
    if os.path.isfile(config.getCertFile()):
        logger.info("Certificate file " + config.getCertFile() + " exists, so using SSL")
        ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ssl_context.load_cert_chain(certfile=config.getCertFile(
        ), keyfile=config.getKeyFile() if os.path.isfile(config.getKeyFile()) else None)

        httpd.socket = ssl_context.wrap_socket(httpd.socket, server_side=True)

        logger.info("serving at port " + str(config.PORT) + " over HTTPS")
    else:
        logger.info("Certificate file " + config.getCertFile() +
              " not found, so not using SSL")
        logger.info("serving at port " + str(config.PORT) + " over HTTP")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()
        logger.info('Server stopped')
