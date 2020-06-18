#! /bin/sh
set -e

# Get the current name and version from info.json
PACKAGE_NAME=$(jq -r .name info.json)
PACKAGE_VERSION=$(jq -r .version info.json)
PACKAGE_FULL_NAME=${PACKAGE_NAME}_${PACKAGE_VERSION}
PACKAGE_FILE=${PACKAGE_FULL_NAME}.zip

echo Preparing $PACKAGE_FILE

 # Find all files and folders that should be part of release (by excluding ones that should not)
FILES=$(find . -maxdepth 1 -iname '*' -not -name "tests" -not -name ".*" -not -name "*.zip" -not -name "*.sh" -not -name "TLBE*")
echo $FILES

mkdir -p ${PACKAGE_FULL_NAME}
cp -r ${FILES} "${PACKAGE_FULL_NAME}"
zip -r ${PACKAGE_FILE} "${PACKAGE_FULL_NAME}"
echo ${PACKAGE_FULL_NAME} ready

