#! /bin/bash
VERBOSE=0
FULL=0
DEBUG=0

# colors for fun
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
PURPLE='\033[1;95m'
NC='\033[0m' # No Color


#################################
# Parameters for fun or experts #
#################################

while getopts "vfdh" o; do
  case "${o}" in
    v) 
    VERBOSE=1
    echo "Using verbose mode."
    ;;
    f)
    FULL=1
    echo -e "Using full test matrix. ${YELLOW}WARNING${NC} - Can take a long time to complete."
    ;;
    d)
    DEBUG=1
    FULL=0
    VERBOSE=1
    echo -e "Using verbose mode AND do not clean resource. ${YELLOW}WARNING${NC} - This mode uses only the first item of the test matrix."
    ;;
    h)
    echo "Help: This script accepts -v for verbose mode, -d for debug mode and -f for full images test and -h for help."
    ;;
    \?)
    echo "Invalid option: -$OPTARG"
    ;;
  esac
done

# quiet logs from oc
[[ ${VERBOSE} -eq 0 ]] && QUIET="&>/dev/null"

####################
# Common Functions #
####################

getDevfileURLSFromRegistry() {
  devfile_registry=$1

  INDEX_PATH='/index/all'
  devfileNames=$(curl -sL "${devfile_registry}${INDEX_PATH}" | jq -r '.[].name' -)

  for name in ${devfileNames}; do
    echo "${devfile_registry}/devfiles/${name}"
  done
}

log() {
  if [ ${VERBOSE} -eq 1 ]; then
    echo ${@}
  fi
}

debug() {
  if [ ${DEBUG} -eq 1 ]; then
    echo ${@}
  fi
}

########
# Main #
########

# oc must be installed
echo -e "\n${BLUE}Checking oc installation...${NC}"
log "Executing 'which oc'..."
if ! [ -x "$(command -v oc)" ]; then
  echo -e "${RED}Error:${NC} oc is not installed. Please install oc CLI. You can find a getting started guide here: https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/cli_tools/openshift-cli-oc" >&2
  exit 1
else
  echo -e "${GREEN}Ok!${NC}"
fi

# jq must be installed
echo -e "\n${BLUE}Checking jq installation...${NC}"
log "Executing 'which jq'..."
if ! [ -x "$(command -v jq)" ]; then
  echo -e "${RED}Error:${NC} jq is not installed. Please install jq package." >&2
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
echo -e "${BLUE}Choose the dedicated scenario to run the validation test suite.${NC}\n1-sshd\n2-jetbrains\n3-vscode"
SCENARIO=""
while true; do
  read -p "(1/2/3)? : " scenario
  case $scenario in
    1 ) SCENARIO=sshd; break;;
    2 ) SCENARIO=jetbrains; break;;
    #3 ) SCENARIO=vscode; break;;
    3 ) SCENARIO=vscode; echo "not supported right now"; exit 0;;
    * ) echo "Please answer 1 or 2 or 3";;
  esac
done

# Read values from scenario's setting
. settings/settings-${SCENARIO}.env

# user namespace where testing will occur
DEVWORKSPACE_NS=$(oc project -q)
echo -e "\n${BLUE}Running test scenario '${SCENARIO}' using ${DEVWORKSPACE_NAME} devworkspace in ${DEVWORKSPACE_NS} namespace...${NC}"

# Temporary storage for generated devfile
TMP_DEVFILE=$(mktemp -t devfile-${SCENARIO}-XXX.yaml)
TMP_DEVWORKSPACE=$(mktemp -t devworkspace-XXX.yaml)

# parsing images list
IMAGES_LIST=()
IMAGE_LIST_PATH=
if [ ${FULL} -eq 0 ]; then
  IMAGE_LIST_PATH="images/images.txt"
else
  IMAGE_LIST_PATH="images/images-full.txt"
fi

while IFS= read -r image; do
  # Skip empty lines
  [[ -z "$image" ]] && continue

  IMAGES_LIST+=("$image")

done < ${IMAGE_LIST_PATH}

failed_test=()
success_count=0
total_count=0

# Start timing
START_TIME=$SECONDS

log "Iterating over ${#DEVFILE_URL_LIST[@]} Devfiles and ${#IMAGES_LIST[@]} Images"

for devfile_url in ${DEVFILE_URL_LIST}; do
  curl -sL -o ${TMP_DEVFILE} ${devfile_url}
  sed -i 's/^/    /' ${TMP_DEVFILE}

  for image in "${IMAGES_LIST[@]}"; do
    [[ ${DEBUG} -eq 1 && ${total_count} == 1 ]] && continue
    log -e "\n${BLUE}Begin testing ${devfile_url} with ${image}${NC}"
    ((total_count++))
    # Modify DevWorkspace template
    cat devworkspace-template.yaml | \
    sed \
    -e "/DEVFILE/r ${TMP_DEVFILE}" \
    -e '/DEVFILE/ d' \
    -e "s|DEVWORKSPACE_NAME|${DEVWORKSPACE_NAME}|" \
    -e "s|DEVWORKSPACE_NS|${DEVWORKSPACE_NS}|" \
    -e "s|EDITOR_DEFINITION|${EDITOR_DEFINITION}|" \
    -e "s|PROJECT_URL|${PROJECT_URL}|" | \
    # Modify the result (must be separate)
    eval "sed \"s|image: .*|image: ${image}|\" > ${TMP_DEVWORKSPACE}"
    eval "oc apply -f ${TMP_DEVWORKSPACE} ${QUIET}"
    state=""
    log -n "Waiting for ${DEVWORKSPACE_NAME} .."
    count=0
    while [ "${state}" != "Running" ] && [ ${count} -lt ${TIMEOUT} ]; do
      state=$(oc get dw ${DEVWORKSPACE_NAME} -o 'jsonpath={.status.phase}')
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
      echo "TEST ${devfile_url} ${image} PASSED ✅"
      ((success_count++))
    else
      echo "TEST ${devfile_url} ${image} FAILED ❌"
      failed_test+=("Devfile '$devfile_url' using image '$image'")
    fi
    sleep 1s
  done # image loop

done # devfile loop

# cleanup
cleanup() {
  echo -e "\n${BLUE}Cleaning up resources...${NC}"
  eval "oc delete dw ${DEVWORKSPACE_NAME} ${QUIET}"
  sleep 1s

  rm $TMP_DEVFILE
  rm $TMP_DEVWORKSPACE
}

[[ ${DEBUG} -eq 0 ]] && cleanup

# Calculate elapsed time
ELAPSED_TIME=$((SECONDS - START_TIME))
ELAPSED_MIN=$((ELAPSED_TIME / 60))
ELAPSED_SEC=$((ELAPSED_TIME % 60))

echo    ""
echo    "======================"
echo    "Summary:"
echo -e "  Total tests: ${BLUE}$total_count${NC} "
echo -e "  Successful: ${GREEN}$success_count${NC}"
echo -e "  Failed: ${RED}${#failed_test[@]}${NC}"
echo -e "  Time elapsed: ${PURPLE}${ELAPSED_MIN}m ${ELAPSED_SEC}s${NC}"
echo    "======================"

if [ ${#failed_test[@]} -gt 0 ]; then
  echo ""
  echo "Failed images:"
  for img in "${failed_test[@]}"; do
    echo "  - $img"
  done
  exit 1
fi

