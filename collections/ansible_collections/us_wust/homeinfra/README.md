# Ansible Collection - us_wust.homeinfra

Configure my home network and related resources. This collection isn't intended
for wider distribution, though I hope to develop my understanding of Ansible
modularity by applying this structure.

## Roles

* [us_wust.homeinfra.dreamcompute](roles/dreamcompute/README.md): Configure
  resources in the DreamCompute OpenStack for virtual machines, volumes,
  networks, and related virtualization objects.

* [us_wust.homeinfra.k8s_nodes](roles/k8s_nodes/README.md): Configure
  Kubernetes control nodes and worker nodes, which includes Debian OS patching
  steps.

* [us_wust.homeinfra.nas](roles/nas/README.md): Configure the QNAP
  network-attached storage device and its ZFS storage.
