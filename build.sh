#!/bin/bash
#set -x
#***** YOU CAN EDIT THIS HEADDER VARIABLES
#Tag for docker regitry
TAG="juampe/ubuntu"
#Platforms to build space separated
PLATFORMS="arm64 amd64 riscv64"
#PLATFORMS="arm64"
#Ubuntu releases to build
#RELEASES="focal groovy hirsute"
RELEASES="hirsute"
#Enough free space to deboostrap and save containers in tar format
WORKPLACE="/data"
#Keep this as LTS version that can boostrap newer versions
BASEREL="focal"


#********************************
#STAGE0 (bootstrap) docker image to build STAGE1 docker image
#STAGE2 image is based on STAGE1
declare -A BOOTSTRAP
BOOTSTRAP["amd64"]="ubuntu:focal"
BOOTSTRAP["arm64"]="ubuntu:focal"
BOOTSTRAP["riscv64"]="tonistiigi/debian:riscv"

declare -A REPOSITORY
REPOSITORY["amd64"]="http://archive.ubuntu.com/ubuntu"
REPOSITORY["arm64"]="http://ports.ubuntu.com/ubuntu-ports"
REPOSITORY["riscv64"]="http://ports.ubuntu.com/ubuntu-ports"


declare -A DOCKER_ARCH
DOCKER_ARCH["amd64"]="amd64"
DOCKER_ARCH["arm64"]="arm64"
DOCKER_ARCH["riscv64"]="riscv64"

cd $WORKPLACE

if [ "$1" != "publish" ]
then
	for RELEASE in $RELEASES
	do
		for PLATFORM in $PLATFORMS
		do
			echo "********* $PLATFORM **** $RELEASE"
			#If already bootstraped use it as a base debootstrap to make stage2
			STAGE1=$(docker images -q $TAG:$BASEREL-$PLATFORM 2> /dev/null)
			if [ -z "$STAGE1" ] 
			then
				echo ">> Using STAGE0 bootstrap image to create STAGE1"
				IMG=${BOOTSTRAP["$PLATFORM"]}
			else 
				echo ">> Using STAGE1 image to create STAGE2"
				IMG=$TAG:$BASEREL-$PLATFORM
			fi

			REPO=${REPOSITORY["$PLATFORM"]}
			echo ">> debootstrap --verbose --include=iputils-ping $RELEASE /data/$RELEASE-$PLATFORM $REPO"
			#debootstrap --verbose --include=iputils-ping --arch arm64 focal /data/focal-arm64 http://ports.ubuntu.com/ubuntu-ports
			echo "export REPO=$REPO RELEASE=$RELEASE PLATFORM=$PLATFORM"
			docker run  -i --rm -v $WORKPLACE:/data $IMG /bin/bash  << EOF
export DEBIAN_FRONTEND="noninteractive" 
apt-get -y update
apt-get -y install debootstrap
debootstrap --verbose --include=iputils-ping --arch $PLATFORM $RELEASE /data/$RELEASE-$PLATFORM $REPO
/bin/echo -ne "deb $REPO $RELEASE main restricted universe multiverse\ndeb $REPO $RELEASE-security main restricted universe multiverse\ndeb $REPO $RELEASE-updates main restricted universe multiverse\n" > /data/$RELEASE-$PLATFORM/etc/apt/sources.list
chroot /data/$RELEASE-$PLATFORM/ /bin/bash << SEOF 
export DEBIAN_FRONTEND="noninteractive"
apt-get -y update
apt-get -y upgrade
apt-get -y clean
SEOF
rm -R /data/$RELEASE-$PLATFORM/debootstrap
EOF
			cd $WORKPLACE/$RELEASE-$PLATFORM
			tar cpf - . | docker import - $TAG:$RELEASE-$PLATFORM --platform $PLATFORM
			cd $WORKPLACE
			docker save $TAG:$RELEASE-$PLATFORM  > ubuntu-$RELEASE-$PLATFORM.tar
		done
	done
fi

if [ "$1" == "publish" ]
then
	for RELEASE in $RELEASES
	do

		
		for PLATFORM in $PLATFORMS
		do
			echo ">> Pushing $TAG:$RELEASE-$PLATFORM"
			docker push $TAG:$RELEASE-$PLATFORM
		done

		AMEND=""
		for PLATFORM in $PLATFORMS
		do
			AMEND="$AMEND --amend $TAG:$RELEASE-$PLATFORM"
		done
		#docker manifest rm $TAG:$RELEASE
		echo ">> Publish $RELEASE"
		docker manifest create $TAG:$RELEASE $AMEND
		docker manifest push $TAG:$RELEASE

		for PLATFORM in $PLATFORMS
		do
			ARCH=${DOCKER_ARCH["$PLATFORM"]}
			echo ">> Publish $RELEASE $ARCH"
			docker manifest annotate --os linux --arch $ARCH $TAG:$RELEASE $TAG:$RELEASE-$PLATFORM
			docker manifest push $TAG:$RELEASE-$PLATFORM
		done
		docker manifest push $TAG:$RELEASE
	done
fi
