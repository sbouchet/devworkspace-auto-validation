#! /bin/bash

# You must be logged into your OpenShift Cluster

VERBOSE=1
# Rough time (seconds) to wait for DevWorkspace to enter 'Running' state
TIMEOUT=60

# name to give all created (singleton) DevWorkspace instances
DEVWORKSPACE_NAME='sshd-test'
# user namespace where testing will occur
DEVWORKSPACE_NS=''

# url of the sample project to use
PROJECT_URL='"https://github.com/che-samples/web-nodejs-sample.git"'
# editor definition to be used when testing
EDITOR_DEFINITION='https://gist.githubusercontent.com/rgrunber/4f40f06f20c0e835bd8274942d6a89ac/raw/309aeece6d46a3784e0df892433fa6e1a05af62b/che-code-sshd-ubi8.yaml'

# URL of sample devfile to use
DEVFILE_URL='https://raw.githubusercontent.com/RomanNikitenko/web-nodejs-sample/refs/heads/main/devfile.yaml'
# Temporary storage for devfile
TMP_DEVFILE=/tmp/devfile-sshd.yaml

# Images to test (override) the given devfile
#IMAGES_TO_TEST=''
IMAGES_TO_TEST=$(cat images_to_test.txt | tr '\n' ' ')

# Function that evaluates whether DevWorkspace is valid
function validate_devworkspace () {
  # Get all pods
  podNameAndDWName=$(oc get pods -o 'jsonpath={range .items[*]}{.metadata.name}{","}{.metadata.labels.controller\.devfile\.io/devworkspace_name}{end}')
  # Find pod in ${DEVWORKSPACE_NS} matching ${DEVWORKSPACE_NAME}
  podName=$(echo ${podNameAndDWName} | grep ${DEVWORKSPACE_NAME} | cut -d, -f1)
  res=$(oc exec -n ${DEVWORKSPACE_NS} ${podName} -c tools -- cat /tmp/sshd.log)
  echo "${res}" | grep -q 'listening'
  if [ $? -eq 0 ]; then
    # pass
    return 0
  else
    # fail
    return 1
  fi
}

function log () {
if [ ${VERBOSE} -eq 1 ]; then
  echo ${@}
fi
}

curl -sL -o ${TMP_DEVFILE} ${DEVFILE_URL}
sed -i 's/^/    /' ${TMP_DEVFILE}

for image in ${IMAGES_TO_TEST}; do
  log "Begin testing ${image}"
  # Modify DevWorkspace template
  cat devworkspace-sshd.yaml | \
  sed \
  -e "/DEVFILE/r ${TMP_DEVFILE}" \
  -e '/DEVFILE/ d' \
  -e "s|DEVWORKSPACE_NAME|${DEVWORKSPACE_NAME}|" \
  -e "s|DEVWORKSPACE_NS|${DEVWORKSPACE_NS}|" \
  -e "s|EDITOR_DEFINITION|${EDITOR_DEFINITION}|" \
  -e "s|PROJECT_URL|${PROJECT_URL}|" | \
  # Modify the result (must be separate)
  sed "s|image: .*|image: ${image}|" \
  | oc apply -f -
  state=""
  log -n "Waiting for ${DEVWORKSPACE_NAME} .."
  count=0
  while [ "${state}" != "Running" ] && [ ${count} -lt ${TIMEOUT} ]; do
    state=$(oc get dw ${DEVWORKSPACE_NAME}  -o 'jsonpath={.status.phase}')
    sleep 1s
    log -n "."
    count=$[${count}+1]
  done
  if [ ${state} == "Running" ]; then
    log -e "\n${DEVWORKSPACE_NAME} is Running"
  else
    log -e "\n${DEVWORKSPACE_NAME} failed to start"
  fi
  log "Validating ${DEVWORKSPACE_NAME} .."
  validate_devworkspace
  if [ $? -eq 0 ]; then
    echo "TEST ${image} PASS"
  else
    echo "TEST ${image} FAIL"
  fi
  sleep 1s
  oc delete dw ${DEVWORKSPACE_NAME}
  sleep 1s
done
