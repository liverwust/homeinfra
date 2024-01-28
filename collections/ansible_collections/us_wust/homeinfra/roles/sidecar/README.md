us_wust.homeinfra.sidecar
=========================

The "Sidecar VM" is the single virtual machine which runs on my QNAP.
This system requires some basic operating system configuration, such as
network, package, and security settings.

Requirements
------------

To enable Ansible to connect to the sidecar VM in the first place, it
likely needs to have run through the _wicked.yml_, _netconfig.yml_, and
_ssh.yml_ tasks once already. This may need to have been done manually.

After those plays have been bootstrapped, it is reasonable to expect
that all the remaining tasks will succeed.

Role Variables
--------------

TODO

Dependencies
------------

TODO

Example Playbook
----------------

TODO

License
-------

GPL-3.0-or-later

Author Information
------------------

Louis Wust <louiswust@fastmail.fm>
