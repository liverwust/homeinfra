# homeinfra

Home infrastructure (Ansible) for Louis's stuff.

## Ansible Configuration Settings

Override [the following settings][settings] in order to utilize the
Ansible Collection and the associated roles, playbooks, etc.. Make sure
to substitute `/path/to/HOME` with the actual, specific value for
[your environment][ANSIBLE_HOME] (generally `$HOME/.ansible`).

```ini
[defaults]
collections_path = /path/to/HOME/.ansible/collections:./collections:/usr/share/ansible/collections"
```

[settings]: https://docs.ansible.com/ansible/latest/reference_appendices/config.html
[ANSIBLE_HOME]: https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-home

## Testing with Molecule

This project uses [Molecule][Molecule] to perform integration tests
against a "staging" virtual machine. This VM is intended to match
closely with the production one, and is run locally on my MacBook using
VMware Fusion.

To interact with VMware Fusion, this project uses the
[qsypoq.vmware_desktop][qsypoq] Ansible collection as explained in
[this blog post][qsypoq_article]. The Ansible plugins provided by this
project require some configuration, which is provided (thru Molecule) as
a series of environment variables in [_.env.yml_][env_yml]. Please
initialize the file in the top-level of the repository as follows:

```yaml
HOMEINFRA_TEST_VMNAME: "<name of the VM>"
HOMEINFRA_TEST_VM_SNAPSHOT_NAME: "<name of the Base OS snapshot>"
HOMEINFRA_TEST_API_USERNAME: "<some username set during vmrest -C>"
HOMEINFRA_TEST_API_PASSWORD: "<some password>"
HOMEINFRA_TEST_API_URL: "http://127.0.0.1"
HOMEINFRA_TEST_API_PORT: "<some port # output by vmrest>"
HOMEINFRA_TEST_SSH_USER: "<username in the guest OS>"
HOMEINFRA_TEST_SSH_IDENTITY_FILE: "<id_rsa on the host; authorized in the guest>"
```

These variables are best understood by reading through this page,
[Use the VMware Fusion REST API Service][vmrest]. This can be
initialized by running `vmrest -C`. While running Molecule tests, the
`vmrest` program should be running somewhere in the background, and the
URL (particularly the port number) which it displays should be
substituted into the `.env.yml` file.

When destroying and recreating the environment, Molecule will call out
to the `vmrun` binary to revert to a known-good snapshot. For some
reason, this isn't available via the Rest API. The strategy, then, is to
occasionally update the Base OS snapshot with new OS packages _and
nothing more_ --- let Ansible take care of everything else.

[Molecule]: https://ansible.readthedocs.io/projects/molecule/
[qsypoq]: https://github.com/qsypoq/Ansible-VMware-Workstation-Fusion-Pro-Modules/blob/master/galaxy.yml
[qsypoq_article]: https://magnier.io/developing-vmware-workstation-pro-ansible-module/
[env_yml]: https://steven-cd-molecule.readthedocs.io/en/latest/configuration.html
[vmrest]: https://docs.vmware.com/en/VMware-Fusion/13/com.vmware.fusion.using.doc/GUID-63847178-3425-4D92-A043-EFBC1251C606.html
