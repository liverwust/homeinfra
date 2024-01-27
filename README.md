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
