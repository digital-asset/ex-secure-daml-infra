#!/usr/local/bin/python
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

from http.server import HTTPServer, BaseHTTPRequestHandler
import ssl
from jwcrypto import jwt, jwk
import json
import time
import logging
import sys
import urllib.parse

signing_key = None
signing_kid = None
ledger_id = ""
clients = None
logger = None

class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_response(500)
        self.end_headers()
        self.wfile.write(b'Service does expect GET requests')

    def do_POST(self):

        global signing_key
        global signing_kid
        global clients
        global ledger_id

        logger.debug(self.headers)
        if self.headers.get('Content-Length', None) == None:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b'No credential data sent')
            return

        content_length = int(self.headers['Content-Length'])
        body = self.rfile.read(content_length)

        body_json = None
        if self.headers['Content-Type'] == 'application/x-www-form-urlencoded':
            try:
                body_json = urllib.parse.parse_qs(body.decode('UTF-8'))
                logger.error(body_json)
                client_id = body_json['client_id'][0]
                client_secret = body_json['client_secret'][0]
                grant_type = body_json['grant_type'][0]
                audience = body_json['audience'][0]

            except Exception as ex:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b'Error processing request')
                return

        if self.headers['Content-Type'] == 'application/json':
            try:
                body_json = json.loads(body)
                logger.error(body_json)
                client_id = body_json['client_id']
                client_secret = body_json['client_secret']
                grant_type = body_json['grant_type']
                audience = body_json['audience']
            except Exception as ex:
                self.send_response(500)
                self.end_headers()
                self.wfile.write(b'Error processing request')
                return

        if grant_type != 'client_credentials':
            logger.error("Invalid grant_type")
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b'Invalid grant_type requested')
            return

        if audience != "https://daml.com/ledger-api":
            logger.error("Invalid audience")
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b'Invalid audience requested')
            return

        current_client = clients.get(client_id, None)
        if current_client == None:
            logger.error("Invalid credentials")
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b'Invalid credentials provided')
            return

        if current_client['secret'] != client_secret:
            logger.error("Invalid credentials")
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b'Invalid credentials provided')
            return

        issue_at = int(time.time())
        expiry_time = int(issue_at + 24*60*60)
        logger.debug("Issued At: " + str(issue_at))
        logger.debug("Expires At: " + str(expiry_time))

        header = {"alg":"RS256","typ":"JWT", "kid": "" }
        header['kid'] = str(signing_kid)

        payload = {
            "https://daml.com/ledger-api": {
                "ledgerId": ledger_id,
                "admin": current_client['admin'] == "True",
                "actAs": current_client['parties'],
                "readAs": current_client['parties']
            },
            "exp": expiry_time,
            "aud": "https://daml.com/ledger-api",
            "azp": current_client['azp'],
            "iss": "local-jwt-provider",
            "iat": issue_at,
            "gty": "client-credentials",
            "sub": current_client['azp'] + "@clients"
        }
        if (current_client.get("application_id", None) == None ):
            pass
        else:
            payload["https://daml.com/ledger-api"]['applicationId'] = current_client['application_id']

        token = jwt.JWT(header=header, claims=payload)
        token.make_signed_token(signing_key)

        response_token = {
            "access_token": token.serialize(),
            "token_type": "Bearer",
            "expires_at": expiry_time
        }
        response_string = json.dumps(response_token)

        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()

        self.wfile.write(response_string.encode('UTF-8'))

def init_logger():
    logger = logging.getLogger()

    h = logging.StreamHandler(sys.stdout)
    h.flush = sys.stdout.flush
    logger.addHandler(h)

    return logger

def main(argv):

    global signing_key
    global signing_kid
    global clients
    global ledger_id
    global logger

    logger = init_logger()
    logger.setLevel(logging.DEBUG)

    logging.info("Starting Auth Service...")
    logging.info(argv)

    # Get signing private key
    with open(argv[0], "r") as key_file:
        key_bytes = key_file.read()
        signing_key = jwk.JWK.from_pem(key_bytes.encode('UTF-8'), password=None)
        logging.info(signing_key.key_id)

    # Get signing Key ID
    with open(argv[1], "r") as json_file:
        jwks = json.load(json_file)
    signing_kid = jwks['keys'][0]['kid']

    # Get authentication database (Hack as this is a JSON file)
    with open(argv[2],"r") as client_file:
        clients = json.load(client_file)

    ledger_id = argv[3]

    # Run web service
    httpd = HTTPServer(('', 4443), SimpleHTTPRequestHandler)
    httpd.socket = ssl.wrap_socket (httpd.socket,
                                keyfile=argv[4],
                                certfile=argv[5], server_side=True)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass

    httpd.server_close()

if __name__ == '__main__':
    main(sys.argv[1:])
