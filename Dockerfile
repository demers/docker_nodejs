FROM ubuntu

MAINTAINER FND <fndemers@gmail.com>

ENV PROJECTNAME=NODEJS

ENV WORKDIRECTORY=/home/ubuntu

# Access SSH login
ENV USERNAME=ubuntu
ENV PASSWORD=ubuntu

RUN apt-get update

RUN apt-get install -y vim-nox curl git exuberant-ctags

# Install a basic SSH server
RUN apt install -y openssh-server
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd
RUN /usr/bin/ssh-keygen -A

# Install Java
RUN apt-get install -qy --no-install-recommends python-dev default-jdk

# Add user to the image
RUN adduser --quiet --disabled-password --shell /bin/bash --home /home/${USERNAME} --gecos "User" ${USERNAME}
# Set password for the jenkins user (you may want to alter this).
RUN echo "$USERNAME:$PASSWORD" | chpasswd

RUN apt-get clean && apt-get -y update && apt-get install -y locales && locale-gen fr_CA.UTF-8
ENV TZ=America/Toronto
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt install -y fish

RUN echo "export PS1=\"\\e[0;31m $PROJECTNAME\\e[m \$PS1\"" >> ${WORKDIRECTORY}/.bash_profile

# Install all you want here...

ENV TZ=America/Toronto
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


# Standard SSH port
EXPOSE 22

# Installation X11.
RUN apt install -y xauth vim-gtk

RUN cd ${WORKDIRECTORY} \
    && git clone git://github.com/zaiste/vimified.git \
    && ln -sfn vimified/ ${WORKDIRECTORY}/.vim \
    && ln -sfn vimified/vimrc ${WORKDIRECTORY}/.vimrc \
    && cd vimified \
    && mkdir bundle \
    && mkdir -p tmp/backup tmp/swap tmp/undo \
    && git clone https://github.com/gmarik/vundle.git bundle/vundle \
    && echo "let g:vimified_packages = ['general', 'coding', 'fancy', 'indent', 'css', 'os', 'ruby', 'js', 'haskell', 'python', 'color']" > local.vimrc

COPY after.vimrc ${WORKDIRECTORY}/vimified/

COPY extra.vimrc ${WORKDIRECTORY}/vimified

RUN cd ${WORKDIRECTORY} \
    && ln -s vimified .vim \
    && ln -s vimified/vimrc .vimrc

RUN echo "vim +BundleInstall +qall" >> ${WORKDIRECTORY}/.bash_profile


RUN apt -qy install gcc g++ make

RUN apt install -qy npm

RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash

RUN apt -qy install npm

RUN nodejs --version

RUN echo "export NVM_DIR=\"\$HOME/.nvm\"" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \. \"\$NVM_DIR/bash_completion\"" >> ${WORKDIRECTORY}/.bash_profile
RUN echo "echo To install Node, type nvm install node" >> ${WORKDIRECTORY}/.bash_profile

RUN cd ${WORKDIRECTORY} \
    && mkdir work \
&& chown -R $USERNAME:$PASSWORD work vimified .vim .vimrc .bash_profile


# Start SSHD server...
CMD ["/usr/sbin/sshd", "-D"]