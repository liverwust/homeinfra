#!/usr/bin/python3
# https://github.com/wmnnd/nginx-certbot

import datetime
from jinja2 import Environment, FileSystemLoader
import json
import os
import os.path
import requests
import shutil
import stat
from typing import List

OPTIONS_SSL_NGINX = '/etc/letsencrypt/conf/options-ssl-nginx.conf'
SSL_DHPARAMS = '/etc/letsencrypt/conf/ssl-dhparams.pem'
SOURCE_CONF = '/usr/src/app'
DEST_CONF = '/etc/nginx/conf.d/{0}.conf'

if __name__ == "__main__":
    domain_env: str = os.getenv('QNAP_NAS_DOMAINS', default='')
    domains: List[str] = domain_env.split(':')
    template_env: str = os.getenv('QNAP_NAS_TEMPLATE', default='initialize')
    rsa_key_size_env: str = os.getenv('QNAP_NAS_KEY_SIZE', default='4096')
    rsa_key_size: int = int(rsa_key_size_env)
    updater_key: str = os.getenv('QNAP_NAS_DREAMHOST_KEY', default='')

    os.makedirs(os.path.dirname(OPTIONS_SSL_NGINX), exist_ok=True)
    os.makedirs("/var/www/certbot", exist_ok=True)

    existing_options_nginx = os.lstat(OPTIONS_SSL_NGINX)
    existing_dhparams = os.lstat(SSL_DHPARAMS)
    if not (stat.S_ISREG(existing_options_nginx.st_mode) and
            stat.S_ISREG(existing_dhparams.st_mode)):
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
        print(f"### Creating nginx configuration for {domain} ...")

        env = Environment(loader=FileSystemLoader(SOURCE_CONF))
        template = env.get_template(f'{template_env}.conf.j2')
        with open(DEST_CONF.format(domain), 'w') as f:
            f.write(template.render(domain=domain))
