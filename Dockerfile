# checkov:skip=CKV_DOCKER_3: "Ensure that a user for the container has been created"
# GitHub actions require that the docker image use the root user
# https://docs.github.com/en/actions/creating-actions/dockerfile-support-for-github-actions#user

# 20.04 is the last ubuntu version to use automake-1.15 which is required to build the gnu-tools
FROM ubuntu:20.04



#################################
### Install Required Packages ###
#################################
RUN ln -fs /usr/share/zoneinfo/Europe/London /etc/localtime && \
    sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get --yes upgrade && \
    apt-get install --yes --no-install-recommends automake-1.15 \
                                                  git && \
    rm -rf /var/lib/apt/lists/*



#########################
### Create Build Area ###
#########################
RUN mkdir /root/build

# clone sourcecode
WORKDIR /root/build
RUN git clone https://github.com/grahame-student/gnu-tools-for-stm32.git



###########################
### Build Prerequisites ###
###########################
WORKDIR /root/build/gnu-tools-for-stm32
RUN ./build-prerequisites.sh
