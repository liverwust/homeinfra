us_wust.homeinfra.letsencrypt
=============================

Request (from Let's Encrypt), retrieve, locally cache, and then
distribute certificates to systems and services which need them.

By design, this role will _FAIL_ a play in the presence of an ongoing,
yet-to-be-fulfilled request. The [DNS-01 challenge
type](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge)
relies on global DNS propagation, which can take several hours. In this
case, the admin is expected to walk away for a while and then try again
--- possibly multiple times, until the action finally completes.

Requirements
------------

This role is designed for exclusive use with Let's Encrypt and with
DreamHost as a DNS provider. It is not intended to be any more
extensible than that.

These are captured in `requirements.txt` and are inherited from modules
like
[community.crypt.acme_certificate](https://docs.ansible.com/ansible/latest/collections/community/crypto/acme_certificate_module.html#ansible-collections-community-crypto-acme-certificate-module):

* either openssl or cryptography >= 1.5
* ipaddress

Role Variables
--------------

```yaml
homeinfra_letsencrypt_production_account_key:
  Description: |
    The private key associated with an account tied into the Let's
    Encrypt production environment. It's not really an _account_ per se,
    but this key just should stay the same between runs of Ansible. This
    can then be used to revoke a cert if needed.
  Required: true
  Type: str (BEGIN PRIVATE KEY // END PRIVATE KEY)

homeinfra_letsencrypt_staging_account_key:
  Description: |
    The private key associated with an account tied into the Let's
    Encrypt staging environment --
    https://letsencrypt.org/docs/staging-environment/
  Required: true
  Type: str (BEGIN PRIVATE KEY // END PRIVATE KEY)

homeinfra_letsencrypt_account_notification_email:
  Description: |
    The email address used to notify about expiring certificates
    associated with this account key.
  Required: true
  Type: str

homeinfra_letsencrypt_use_production_environment:
  Description: |
    Override to true if it is time for production. Otherwise, leave it
    as false and use the staging environment.
  Required: false
  Default: false
  Type: bool

homeinfra_letsencrypt_control_node_cache_dir:
  Description: |
    The existence of a cache directory is an important assumption. This
    location will hold *.crt files, which represent the issued
    certificates as delivered by Let's Encrypt. It will also hold
    *.crt-lock files, which represent serialized data returned from the
    ACME request and which exist during the period of time between the
    renewal request and the confirmation of DNS propagation.
  Required: false
  Default: playbook_dir ~ "/acme-certificates"
  Type: str

homeinfra_letsencrypt_dreamhost_api_key:
  Description: |
    API key for DreamHost, as explained on this page:
    https://help.dreamhost.com/hc/en-us/articles/4407354972692-Connecting-to-the-DreamHost-API
  Required: true
  Type: str

homeinfra_letsencrypt_certificates:
  Description: |
    List of certificates to be requested for this host. Each item is
    a dictionary with a key, certificate_tag, that should be unique
    within the context of this list. This will be used to generate a
    certificate at the following location:
        playbook_dir/acme-certificates/inventory_hostname-CERTIFICATE_TAG.crt
    The other elements are passed to one or the other of these modules:
        ansible-doc -t module community.crypto.openssl_csr
        ansible-doc -t module community.crypto.acme_certificate
  Required: false
  Default: empty, do not request any certificates
  Type:
    - list of dicts, each with some of the keys named below
    - certificate_tag (**REQUIRED**): An identifier for this certificate
      in the context of this inventory host, as described above.
    - common_name (openssl_csr, **REQUIRED**): The commonName field of
      the certificate.
    - privatekey_content (openssl_csr, **REQUIRED**): The content of the
      private key to use when signing the certificate signing request.
    - subject_alt_name (openssl_csr): Subject Alternative Name (SAN)
      extension to attach to the certificate signing request. Don't
      include the common_name again. See:
      https://docs.ansible.com/ansible/latest/collections/community/crypto/openssl_csr_module.html#parameter-subject_alt_name
    - extended_key_usage (openssl_csr): List of Additional restrictions
      (for example client authentication, server authentication) on the
      allowed purposes for which the public key may be used.
    - key_usage (openssl_csr): This defines the purpose (for example
      encipherment, signature, certificate signing) of the key contained
      in the certificate.
    - remaining_days (acme_certificate): The number of days the
      certificate must have left being valid. If cert_days <
      remaining_days, then it will be renewed. Defaults to 10.
    - force (acme_certificate): Enforces the execution of the challenge
      and validation, even if an existing certificate is still valid for
      more than remaining_days.
```

During execution of the role, the following data structure is generated
as a superset of the homeinfra_letsencrypt_certificates input:

```yaml
homeinfra_letsencrypt_certificates_results:
  Description: |
    List of certificates generated and cached for this host. Each
    element of the list is a dictionary, as described below.
  Type:
    - list of dicts, each with these keys named below
    - certificate_tag: The same identifier as passed-in via the input
      data structure.
    - privatekey_content: For convenience, a copy of the private key as
      passed-in thru the original datastructure.
    - privatekey_filename: This is NOT a path to a location on the
      control node. Instead, it is a suggested filename for the private
      key based on certificate_tag. Compare this with the value of
          issued_cert_dest | basename
    - issued_cert_dest: The path to the issued and cached certificate.
      Copy this from the control node to the remote host.
    - issued_chain_dest: The path to a file containing the intermediate
      certificate.
    - issued_fullchain_dest: The path to a file containing the full
      chain (that is, a certificate followed by chain of intermediate
      certificates).
    - input_dict: The same unmodified dictionary which was originally
      provided via homeinfra_letsencrypt_certificates.
```

Dependencies
------------
No additional dependencies beyond the standard `ansible` distribution.

Example Playbook
----------------

```yaml
- hosts: example.com
  vars:
    # other context for controlling DNS updates, etc.
    homeinfra_letsencrypt_certificates:
      - certificate_tag: webserver    # yields example.com-webserver.crt
        privatekey_content: ...
        common_name: example.com

  tasks:
    - name: Obtain a Lets Encrypt certificate
      ansible.builtin.import_role:
        name: us_wust.homeinfra.letsencrypt

    # At this point, the playbook may fail if the certificate was just
    # issued now or reissued. In these cases, it is very likely that DNS
    # propagation delays will ensue, and you'll need to run the playbook
    # again at a later time. Go eat lunch.

    - name: Copy private keys to host
      ansible.builtin.copy:
        content: "{{ item.privatekey_content }}"
        dest: "/etc/pki/tls/private/{{ item.privatekey_filename }}"
      loop: "{{ homeinfra_letsencrypt_certificates_results }}"

    - name: Copy retrieved signed certs to host
      ansible.builtin.copy:
        src: "{{ item.issued_cert_dest }}"
        dest: "/etc/pki/tls/certs/{{ item.issued_cert_dest | basename }}"
      loop: "{{ homeinfra_letsencrypt_certificates_results }}"
```

License
-------

GPL-3.0.-or-later

Author Information
------------------

Louis Wust <louiswust@fastmail.fm>
