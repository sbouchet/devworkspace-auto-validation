# DevWorkspace Auto Validation Script

## Automatically test DevWorkspaces sequentially using an image override for the given devfile

## Requirements

* The command-line tools : `oc`, `yq`, `jq`
* You must be logged into the OpenShift cluster

### Usage

* Simply run the script. This loads various constants specific to that type of test including possible functions.


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

See the files under `settings/` for all configurable settings.
