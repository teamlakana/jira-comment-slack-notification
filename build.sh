#!/bin/bash

# Show commands
#set -x
# Exit on error/unset var
set -e

# Pull in build.env for Configuration
source ./build.vars

if [ -z ${NAMESPACE} || -z ${APP} || -z ${AWS_REGION} ]
then
  echo "Something is wrong, missing variables from build.vars"
  exit 1
fi

# Ensure login to ECR
$(aws ecr get-login --no-include-email --region "${AWS_REGION}")

# Find existing repositories
if aws ecr describe-repositories --region "${AWS_REGION}" | jq -r '.repositories[] | .repositoryName' | grep -q "${NAMESPACE}/${APP}"
then
  # Found matching, fetch URI
  echo "${NAMESPACE}/${APP} found in ECR"
  AWS_ECR_URI=$(aws ecr describe-repositories --repository-names "${NAMESPACE}/${APP}" --region "${AWS_REGION}" | jq -r '.repositories[] | .repositoryUri')
  echo "ECR URI set to: ${AWS_ECR_URI}"
else
  echo "${NAMESPACE}/${APP} not found in ECR"
  AWS_ECR_URI=$(aws ecr create-repository --repository-name "${NAMESPACE}/${APP}" --region "${AWS_REGION}" | jq -r '.repositories[] | .repositoryUri')
  echo "Created ${NAMESPACE}/${APP} in ECR, ECR URI set to: ${AWS_ECR_URI}"
fi

# Identification of this build
COMMIT=$(git log -1 --pretty=%H)

[ -f package.json ] && VERSION=$(cat package.json | jq -r '.version')
[ -f pom.xml ] && VERSION=$(mvn -Dexec.executable='echo' -Dexec.args='${project.version}' --non-recursive exec:exec -q)

if [ -z ${VERSION} ]
then
  echo "Something is wrong, could not find and set VERISON"
  exit 1
fi

# Perform the Build
docker build -t "${NAMESPACE}/${APP}" .

# Tag image for each additional tag to ECR
for tag in {latest,${COMMIT},${BUILD},${VERSION}}
do
  # If BAMBOO_BUILD is just '-' then we don't have the plan variables, continue
  if [[ "${tag}" == "-" ]] ; then continue ; fi
  docker tag "${NAMESPACE}/${APP}" "${AWS_ECR_URI}:${tag}"
  #docker push "${AWS_ECR_URI}:${tag}"
done

docker push "${AWS_ECR_URI}"
