#! /bin/bash
VERBOSE=0

# colors
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
PURPLE='\033[1;95m'
NC='\033[0m' # No Color

<<<<<<< Upstream, based on branch 'main' of git@github.com:rgrunber/devworkspace-auto-validation.git
####################
# Common Functions #
####################
=======
# [EXPERT MODE] by default runs the full validation mode, adding extra params to who knows...
while getopts "v" o; do
    case "${o}" in
        v)
            VERBOSE=1
            ;;
        *)
            usage
            ;;
    esac
done
>>>>>>> a3b0257 tweaking script:

<<<<<<< Upstream, based on branch 'main' of git@github.com:rgrunber/devworkspace-auto-validation.git
# Seems to be the first one listed under components
function getMainContainerFromDevfile () {
  devfile_url=$1
  curl -sl ${devfile_url} | yq '.components[0].name'
}
=======
######### FUNCTIONS 
>>>>>>> a3b0257 tweaking script:

<<<<<<< Upstream, based on branch 'main' of git@github.com:rgrunber/devworkspace-auto-validation.git
function getDevfileURLSFromRegistry () {
  devfile_registry=$1

  INDEX_PATH='/index/all'
  devfileNames=$(curl -sL "${devfile_registry}${INDEX_PATH}" | jq -r '.[].name' -)

  for name in ${devfileNames}; do
    echo "${devfile_registry}/devfiles/${name}"
  done
=======
# Function that evaluates whether DevWorkspace is valid
validate_devworkspace() {
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
>>>>>>> a3b0257 tweaking script:
}

<<<<<<< Upstream, based on branch 'main' of git@github.com:rgrunber/devworkspace-auto-validation.git
function log () {
  if [ ${VERBOSE} -eq 1 ]; then
    echo ${@}
  fi
=======
log() {
if [ ${VERBOSE} -eq 1 ]; then
  echo ${@}
fi
>>>>>>> a3b0257 tweaking script:
}

<<<<<<< Upstream, based on branch 'main' of git@github.com:rgrunber/devworkspace-auto-validation.git
=======
# oc must be installed
echo -e "\n${BLUE}Checking oc installation...${NC}"
log "Executing 'which oc'..."
if ! [ -x "$(command -v oc)" ]; then
  echo '${RED}Error:${NC} oc is not installed. Please install oc CLI. You can find a getting started guide here: https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/cli_tools/openshift-cli-oc' >&2
  exit 1
else
  echo -e "${GREEN}Ok!${NC}"
fi

# You must be logged into your OpenShift Cluster
echo -e "\n${BLUE}Checking cluster connection...${NC}"
log "Executing 'oc whoami'..."
current_cluster=$(oc config current-context)
if ! [ "$(oc whoami)" ]; then
  echo -e "${YELLOW}Not connected.${NC} Do you want to login to current cluster? Current cluster is ${PURPLE}${current_cluster}.${NC}"
  while true; do
    read -p "(y/n)? : " yn
    case $yn in
      [Yy]* ) oc login --web; break;;
      [Nn]* ) exit;;
      * ) echo "Please answer (Yy)es or (Nn)o.";;
    esac
  done
else
  echo -e "${GREEN}Ok!${NC}\nUsing current context ${PURPLE}${current_cluster}${NC}\n"
fi

# Choose scenario
echo -e "${BLUE}Choose the dedicated scenario to run the editor validation.${NC}\n1-sshd\n2-jetbrains\n3-vscode"
SCENARIO=""
while true; do
  read -p "(1/2/3)? : " scenario
  case $scenario in
    1 ) SCENARIO=sshd; break;;
    2 ) SCENARIO=jetbrains; break;;
    3 ) SCENARIO=vscode; break;;
    * ) echo "Please answer 1 or 2 or 3";;
  esac
done

# Read values from settings.env
. settings-${SCENARIO}.env

