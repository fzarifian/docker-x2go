FROM centos:7
LABEL maintainer="fabien.zarifian@nuevolia.fr"
EXPOSE 22

# Install
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
  && rpm --import https://packages.cisofy.com/keys/cisofy-software-rpms-public.key \
  && yum-config-manager --add-repo 'https://packages.cisofy.com/community/lynis/rpm' \
  && rpm --import https://packages.microsoft.com/keys/microsoft.asc \
  && yum-config-manager --add-repo 'https://packages.microsoft.com/yumrepos/vscode' \
  && yum install -y \
    "@mate-desktop-environment" \
    "@mate-desktop" \
    google-droid-sans-fonts \
    google-droid-sans-mono-fonts \
    roboto-fontface-fonts \
    oxygen-fonts \
    google-noto-sans-fonts \
    man-pages-fr \
    hunspell-fr \
    auditd \
    x2goserver \
    git \
    code \
    unzip \
    sudo \
    rsync \
    sysstat \
    arpwatch \
    lynis \
 && yum clean all

# Configure
RUN groupadd ssh-users \
    && adduser -m -G ssh-users user
ADD ./entrypoint.sh /entrypoint.sh
ADD ./sshd/sshd_config /etc/ssh/sshd_config
ADD ./sudo/sudoers /etc/sudoers.d/999-sudoers-docker
ADD ./userskel /home/user/.config
RUN mkdir -p /home/user/.ssh \
    && chmod 700 /home/user/.ssh \
    && mkdir -p /var/run/sshd \
    && chmod 440 /etc/sudoers.d/999-sudoers-docker \
    && chmod 750 /entrypoint.sh \
    && chown -R user:user /home/user/.config
VOLUME /home/user/.ssh

# Run
ENTRYPOINT [ "/entrypoint.sh" ]