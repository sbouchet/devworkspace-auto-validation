# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a bash-based automated validation tool for testing DevWorkspace instances on OpenShift clusters. It validates that different container images work correctly with various devfiles across different editor scenarios (sshd, JetBrains, VSCode).

## Commands

### Running Tests

```bash
# Run basic validation (uses images/images.txt)
./dw-auto-validate.sh

# Run with verbose output
./dw-auto-validate.sh -v

# Run full test matrix (uses images/images-full.txt - can take a long time)
./dw-auto-validate.sh -f

# Debug mode (verbose + only first image + no cleanup)
./dw-auto-validate.sh -d
```

### Verify Images

```bash
# Verify all images in images-full.txt are accessible
./verify_images.sh
```

## Architecture

### Main Script Flow (dw-auto-validate.sh)

1. **Prerequisites Check**: Validates `oc` and `jq` are installed and user is logged into OpenShift
2. **Scenario Selection**: Prompts user to choose scenario (sshd, jetbrains, or vscode)
3. **Settings Loading**: Sources the appropriate `settings/settings-<SCENARIO>.env` file
4. **Test Matrix**: Iterates through devfiles × images, creating DevWorkspace instances and validating them
5. **Cleanup**: Removes created resources (unless in debug mode)

### Scenarios

Each scenario is defined by a settings file in `settings/` that must export:

- `TIMEOUT`: Maximum seconds to wait for DevWorkspace to enter 'Running' state
- `DEVWORKSPACE_NAME`: Name for the DevWorkspace instance
- `PROJECT_URL`: Git repository URL for the sample project
- `EDITOR_DEFINITION`: URL to the editor definition YAML
- `DEVFILE_URL_LIST`: Space-separated list of devfile URLs to test
- `validate_devworkspace()`: Bash function that validates the running DevWorkspace (returns 0 for pass, 1 for fail)

#### Scenario-Specific Validation

- **sshd**: Checks for SSHD server listening by examining `/tmp/sshd.log` for "Server listening on"
- **jetbrains**: Port-forwards to port 3400 and validates HTTP 200 response from landing page
- **vscode**: Currently not supported

### DevWorkspace Generation

The script uses `devworkspace-template.yaml` as a base template and performs sed substitutions:

1. Injects devfile content at the `DEVFILE` placeholder
2. Replaces `DEVWORKSPACE_NAME`, `DEVWORKSPACE_NS`, `EDITOR_DEFINITION`, `PROJECT_URL`
3. Overrides container image with the test image
4. Applies the generated YAML to the cluster

### Key Bash Functions

- `log()`: Outputs messages only in verbose mode
- `debug()`: Outputs messages only in debug mode
- `getDevfileURLSFromRegistry()`: Queries devfile registry index to retrieve devfile URLs (currently unused but available)

## File Structure

```
settings/
  settings-sshd.env       # SSHD scenario configuration + validation function
  settings-jetbrains.env  # JetBrains scenario configuration + validation function
  settings-vscode.env     # VSCode scenario configuration (not supported)

images/
  images.txt              # Minimal image list for quick testing
  images-full.txt         # Full image list for comprehensive testing

samples/
  samples.txt             # Sample devfile URLs (currently unused)
  samples-full.txt        # Full sample list (currently unused)

devworkspace-template.yaml  # Base template for DevWorkspace generation
dw-auto-validate.sh        # Main validation script
verify_images.sh           # Image accessibility verification script
```

## Important Implementation Notes

### When Modifying Scenarios

1. All settings environment variables must be exported (`export VAR=value`)
2. The `validate_devworkspace()` function receives `devfile_url` as `$1`
3. Validation functions have access to `log()` and `debug()` helper functions
4. Return 0 for pass, 1 for fail from validation functions
5. Use `${DEVWORKSPACE_NS}` and `${DEVWORKSPACE_NAME}` variables set by main script

### When Modifying the Main Script

- The script uses `eval` for sed commands and oc commands to allow `${QUIET}` variable expansion
- `${QUIET}` is set to `&>/dev/null` in non-verbose mode, empty otherwise
- Template substitution happens in two stages: first for devfile injection and metadata, then for image override
- Debug mode (`-d`) runs only the first test iteration and skips cleanup for troubleshooting

### Variable Quoting

- `PROJECT_URL` in settings files must include its own double quotes (e.g., `'"https://..."'`)
- This is because the value gets inserted into YAML where it needs to be a quoted string

## Dependencies

- `oc` (OpenShift CLI)
- `jq` (JSON processor)
- `curl` (for fetching devfiles)
- `skopeo` (for verify_images.sh only)
- Active OpenShift cluster login
