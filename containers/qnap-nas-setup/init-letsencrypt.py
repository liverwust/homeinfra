#!/usr/bin/python3
# https://github.com/wmnnd/nginx-certbot

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID
import datetime
from jinja2 import Environment, FileSystemLoader
import json
import os
import os.path
import requests
import shutil
from typing import List

OPTIONS_SSL_NGINX = '/etc/letsencrypt/conf/options-ssl-nginx.conf'
SSL_DHPARAMS = '/etc/letsencrypt/conf/ssl-dhparams.pem'
PRIV_KEY = '/etc/letsencrypt/live/{0}/privkey{1}.key'
PUB_CERT = '/etc/letsencrypt/live/{0}/fullchain{1}.pem'
SOURCE_CONF = '/usr/src/app'
DEST_CONF = '/etc/nginx/conf.d/{0}.conf'

if __name__ == "__main__":
    mode: str = os.getenv('QNAP_NAS_SETUP_MODE', default='')
    domain_env: str = os.getenv('QNAP_NAS_DOMAINS', default='')
    domains: List[str] = domain_env.split(':')
    rsa_key_size_env: str = os.getenv('QNAP_NAS_KEY_SIZE', default='4096')
    rsa_key_size: int = int(rsa_key_size_env)
    updater_key: str = os.getenv('QNAP_NAS_DREAMHOST_KEY', default='')

    suffix: str = None
    if not mode in ['initialize', 'production']:
        raise ValueError('set QNAP_NAS_SETUP_MODE to either '
                         '"initialize" or "production"')
    elif mode == 'initialize':
        suffix = '.temp'
    elif mode == 'production':
        suffix = ''

    if mode == 'initialize':
        os.makedirs(os.path.dirname(OPTIONS_SSL_NGINX), exist_ok=True)

        print('### Downloading recommended TLS parameters ...')
        resp = requests.get('https://raw.githubusercontent.com/certbot/'
                            'certbot/master/certbot-nginx/certbot_nginx/'
                            '_internal/tls_configs/options-ssl-nginx.conf')
        with open(OPTIONS_SSL_NGINX, 'w') as f:
            f.write(resp.text)

        resp = requests.get('https://raw.githubusercontent.com/certbot/'
                            'certbot/master/certbot/certbot/ssl-dhparams.pem')
        with open(SSL_DHPARAMS, 'w') as f:
            f.write(resp.text)

        print('### Generating JSON configuration for updater DDNS ...')
        initialize_obj = { 'settings': [] }
        for domain in domains:
            initialize_obj['settings'].append({
                    'provider': 'dreamhost',
                    'domain': domain,
                    'key': updater_key,
                    'ip_version': 'ipv4',
                    'ipv6_suffix': ''
            })
        with open('/updater/config/config.json', 'w') as f:
            json.dump(initialize_obj, f)

    for domain in domains:

        if mode == 'initialize':
            print(f"### Creating dummy certificate for {domain} ...")
            os.makedirs(os.path.dirname(PRIV_KEY.format(domain, suffix)),
                        exist_ok=True)

            # https://cryptography.io/en/latest/x509/tutorial/#creating-a-self-signed-certificate

            key = rsa.generate_private_key(
                    public_exponent=65537,
                    key_size=rsa_key_size
            )

            with open(PRIV_KEY.format(domain, suffix), 'wb') as f:
                f.write(key.private_bytes(
                    encoding=serialization.Encoding.PEM,
                    format=serialization.PrivateFormat.TraditionalOpenSSL,
                    encryption_algorithm=serialization.NoEncryption()
                ))

            subject = issuer = x509.Name([
                    x509.NameAttribute(NameOID.COMMON_NAME, domain),
            ])
            cert = x509.CertificateBuilder().subject_name(
                    subject
            ).issuer_name(
                    subject
            ).public_key(
                    key.public_key()
            ).serial_number(
                    x509.random_serial_number()
            ).not_valid_before(
                    datetime.datetime.now(datetime.timezone.utc)
            ).not_valid_after(
                    datetime.datetime.now(datetime.timezone.utc) +
                    datetime.timedelta(days=10)
            ).add_extension(
                    x509.SubjectAlternativeName([x509.DNSName("localhost")]),
                    critical=False,
            ).sign(key, hashes.SHA256())

            with open(PUB_CERT.format(domain, suffix), "wb") as f:
                f.write(cert.public_bytes(serialization.Encoding.PEM))

        print(f"### Creating nginx configuration for {domain} ...")

        env = Environment(loader=FileSystemLoader(SOURCE_CONF))
        template = env.get_template('domain.conf.j2')
        with open(DEST_CONF.format(domain), 'w') as f:
            f.write(template.render(
                    domain=domain,
                    suffix=suffix,
                    pubkey_cert=PUB_CERT.format(domain, suffix),
                    privkey=PRIV_KEY.format(domain, suffix)
            ))
