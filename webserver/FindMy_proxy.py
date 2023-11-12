#!/usr/bin/env python

import json
import ssl
import sys
import six
import os
import requests
import datetime, time


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
        UTCTime, Timezone, unixEpoch = self.getCurrentTimes()
        body = json.loads(post_body)
        if "days" in body:
            days = body['days']
        else: 
            days = 7
        print('Querying for ' + str(days) + ' days')
        startdate = (unixEpoch - 60 * 60 * 24 * days) * 1000
        data = { "search": [{"startDate": startdate *1000, "endDate": unixEpoch *1000, "ids": body['ids']}] }

        try:
            r = requests.post("https://gateway.icloud.com/acsnservice/fetch", auth=self.getAuth(), headers=json.loads(requests.get('http://' + anisette + ':' + port, timeout=10).text), json=data)
            result = json.loads(r.content.decode())
            results = result['results']

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
        except requests.exceptions.ConnectTimeout:
            print("Timeout to " + anisette + ", is your anisette running and accepting Connections?")
            self.send_response(504)

    def getCurrentTimes(self):
        clientTime = datetime.datetime.utcnow().replace(microsecond=0).isoformat() + 'Z'
        clientTimestamp = int(datetime.datetime.now().strftime('%s'))
        return clientTime, time.tzname[1], clientTimestamp

    def getAuth(self):
        CONFIG_PATH = "openhaystack.json"
        if os.path.exists(CONFIG_PATH):
            with open(CONFIG_PATH, "r") as f:
                j = json.load(f)
                return (j['ds_prs_id'], j['search_party_token'])
        else:
            print(f'No search-party-token found, please run ../token-generator/pypush/examples/openhaystack.py as described in the README or use the docker container in ../token-generator/')
            exit(1)



if __name__ == "__main__":
    isV3 = sys.version_info.major > 2
    print('Using python3' if isV3 else 'Using python2')

    script_directory = os.path.dirname(os.path.abspath(__file__))

    os.chdir(script_directory)

    anisette = os.environ.get("ANISETTE_IP", "localhost")
    port = os.environ.get("ANISETTE_PORT", "6969")

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
