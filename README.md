# Ubuntu 64 bit Multiarch docker containers 🐳
This is replicable a 2 stage bootstrap ubuntu images built from debootstrap
Access to the multi-platform docker [image](https://hub.docker.com/r/juampe/ubuntu).
Access to the Git [repository](https://github.com/juampe/ubuntu)

# 2 stage debootstrap build process
First built from base distribution, second build from itself as a ubuntu container with ubuntu debootstrap
Assure container support compatibility with the architecture adding updates and security updates

# Multi-platform image 👪
Supported platforms:
* linux/amd64
* linux/arm64
* linux/riscv64
* 
🙏If you apprecciate the effort, please consider to support us making an ADA donation.
>addr1qys8y92emhj6r5rs7puw6df9ahcvna6gtdm7jlseg8ek7xf46xjc0eelmgtjvmcl9tjgaamz93f4e5nu86dus6grqyrqd28l0r
# Minimize supply chain attack. 🔗
You can supervise all the sources, all the build steps, build yourserlf.

# Build your own container. 🏗️
From a ubuntu:hirsute with enught space prepare for docker buildx multiarch environment
```
apt-get update
apt-get -y install git curl ca-certificates curl gnupg qemu binfmt-support qemu-user-static docker.io byobu make
export DOCKER_CLI_EXPERIMENTAL=enabled
docker run --rm --privileged docker/binfmt:820fdd95a9972a5308930a2bdfb8573dd4447ad3
docker buildx create --name builder
docker buildx use builder
docker buildx inspect --bootstrap
docker buildx ls

docker run --rm --privileged multiarch/qemu-user-static --reset -p yes 
docker run --rm -t juampe/ubuntu:hirsute-riscv64 uname -m # Testing the emulation environment

```
Clone the repository
```
git clone https://github.com/juampe/ubuntu.git
cd ubuntu
```
Edit build.sh header variables to fit yout needs
```
./build.sh # to build
./builds.sh publish # to register and manifest publish
```

Enjoy!
