#!/bin/bash

RPM_ARTIFACT_DIR=cxx_rpm
IMAGE_TAG=cxx_rpm
DOCKERFILE=Dockerfile_rpm

RPM_DISTRIBUTION_TYPE="rhel8"

INFLUXDB_CXX_PACKAGE_VERSION="0.0.1"
INFLUXDB_CXX_RELEASE_VERSION=0.0.1

OWNER_GITHUB=pgspider
INFLUXDB_CXX_PROJECT_GITHUB=influxdb-cxx


set -eE

# User need to specified proxy and no_proxy as environment variable before executing
#   Example:
#       export proxy=http://username:password@proxy:port
#       export no_proxy=127.0.0.1,localhost
if [[ -z "${proxy}" ]]; then
  echo "proxy environment variable not set"
  exit 1
fi

if [[ -z "${no_proxy}" ]]; then
  echo "no_proxy environment variable not set"
  exit 1
fi

# Choose location of PGSpider RPM binaries
read -p "Location of PGSpider RPM binaries: " location
if [[ $location != [gG][iI][tT][hH][uU][bB] && $location != [gG][iI][tT][lL][aA][bB] ]]; then
    echo "Please choose: [GITHUB], [GITLAB]"
    exit 1
fi

# Input necessary information
#   For Github API require RELEASE_ID. Example:
#        Public projects: https://github.com/public-username/public-repo.git
#           "public-username" is OWNER
#           "public-repo" is REPO
#           Release ID is system value. You can get it by command: curl https://api.github.com/repos/OWNER/REPO/releases/latest
#   For Gitlab require project id. Example:
#           "728" is project id of influxdb-cxx
read -p "Access Token: " ACCESS_TOKEN
if [[ $location == [gG][iI][tT][hH][uU][bB] ]]; then
    read -p "InfluxDB-CXX Release ID: " INFLUXDB_CXX_RELEASE_ID
else
    read -p "InfluxDB CXX PROJECT ID: " INFLUXDB_CXX_PROJECT_ID
fi

# create rpm on container environment
if [[ $location == [gG][iI][tT][lL][aA][bB] ]];
then 
    docker build -t $IMAGE_TAG \
                 --build-arg proxy=${proxy} \
                 --build-arg no_proxy=${no_proxy} \
                 --build-arg ACCESS_TOKEN=${ACCESS_TOKEN} \
                 --build-arg RPM_DISTRIBUTION_TYPE=${RPM_DISTRIBUTION_TYPE} \
                 --build-arg INFLUXDB_CXX_RELEASE_VERSION=${INFLUXDB_CXX_RELEASE_VERSION} \
                 -f $DOCKERFILE .
else
    docker build -t $IMAGE_TAG \
                 --build-arg proxy=${proxy} \
                 --build-arg no_proxy=${no_proxy} \
                 --build-arg RPM_DISTRIBUTION_TYPE=${RPM_DISTRIBUTION_TYPE} \
                 --build-arg INFLUXDB_CXX_RELEASE_VERSION=${INFLUXDB_CXX_RELEASE_VERSION} \
                 -f $DOCKERFILE .
fi

# copy binary to outside
mkdir -p $RPM_ARTIFACT_DIR
docker run --rm -v $(pwd)/$RPM_ARTIFACT_DIR:/tmp \
                -u "$(id -u $USER):$(id -g $USER)" \
                -e LOCAL_UID=$(id -u $USER) \
                -e LOCAL_GID=$(id -g $USER) \
                $IMAGE_TAG /bin/sh -c "cp /home/user1/rpmbuild/RPMS/x86_64/*.rpm /tmp/"
rm -f $RPM_ARTIFACT_DIR/*-debuginfo-*.rpm

# Push binary on repo
if [[ $location == [gG][iI][tT][lL][aA][bB] ]];
then
    curl_command="curl --header \"PRIVATE-TOKEN: ${ACCESS_TOKEN}\" --insecure --upload-file"
    influxdb_cxx_package_uri="https://tccloud2.toshiba.co.jp/swc/gitlab/api/v4/projects/${INFLUXDB_CXX_PROJECT_ID}/packages/generic/rpm_${RPM_DISTRIBUTION_TYPE}/${INFLUXDB_CXX_PACKAGE_VERSION}"

    # influxdb-cxx
    eval "$curl_command ${RPM_ARTIFACT_DIR}/influxdb-cxx-${INFLUXDB_CXX_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $influxdb_cxx_package_uri/influxdb-cxx-${INFLUXDB_CXX_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
else
    curl_command="curl -L \
                            -X POST \
                            -H \"Accept: application/vnd.github+json\" \
                            -H \"Authorization: Bearer ${ACCESS_TOKEN}\" \
                            -H \"X-GitHub-Api-Version: 2022-11-28\" \
                            -H \"Content-Type: application/octet-stream\" \
                            --insecure"
    influxdb_cxx_assets_uri="https://uploads.github.com/repos/${OWNER_GITHUB}/${INFLUXDB_CXX_PROJECT_GITHUB}/releases/${INFLUXDB_CXX_RELEASE_ID}/assets"
    binary_dir="--data-binary \"@${RPM_ARTIFACT_DIR}\""

    # influxdb-cxx
    eval "$curl_command $influxdb_cxx_assets_uri?name=influxdb-cxx-${INFLUXDB_CXX_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $binary_dir/influxdb-cxx-${INFLUXDB_CXX_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
fi

# Clean
# docker rmi $IMAGE_TAG
