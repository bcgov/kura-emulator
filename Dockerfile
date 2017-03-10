FROM fedora:25

MAINTAINER Jens Reimann <jreimann@redhat.com>
LABEL maintainer "Jens Reimann <jreimann@redhat.com>"

ENV JAVA_HOME=/usr/lib/jvm/jre-1.8.0
ENV MAVEN_PROPS=-Dmaven.test.skip=true
ENV KURA_COMMIT=a0eb9adcf858806183b6bf869d5b614c3dbe389a

COPY kura.patch /

RUN mkdir -p /opt/eclipse && \
    useradd -m -d /opt/eclipse/kura_3.0.0-SNAPSHOT_fedora25-nn \
            -s /bin/bash kurauser && \
    dnf -y install wget git java-1.8.0-openjdk-devel maven procps-ng zip unzip tar psmisc telnet dos2unix net-tools hostname && \
    git clone https://github.com/eclipse/kura.git && cd kura && git checkout $KURA_COMMIT && \
    ( \
      cd /kura && \
      mvn -f target-platform/pom.xml clean install $MAVEN_PROPS && \
      mvn -f kura/manifest_pom.xml clean install $MAVEN_PROPS -Pspeedup && \
      git apply --verbose /kura.patch && \
      mv kura/distrib/src/main/resources/fedora25 kura/distrib/src/main/resources/fedora25-nn && \
      mvn -f kura/distrib/pom.xml clean install $MAVEN_PROPS -Pfedora25 \
    ) && \
    /kura/kura/distrib/target/kura_3.0.0-SNAPSHOT_fedora25-nn_installer.sh && \
    wget https://github.com/bcgov/kura-emulator/blob/master/weather_demo.csv -O /opt/eclipse/kura/weather_demo.csv && \
    dnf remove -y wget git java-1.8.0-openjdk-devel maven && \
    dnf install -y jre-1.8.0-openjdk-headless && \
    rm -Rf /kura /root/.m2 && dnf -y clean all && \
    chown -R kurauser:root /opt/eclipse/kura_3.0.0-SNAPSHOT_fedora25-nn && \
    chmod -R g+rwx  /opt/eclipse/kura_3.0.0-SNAPSHOT_fedora25-nn && \
    touch /var/log/kura.log && \
    chown kurauser:root /var/log/kura.log && \
    chmod g+rwx /var/log/kura.log

USER kurauser

EXPOSE 8080

ENTRYPOINT ["/opt/eclipse/kura/bin/start_kura.sh"]
