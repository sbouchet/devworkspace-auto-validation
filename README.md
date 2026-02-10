# DevWorkspace Auto Validation Script

## Automatically test DevWorkspaces sequentially using an image override for the given devfile

## Requirements

* You must have `oc` installed and be logged into the cluster

### Usage

```
$ ./dw-auto-validate.sh
Begin testing registry.access.redhat.com/ubi8:latest
devworkspace.workspace.devfile.io/sshd-test created
Waiting for sshd-test .................
sshd-test is Running
Validating sshd-test ..
TEST registry.access.redhat.com/ubi8:latest PASS
devworkspace.workspace.devfile.io "sshd-test" deleted
Begin testing registry.access.redhat.com/ubi8-minimal:latest
devworkspace.workspace.devfile.io/sshd-test created
Waiting for sshd-test .....................
sshd-test is Running
Validating sshd-test ..
TEST registry.access.redhat.com/ubi8-minimal:latest PASS
...
...
```

See `settings.env` for all configurable settings.
