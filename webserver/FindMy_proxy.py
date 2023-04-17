#!/usr/bin/env python

import base64
import json
import six
import ssl
import sys

from apple_cryptography import *


PORT = 6176

class ServerHandler(six.moves.SimpleHTTPServer.SimpleHTTPRequestHandler):
    def do_OPTIONS(self):
        self.send_response(200, "ok")
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header("Access-Control-Allow-Headers", "X-Requested-With")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_POST(self):
        content_len = int(self.headers.getheader('content-length', 0))

        post_body = self.rfile.read(content_len)

        print('Getting with post: ' + post_body)
        UTCTime, Timezone, unixEpoch = getCurrentTimes()
        body = json.loads(post_body)
        startdate = unixEpoch - 60 * 60 * 24 * 7
        data = '{"search": [{"endDate": %d, "startDate": %d, "ids": [\"%s\"]}]}' % (
            (unixEpoch - 978307200) * 1000000, (startdate - 978307200)*1000000, "\",\"".join(body['ids']))

        print(data)
        iCloud_decryptionkey = retrieveICloudKey()
        AppleDSID, searchPartyToken = getAppleDSIDandSearchPartyToken(
            iCloud_decryptionkey)
        machineID, oneTimePassword = getOTPHeaders()
        UTCTime, Timezone, unixEpoch = getCurrentTimes()

        request_headers = {
            'Authorization': "Basic %s" % (base64.b64encode((AppleDSID + ':' + searchPartyToken).encode('ascii')).decode('ascii')),
            'X-Apple-I-MD': "%s" % (oneTimePassword),
            'X-Apple-I-MD-RINFO': '17106176',
            'X-Apple-I-MD-M': "%s" % (machineID),
            'X-Apple-I-TimeZone': "%s" % (Timezone),
            'X-Apple-I-Client-Time': "%s" % (UTCTime),
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'X-BA-CLIENT-TIMESTAMP': "%s" % (unixEpoch)
        }

        conn = six.moves.http_client.HTTPSConnection(
            'gateway.icloud.com', timeout=5, context=ssl._create_unverified_context())
        conn.request("POST", "/acsnservice/fetch", data, request_headers)
        res = conn.getresponse()
        # self.wfile.write(res.read())

        self.send_response(200)
        # send response headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        # send the body of the response
        responseBody = res.read()
        self.wfile.write(responseBody)

        print(responseBody)



if __name__ == "__main__":
    isV3 = sys.version_info.major > 2
    print('Using python3' if isV3 else 'Using python2')
    retrieveICloudKey()

    Handler = ServerHandler

    httpd = six.moves.socketserver.TCPServer(("", PORT), Handler)

    print("serving at port " + str(PORT))

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()
        print('Server stopped')
