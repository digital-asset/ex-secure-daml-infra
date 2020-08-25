#!/usr/local/bin/python
# Copyright (c) 2020 Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

import sys
import json
import base64
from jwcrypto import jwk,jwt, jws

def main(domain, certificate, signing_der, intermediate_der, root_der):
    key : "jwcrypto.jwk.JWK"
    with open("certs/signing/jwt-sign.{}.cert.pem".format(domain), "r") as pemfile:
        key = jwk.JWK.from_pem(pemfile.read().encode('UTF-8'))

    # Prepare fingerprint string
    cert_lines = certificate.splitlines()
    fingerprint = cert_lines.pop(0)
    fingerprint = fingerprint.split('=')[1].replace(':', '')
    fingerprint = fingerprint.encode("utf-8")
    x5t = str(base64.urlsafe_b64encode(fingerprint), 'utf-8')
    tmp_val = base64.urlsafe_b64decode(x5t)

    x5c = []
    x5c.append(signing_der)
    x5c.append(intermediate_der)
    x5c.append(root_der)

    tmp_json = json.loads(key.export_public())
    tmp_json['alg'] = "RS256"
    tmp_json['use'] = "sig"
    tmp_json['x5t'] = x5t # Base64_URL SHA-1 thumbprint of certificate
    tmp_json['x5c'] = x5c # "to be done" # X509 cerficiate or chain - JSON array of certificate value strings. Base64 DER PKIX certificate value

    final_json = {}
    final_json["keys"] = []
    final_json["keys"].append(tmp_json)

    with open("certs/jwt/jwks.json", "w") as jsonfile:
        json.dump(final_json, jsonfile)

if __name__ == '__main__':
    domain = sys.argv[1]
    certificate = sys.argv[2]
    signing_der = sys.argv[3]
    intermediate_der = sys.argv[4]
    root_der = sys.argv[5]
    main(domain, certificate, signing_der, intermediate_der, root_der)




