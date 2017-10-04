# This dockerfile will build an image that can run a full android emulator + the visual emulator over VNC.
# This is maintained and intended to be run in AWS Docker instances with ECS support.
# Based on the work by https://github.com/ConSol/docker-headless-vnc-container

FROM ubuntu:14.04

# Change the sources.list
COPY sources.list /etc/apt/sources.list
# set the language
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8    
ENV LANGUAGE en_US:en    
ENV LC_ALL en_US.UTF-8 
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

ENV SAKULI_DOWNLOAD_URL https://labs.consol.de/sakuli/install
ENV JAVA_VERSION 8u65
ENV JAVA_HOME /usr/lib/jvm/java-$JAVA_VERSION

RUN set -x \
 && : \
 && apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y \
	unzip \
	vim \
	vnc4server \
	wget \
	xfce4 \
 && : Add Oracle JAVA JRE8 \
 && mkdir -p $JAVA_HOME \
 && wget -qO- $SAKULI_DOWNLOAD_URL/3rd-party/java/jre-$JAVA_VERSION-linux-x64.tar.gz | tar xz --strip 1 -C $JAVA_HOME \
 && update-alternatives --install "/usr/bin/java" "java" "$JAVA_HOME/bin/java" 1 \
 && update-alternatives --install "/usr/bin/javaws" "javaws" "$JAVA_HOME/bin/javaws" 1 \
 && : \
 && : Setup specifics for android support - glx drivers etc. \
 && apt-get install -y \
	git \
	lib32gcc1 \
	lib32ncurses5 \
	lib32stdc++6 \
	lib32z1 \
	libc6-i386 \
	libgl1-mesa-dev \
	nano \
 && apt-get clean \
 && : \
 && : Install Android SDK \
 && wget -qO- http://dl.google.com/android/android-sdk_r24.4.1-linux.tgz | tar xz -C /root/ --no-same-permissions \
 && chmod -R a+rX /root/android-sdk-linux \
 && : \
 && : Install Android tools \
 && echo y | /root/android-sdk-linux/tools/android update sdk --filter tools --no-ui --force -a \
 && echo y | /root/android-sdk-linux/tools/android update sdk --filter platform-tools --no-ui --force -a \
 && echo y | /root/android-sdk-linux/tools/android update sdk --filter android-21 --no-ui --force -a \
 && echo y | /root/android-sdk-linux/tools/android update sdk --filter build-tools-21.0.1 --no-ui -a \
 && echo y | /root/android-sdk-linux/tools/android update sdk --filter sys-img-armeabi-v7a-android-21 --no-ui -a \
 && /root/android-sdk-linux/tools/mksdcard 100M /root/sdcard.img \
 && echo n | /root/android-sdk-linux/tools/android create avd  -t 'android-21' -b armeabi-v7a -n android-5.0.1 

ENV ANDROID_HOME /root/android-sdk-linux
ENV PATH $PATH:${ANDROID_HOME}/tools:$ANDROID_HOME/platform-tools

ADD scripts /root/scripts
RUN chmod a+x /root/scripts/*.sh
CMD ["/root/scripts/main.sh"]