# user namespace where testing will occur
DEVWORKSPACE_NS=$(oc project -q)
echo -e "\n${BLUE}Running test scenario '${SCENARIO}' using ${DEVWORKSPACE_NAME} devworkspace in ${DEVWORKSPACE_NS} namespace...${NC}"

# Images to test (override) the given devfile
IMAGES_TO_TEST=$(cat images_to_test.txt | tr '\n' ' ')

# Temporary storage for generated devfile
TMP_DEVFILE=$(mktemp -t devfile-${SCENARIO}-XXX.yaml)

curl -sL -o ${TMP_DEVFILE} ${DEVFILE_URL}
sed -i 's/^/    /' ${TMP_DEVFILE}
>>>>>>> a3b0257 tweaking script:

<<<<<<< Upstream, based on branch 'main' of git@github.com:rgrunber/devworkspace-auto-validation.git
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
=======
######## MAIN 
failed_images=()
success_count=0
total_count=0
[[ ${VERBOSE} -eq 0 ]] && QUIET="> /dev/null 2>&1"

for image in ${IMAGES_TO_TEST}; do
  log -e "\n${BLUE}Begin testing ${image}${NC}"
  ((total_count++))
>>>>>>> a3b0257 tweaking script:
  # Modify DevWorkspace template
  cat devworkspace-${SCENARIO}.yaml | \
  sed \
  -e "/DEVFILE/r ${TMP_DEVFILE}" \
  -e '/DEVFILE/ d' \
  -e "s|DEVWORKSPACE_NAME|${DEVWORKSPACE_NAME}|" \
  -e "s|DEVWORKSPACE_NS|${DEVWORKSPACE_NS}|" \
  -e "s|EDITOR_DEFINITION|${EDITOR_DEFINITION}|" \
  -e "s|PROJECT_URL|${PROJECT_URL}|" | \
  # Modify the result (must be separate)
  eval "sed \"s|image: .*|image: ${image}|\" \
  | oc apply -f - ${QUIET}"
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
    log -e "\n${GREEN}${DEVWORKSPACE_NAME} is Running${NC}"
  else
    log -e "\n${YELLOW}${DEVWORKSPACE_NAME} failed to start${NC}"
  fi
  log "Validating ${DEVWORKSPACE_NAME} .."
  validate_devworkspace ${devfile_url}
  if [ $? -eq 0 ]; then
<<<<<<< Upstream, based on branch 'main' of git@github.com:rgrunber/devworkspace-auto-validation.git
    echo "TEST ${devfile_url} ${image} PASS"
=======
    ((success_count++))
    echo "TEST ${image} PASSED ✅"
>>>>>>> a3b0257 tweaking script:
  else
<<<<<<< Upstream, based on branch 'main' of git@github.com:rgrunber/devworkspace-auto-validation.git
    echo "TEST ${devfile_url} ${image} FAIL"
=======
    failed_images+=("$image")
    echo "TEST ${image} FAILED ❌"
>>>>>>> a3b0257 tweaking script:
  fi
  sleep 1s
<<<<<<< Upstream, based on branch 'main' of git@github.com:rgrunber/devworkspace-auto-validation.git
  oc delete dw ${DEVWORKSPACE_NAME}
  sleep 1s
done # image loop

done # devfile loop
=======
done

# cleanup
echo -e "\n${BLUE}Cleaning up resources...${NC}"
eval "oc delete dw ${DEVWORKSPACE_NAME} ${QUIET}"
sleep 1s

rm $TMP_DEVFILE

echo    ""
echo    "========================================="
echo    "Summary:"
echo -e "  Total images: ${BLUE}$total_count${NC} "
echo -e "  Successful: ${GREEN}$success_count${NC}"
echo -e "  Failed: ${RED}${#failed_images[@]}${NC}"
echo    "========================================="

if [ ${#failed_images[@]} -gt 0 ]; then
  echo ""
  echo "Failed images:"
  for img in "${failed_images[@]}"; do
    echo "  - $img"
  done
  exit 1
fi

>>>>>>> a3b0257 tweaking script:
