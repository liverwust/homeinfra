us_wust.homeinfra.sidecar_bareos
================================

The "Sidecar VM" is the single virtual machine which runs on my QNAP.
The [bareos](https://www.bareos.com/) Director, Storage Daemon, Console,
and one of the File Daemons (Clients) run on the sidecar VM. This role
is distinct from the main sidecar role, in part because it cannot be
tested on my Apple Silicon M1 Pro (i.e., no bareos packages for aarm64).

Requirements
------------

TODO

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
