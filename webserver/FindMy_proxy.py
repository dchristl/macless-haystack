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
        if hasattr(self.headers, 'getheader'):
          content_len = int(self.headers.getheader('content-length', 0))
        else:
          content_len = int(self.headers.get('content-length'))

        post_body = self.rfile.read(content_len)

        print('Getting with post: ' + str(post_body))
        UTCTime, Timezone, unixEpoch = getCurrentTimes()
        body = json.loads(post_body)
        if "days" in body:
            days = body['days']
        else: 
            days = 7
        print('Querying for ' + str(days) + ' days')
        startdate = (unixEpoch - 60 * 60 * 24 * days) * 1000
        data = '{"search": [{"ids": [\"%s\"]}]}' % ( "\",\"".join(body['ids']))

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
        result = json.loads(res.read())

        results = result["results"]

        newResults = [] 
        latestEntry = None
        
        for idx, entry in enumerate(results):
            if (int(entry["datePublished"]) > startdate):  
                newResults.append(entry)
            if latestEntry is None:
                latestEntry = entry
            elif latestEntry["datePublished"] < entry["datePublished"]:
                latestEntry = entry

        if days < 1 and latestEntry is not None:
            newResults.append(latestEntry)         
        result["results"] = newResults
        self.send_response(200)
        # send response headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        # send the body of the response
        responseBody = json.dumps(result)
        self.wfile.write(responseBody.encode())

        # print(responseBody)



if __name__ == "__main__":
    isV3 = sys.version_info.major > 2
    print('Using python3' if isV3 else 'Using python2')
    retrieveICloudKey()

    Handler = ServerHandler

    httpd = six.moves.socketserver.TCPServer(("", PORT), Handler)
    cert = 'certificate.pem'
    if os.path.isfile(cert):
        print("Certificate file "+ cert + " exists, so using SSL")
        httpd.socket = ssl.wrap_socket(httpd.socket, certfile=cert, server_side=True)
        print("serving at port " + str(PORT) + " over HTTPS")
    else:
       print("Certificate file "+ cert + " not found, so not using SSL") 
       print("serving at port " + str(PORT) + " over HTTP")


    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()
        print('Server stopped')
