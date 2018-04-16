FROM  ubuntu:16.04
LABEL maintainer="mLearn"

ENV DEBIAN_FRONTEND=noninteractive \
    ANDROID_HOME=/opt/android-sdk-linux \
    NODE_VERSION=6.11.2 \
    NPM_VERSION=3.10.10 \
    IONIC_VERSION=3.19.0 \
    CORDOVA_VERSION=6.5.0 \
    GRADLE_VERSION=4.3.1 \
    SDK_DOWNLOAD_URL=https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip

# Install basics
RUN apt-get update \
    && apt-get install -y --no-install-recommends git wget curl zip unzip ruby ruby-dev gcc make \
    && curl --retry 3 -SLO "http://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz" \
    && tar -xzf "node-v${NODE_VERSION}-linux-x64.tar.gz" -C /usr/local --strip-components=1 \
    && rm "node-v${NODE_VERSION}-linux-x64.tar.gz" \
    && npm install -g npm@${NPM_VERSION} \
    && npm install -g cordova@${CORDOVA_VERSION} \
    && npm install -g ionic@${IONIC_VERSION} \
    && npm cache clear --force \
    && gem install sass

# Install python-software-properties (so you can do add-apt-repository)
RUN apt-get update \
    && apt-get install -y --no-install-recommends -q python-software-properties software-properties-common \
    && add-apt-repository ppa:webupd8team/java -y \
    && echo oracle-java8-installer shared/accepted-oracle-license-v1-1 \
    select true | /usr/bin/debconf-set-selections \
    && apt-get update \
    && apt-get -y install oracle-java8-installer

#ANDROID STUFF
RUN echo ANDROID_HOME="${ANDROID_HOME}" >> /etc/environment \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y expect ant wget zipalign libc6-i386 \
    lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1 qemu-kvm kmod oracle-java8-set-default\
    && apt-get clean \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Android SDK && Gradle
RUN cd /opt \
    && wget --output-document=android-sdk-linux.zip ${SDK_DOWNLOAD_URL} \
    && unzip -d ${ANDROID_HOME} android-sdk-linux.zip \
    && rm -f android-sdk-linux.zip \
    && chown -R root. /opt

# Install Gradle
RUN wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    mkdir /opt/gradle && \
    unzip -d /opt/gradle gradle-${GRADLE_VERSION}-bin.zip && \
    rm -rf gradle-${GRADLE_VERSION}-bin.zip

# Setup environment
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:/opt/gradle/gradle-${$GRADLE_VERSION}bi

RUN touch ~/.android/repositories.cfg \
    sdkmanager --update \
    && yes | sdkmanager --licenses \
    && sdkmanager "platforms;android-26" "build-tools;26.0.3" "extras;google;google_play_services" "extras;google;m2repository" \
    && yes | sdkmanager --licenses

# Test First Build so that it will be faster later
RUN cd myApp && \
    ionic cordova build android --prod --no-interactive --release

WORKDIR myApp
EXPOSE 8100 35729
CMD ["ionic", "serve"]
