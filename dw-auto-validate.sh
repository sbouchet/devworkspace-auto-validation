#! /bin/bash

# You must be logged into your OpenShift Cluster

####################
# Common Functions #
####################

# Seems to be the first one listed under components
function getMainContainerFromDevfile () {
  devfile_url=$1
  curl -sl ${devfile_url} | yq '.components[0].name'
}

function getDevfileURLSFromRegistry () {
  devfile_registry=$1

  INDEX_PATH='/index/all'
  devfileNames=$(curl -sL "${devfile_registry}${INDEX_PATH}" | jq -r '.[].name' -)

  for name in ${devfileNames}; do
    echo "${devfile_registry}/devfiles/${name}"
  done
}

function log () {
  if [ ${VERBOSE} -eq 1 ]; then
    echo ${@}
  fi
}


########
# Main #
########

if [ -z "$1" ]; then
  echo "Please make sure to pass in one of the constant files under settings/ as an argument to this script."
  echo "$ ./dw-auto-validate.sh settings/che-code-sshd.env"
  exit 1
fi

SETTINGS=$1
. ${SETTINGS}

for devfile_url in ${DEVFILE_URL_LIST}; do
  curl -sL -o ${TMP_DEVFILE} ${devfile_url}
  sed -i 's/^/    /' ${TMP_DEVFILE}

for image in ${IMAGES_LIST}; do
  log "Begin testing ${devfile_url} with ${image}"
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
  validate_devworkspace ${devfile_url}
  if [ $? -eq 0 ]; then
    echo "TEST ${devfile_url} ${image} PASS"
  else
    echo "TEST ${devfile_url} ${image} FAIL"
  fi
  sleep 1s
  oc delete dw ${DEVWORKSPACE_NAME}
  sleep 1s
done # image loop

done # devfile loop
