#!/usr/bin/env python3
"""Call the official App Store Connect API using an existing local team key.

Credentials stay in process memory. Supply ASC_KEY_ID, ASC_ISSUER_ID and
ASC_KEY_PATH, or the equivalent command-line options. No key is created.
"""
import argparse
import base64
import json
import os
from pathlib import Path
import subprocess
import time
from urllib.error import HTTPError
from urllib.request import Request, urlopen


def token(key_id, issuer, key_path):
    encode = lambda data: base64.urlsafe_b64encode(data).rstrip(b'=')
    header = encode(json.dumps(dict(alg='ES256', kid=key_id, typ='JWT')).encode())
    body = encode(json.dumps(dict(iss=issuer, iat=int(time.time()), exp=int(time.time()) + 300,
                                 aud='appstoreconnect-v1')).encode())
    payload = header + b'.' + body
    der = subprocess.check_output(['openssl', 'dgst', '-sha256', '-sign', str(key_path)], input=payload)
    assert der[0] == 0x30 and der[2] == 2
    length = der[3]; r = int.from_bytes(der[4:4+length], 'big'); offset = 4 + length
    assert der[offset] == 2
    length = der[offset+1]; s = int.from_bytes(der[offset+2:offset+2+length], 'big')
    return (payload + b'.' + encode(r.to_bytes(32, 'big') + s.to_bytes(32, 'big'))).decode()


def request(path, key_id, issuer, key_path, method='GET', body=None):
    assert path.startswith('/v1/'), 'Only official /v1 API paths are accepted'
    headers = {'Authorization': 'Bearer ' + token(key_id, issuer, key_path), 'Content-Type': 'application/json'}
    data = json.dumps(body).encode() if body is not None else None
    with urlopen(Request('https://api.appstoreconnect.apple.com' + path, data=data, headers=headers, method=method), timeout=60) as response:
        raw = response.read()
    return json.loads(raw) if raw else {}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('path')
    parser.add_argument('--key-id', default=os.environ.get('ASC_KEY_ID'))
    parser.add_argument('--issuer', default=os.environ.get('ASC_ISSUER_ID'))
    parser.add_argument('--key-path', type=Path, default=os.environ.get('ASC_KEY_PATH'))
    parser.add_argument('--method', default='GET', choices=['GET', 'POST', 'PATCH', 'DELETE'])
    parser.add_argument('--body', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    if not all([args.key_id, args.issuer, args.key_path]):
        parser.error('An existing key ID, issuer and local private-key path are required')
    try:
        result = request(args.path, args.key_id, args.issuer, args.key_path, args.method,
                         json.loads(args.body.read_text()) if args.body else None)
    except HTTPError as error:
        print(f'App Store Connect HTTP {error.code}: {error.read().decode()}')
        raise SystemExit(1)
    text = json.dumps(result, indent=2) + '\n'
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True); args.output.write_text(text)
        print('Saved API response to', args.output)
    else:
        print(text, end='')
