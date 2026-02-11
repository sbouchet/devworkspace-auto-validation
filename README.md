# DevWorkspace Auto Validation Script

## Automatically test DevWorkspaces sequentially using an image override for the given devfile

## Requirements

* The command-lie tools : `oc`, `yq`
* You must be logged into the OpenShift cluster

### Usage

* Run the script by passing a configuration file as the first argument. This loads various constants specific to that type of test including possible functions.

```
$ ./dw-auto-validate.sh settings/che-code-sshd.env
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
