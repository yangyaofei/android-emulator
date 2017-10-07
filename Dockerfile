# This dockerfile will build an image that can run a full android emulator + the visual emulator over VNC.
# This is maintained and intended to be run in AWS Docker instances with ECS support.
# Based on the work by https://github.com/ConSol/docker-headless-vnc-container

FROM ubuntu:16.04

# Change the sources.list
COPY sources.list /etc/apt/sources.list

# set SSHD
RUN apt-get update \
 && apt-get install -y openssh-server \
 && mkdir /var/run/sshd \
 && echo 'root:root' | chpasswd \
 && sed -i 's/PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
 && /etc/init.d/ssh start
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
EXPOSE 22

# ???
ENV DEBIAN_FRONTEND noninteractive
RUN echo "debconf shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections && \
    echo "debconf shared/accepted-oracle-license-v1-1 seen true" | debconf-set-selections

RUN set -x \
 && : \
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y \
	vim \
	wget \
	socat \
	git \
	bzip2 \
	net-tools \
 && apt-get clean
 
RUN set -x \
 && apt-get -y install software-properties-common \
 && add-apt-repository ppa:webupd8team/java \
 && apt-get update \
 && apt-get -y install oracle-java8-installer

RUN set -x \
 && : Install Android SDK \
 && wget -qO- http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz | tar xz -C /root/ --no-same-permissions \
 && chmod -R a+rX /root/android-sdk-linux \
 && : \
 && : Install Android tools \
 && echo y | /root/android-sdk-linux/tools/android update sdk --filter tools --no-ui --force -a \
 && echo y | /root/android-sdk-linux/tools/android update sdk --filter platform-tools --no-ui --force -a \
 && echo y | /root/android-sdk-linux/tools/android update sdk --filter android-22 --no-ui --force -a \
 && echo y | /root/android-sdk-linux/tools/android update sdk --filter build-tools-22.0.1 --no-ui -a \
 && echo y | /root/android-sdk-linux/tools/android update sdk --filter sys-img-armeabi-v7a-android-22 --no-ui -a \
 && echo y | /root/android-sdk-linux/tools/android update adb
 # && /root/android-sdk-linux/tools/mksdcard 100M /root/sdcard.img \

# Create fake keymap file
RUN mkdir /root/android-sdk-linux/tools/keymaps && \
    touch /root/android-sdk-linux/tools/keymaps/en-us

ENV ANDROID_HOME /root/android-sdk-linux
ENV PATH $PATH:$ANDROID_HOME/tools
ENV PATH $PATH:$ANDROID_HOME/platform-tools
EXPOSE 5555 5554 5037 5900
ADD entrypoint.sh /root/
RUN chmod a+x /root/entrypoint.sh
#HEALTHCHECK --interval=2s --timeout=40s --retries=1 \
#    CMD adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done'
ENTRYPOINT ["/root/entrypoint.sh"]
