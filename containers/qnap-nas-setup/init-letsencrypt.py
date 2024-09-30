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

    existing_options_nginx = False
    try:
        options_nginx_stat = os.lstat(OPTIONS_SSL_NGINX)
        existing_options_nginx = stat.S_ISREG(options_nginx_stat.st_mode)
    except FileNotFoundError:
        existing_options_nginx = False

    existing_dhparams = False
    try:
        dhparams_stat = os.lstat(SSL_DHPARAMS)
        existing_dhparams = stat.S_ISREG(dhparams_stat.st_mode)
    except FileNotFoundError:
        existing_dhparams = False

    if not (existing_options_nginx and existing_dhparams):
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

    # Keep track of the "primary domain," which is 1st in the various lists
    # and will represent the CN for the LetsEncrypt certificate. All other
    # names are SANs.
    primary_domain = domains[0]

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
            f.write(template.render(
                    domain=domain,
                    primary_domain=primary_domain
            ))
