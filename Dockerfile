FROM centos:7 AS dependencies-stage
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /tini.asc
RUN ( \
        gpg --batch --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
        || gpg --batch --keyserver pgp.mit.edu --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
        || gpg --batch --keyserver keyserver.pgp.com --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
        || gpg --batch --keyserver p80.pool.sks-keyservers.net --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
    ) && gpg --batch --verify /tini.asc /tini \
    && chmod +x /tini

FROM centos:7 AS build-stage
LABEL maintainer="fabien.zarifian@nuevolia.fr"
ENV X2GO_ADMIN_USER admin

COPY --from=dependencies-stage /tini /usr/local/bin/tini

EXPOSE 22

# Install
RUN yum install -y yum-utils epel-release deltarpm \
    && yum clean all \
    && rpm --import https://packages.cisofy.com/keys/cisofy-software-rpms-public.key \
    && yum-config-manager --add-repo 'https://packages.cisofy.com/community/lynis/rpm' \
    && rpm --import https://packages.microsoft.com/keys/microsoft.asc \
    && yum-config-manager --add-repo 'https://packages.microsoft.com/yumrepos/vscode' \
    && rm -f /var/cache/yum/timedhosts.txt \
    && yum update -y --obsoletes

RUN yum install -y \
        mate-desktop mate-panel mate-applets mate-menus mate-common mate-control-center mate-utils \
        mate-backgrounds mate-themes mate-themes-extra mate-icon-theme mate-icon-theme-faenza  \
        google-droid-sans-fonts google-droid-sans-mono-fonts google-noto-sans-fonts \
        roboto-fontface-fonts oxygen-fonts \
        x2goserver \
        git code \
        unzip \
        sudo \
        rsync \
        sysstat \
    && yum clean all

# Configure
ADD ./skel/config /etc/skel/.config
RUN groupadd ssh-users \
    && adduser -m -k /etc/skel -G ssh-users ${X2GO_ADMIN_USER}

ADD ./docker-entrypoint.sh /docker-entrypoint.sh
ADD ./sshd/sshd_config /etc/ssh/sshd_config
ADD ./sudo/sudoers /etc/sudoers.d/999-sudoers-docker
RUN mkdir -p /home/${X2GO_ADMIN_USER}/.ssh \
    && chmod 700 /home/${X2GO_ADMIN_USER}/.ssh \
    && mkdir -p /var/run/sshd \
    && chmod -R 440 /etc/sudoers.d \
    && chmod 750 /docker-entrypoint.sh

# Run
ENTRYPOINT ["/usr/local/bin/tini", "--", "/docker-entrypoint.sh" ]
