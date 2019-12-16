FROM krallin/centos-tini:7
LABEL maintainer="fabien.zarifian@nuevolia.fr"
ENV X2GO_ADMIN_USER admin

EXPOSE 22

# Install
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && rpm --import https://packages.cisofy.com/keys/cisofy-software-rpms-public.key \
    && yum-config-manager --add-repo 'https://packages.cisofy.com/community/lynis/rpm' \
    && rpm --import https://packages.microsoft.com/keys/microsoft.asc \
    && yum-config-manager --add-repo 'https://packages.microsoft.com/yumrepos/vscode' \
    && yum install -y \
        "@mate-desktop" \
        google-droid-sans-fonts \
        google-droid-sans-mono-fonts \
        google-noto-sans-fonts \
        roboto-fontface-fonts \
        oxygen-fonts \
        x2goserver \
        git \
        code \
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