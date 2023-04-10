FROM ubuntu:22.04	
MAINTAINER Don Harbin (don.harbin@linaro.org)

ENV DEBIAN_FRONTEND noninteractive

ENV TZ=Europe/Stockholm

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

################################################################################
# Configuration parameters to set up prior to build
################################################################################
# Container directories for the Yocto Cache and TRS reference share
ARG YOCTO_CACHE=yocto_cache
ARG REF_REPO=trs-reference-repo
ARG DEVELOPMENT_DIR=trs-workspace

ARG USERNAME=dev


# Notes:  Per Readme, these values are overridden by the docker build command if
# want to use the same UiD/GID as the host. To use the hard coded UID and GID
# below, udate the 2 fields below to deire values and follow the alternative
# docker build shown in the Readme.
ARG USER_UID=1000
ARG USER_GID=1000

# ^^^ Can either exchange 1000 to desired user id and group id
# Or pass the UIDs in docker build command options (preferred, see readme)


################################################################################
# APT packages
################################################################################
RUN apt update

RUN apt -y --allow-downgrades --allow-remove-essential --allow-change-held-packages install apt-utils

# Minimum ammount of packages needed to be able to kick of a TRS build. I.e.,
# even though TRS has it's own apt-prereqs target, we have to preinstall a few.
# I.e, for example, we cannot call make before installing make.
RUN apt -y --allow-downgrades --allow-remove-essential --allow-change-held-packages install \
	    curl \
	    cpio \
	    git \
	    make \
	    python-is-python3 \
	    tzdata \
	    vim \
	    wget


################################################################################
# Repo
################################################################################
RUN curl https://storage.googleapis.com/git-repo-downloads/repo > /bin/repo
RUN chmod a+x /bin/repo

################################################################################
# User and group configuration
################################################################################
RUN groupadd -g $USER_GID -o $USERNAME
RUN useradd --shell /bin/bash -u $USER_UID -g $USER_GID -o -c "" -m $USERNAME
RUN echo "${USERNAME}:${USERNAME}" | chpasswd

################################################################################
# Locale configuration
################################################################################
RUN apt-get -y --allow-downgrades --allow-remove-essential --allow-change-held-packages install locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN apt-get -y install iputils-ping

################################################################################
# Set up DinD
################################################################################
# Install Docker CLI and dependencies
RUN apt-get update && apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common

# Add Docker's official GPG key
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

# Add Docker's stable repository
RUN add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

# Install Docker CLI
RUN apt-get update && apt-get install -y docker-ce-cli


################################################################################
# Sudo setup
################################################################################
RUN apt -y --allow-downgrades --allow-remove-essential --allow-change-held-packages install sudo
RUN echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME
RUN chmod 0440 /etc/sudoers.d/$USERNAME

################################################################################
# Clean up
################################################################################
RUN apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Run this once again so we have an up-to-date apt database
RUN apt update

################################################################################
# Start user related configuration / TRS
################################################################################
ENV WORKSPACE=/home/$USERNAME/$DEVELOPMENT_DIR
RUN mkdir -p $WORKSPACE/build
RUN mkdir -p /home/$USERNAME/$YOCTO_CACHE/sstate-cache
RUN mkdir -p /home/$USERNAME/$YOCTO_CACHE/downloads
RUN mkdir /home/$USERNAME/$REF_REPO

WORKDIR $WORKSPACE

ADD trs-install.sh $WORKSPACE/trs-install.sh
RUN chmod a+x $WORKSPACE/trs-install.sh
RUN chown -R $USERNAME:$USERNAME $WORKSPACE

USER $USERNAME
ENV PATH="${PATH}:/home/${USERNAME}/.local/bin"

# Configure git so repo won't complain later on
RUN git config --global user.name "${USERNAME}"
RUN git config --global user.email "trs@linaro.org"

RUN chmod a+x $WORKSPACE/trs-install.sh
RUN ln -snf $HOME/$YOCTO_CACHE/downloads $WORKSPACE/build/downloads
RUN ln -snf $HOME/$YOCTO_CACHE/sstate-cache $WORKSPACE/build/sstate-cache

################################################################################
# SSH configuration
################################################################################
# Update password for ssh access and start up ssh
#####
#RUN apt update && apt install openssh-server sudo -y \
#&& echo 'root:password' | chpasswd \
#&& sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config \
#&& service ssh start

#EXPOSE 22
#CMD ["/usr/sbin/sshd", "-D"]
# ENTRYPOINT service bash
# Start Docker daemon

CMD dockerd &

CMD ["/bin/bash"]
