FROM brauner/debian:testing

MAINTAINER Christian Brauner christianvanbrauner[at]gmail.com

RUN export DEBIAN_FRONTEND=noninteractive \
&& printf "\npath-exclude=/usr/share/locale/*" >> /etc/dpkg/dpkg.cfg.d/excludes \
&& printf "\npath-include=/usr/share/locale/en*" >> /etc/dpkg/dpkg.cfg.d/excludes \
&& printf "\npath-include=/usr/share/locale/locale.alias" >> /etc/dpkg/dpkg.cfg.d/excludes \
&& printf "\npath-exclude=/usr/share/man/*" >> /etc/dpkg/dpkg.cfg.d/excludes \
&& printf "\npath-include=/usr/share/man/en*" >> /etc/dpkg/dpkg.cfg.d/excludes \
&& printf "\npath-include=/usr/share/man/man[1-9]/*" >> /etc/dpkg/dpkg.cfg.d/excludes \
&& apt-get update -qq -y \
&& apt-get install -y --no-install-recommends \
   locales \
   less \
   libcurl4-gnutls-dev \
   zip \
   unzip \
&& apt-get build-dep -y \
   r-base \
   r-base-dev \
   r-recommended \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

RUN apt-get update -qq -y \
&& apt-get install -y --no-install-recommends \
   git \
&& cd /tmp \
&& git clone git://github.com/xianyi/OpenBLAS openblas \
&& cd /tmp/openblas \
&& make TARGET=SANDYBRIDGE \
&& make install PREFIX=/usr/local \
&& cd \
&& rm -rf /tmp/openblas \
&& apt-get autoremove -y \
   git \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

RUN apt-get update -qq -y \
&& apt-get install -y --no-install-recommends \
   subversion \
   rsync \
&& cd /tmp \
&& svn co http://svn.r-project.org/R/branches/R-3-1-branch R-patched \
&& cd /tmp/R-patched \
&& tools/rsync-recommended \
&& AWK=/usr/bin/awk \
   CFLAGS="-march=ivybridge -pipe -std=gnu99 -Wall -pedantic -O3 -m64"  \
   CXXFLAGS="-march=ivybridge -pipe -Wall -pedantic -O3 -m64" \
   FFLAGS="-march=ivybridge -g -O3 -m64" \
   FCFLAGS="-march=ivybridge -g -O3 -m64" \
   LIBnn=lib \
   PAGER=/usr/bin/less \
   PERL=/usr/bin/perl \
   R_PAPERSIZE=a4 \
   R_BATCHSAVE="--no-save --no-restore" \
   R_BROWSER=xdg-open \
   R_PDFVIEWER=mupdf \
   R_UNZIPCMD=/usr/bin/unzip \
   R_ZIPCMD=/usr/bin/zip \
   R_PRINTCMD=/usr/bin/lpr \
   ./configure --enable-R-shlib \
               --without-blas \
               --without-lapack \
               --with-readline \
&& make \
&& make install \
&& cd /usr/local/lib/R/lib \
&& mv libRblas.so libRblas.so.old \
&& ln -s /usr/local/lib/libopenblas_sandybridgep-r0.2.12.so libRblas.so \
&& cd \
&& rm -rf /tmp/R-patched \
&& apt-get autoremove -y \
   subversion \
   rsync \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/*

# Add user
RUN echo "root:test" | chpasswd \
&& useradd -u 1000 -m docker \
&& echo "docker:test" | chpasswd \
&& usermod -s /bin/bash docker \
&& usermod -a -G 100 docker \
# && usermod -a -G sudo docker \
# On my system the gid of group video is 91. I need to change gid of group
# video on ubuntu in order to allow access to video devices when I add them to
# the container.
&& groupmod -g 91 video \
&& usermod -a -G video docker \
&& printf "\nen_IE.UTF-8 UTF-8\n" >> /etc/locale.gen \
&& locale-gen \
# set standard repository
&& cd \
&& printf "options(repos=structure(c(CRAN='http://stat.ethz.ch/CRAN/')))\n" > /home/docker/.Rprofile \
# set vim as default editor; vi-editing mode for bash
&& printf "# If not running interactively, don't do anything\n[[ \$- != *i* ]] && return\n\nalias ls='ls --color=auto'\n\nalias grep='grep --color=auto'\n\nPS1='[\u@\h \W]\\$ '\n\ncomplete -cf sudo\n\n# Set default editor.\nexport EDITOR=vim xterm\n\nexport OPENBLAS_NUM_THREADS=4\n\n# Enable vi editing mode.\nset -o vi\n" > /home/docker/.bashrc \
&& printf "# If not running interactively, don't do anything\n[[ \$- != *i* ]] && return\n\nalias ls='ls --color=auto'\n\nalias grep='grep --color=auto'\n\nPS1='[\u@\h \W]\\$ '\n\ncomplete -cf sudo\n\n# Set default editor.\nexport EDITOR=vim xterm\n\nexport OPENBLAS_NUM_THREADS=4\n\n# Enable vi editing mode.\nset -o vi\n" > /root/.bashrc \
# Set vi-editing mode for R
&& printf "set editing-mode vi\n\nset keymap vi-command\n" > /home/docker/.inputrc \
&& printf "set editing-mode vi\n\nset keymap vi-command\n" > /root/.inputrc

ENV LANG en_IE.UTF-8
ENV HOME /home/docker
WORKDIR /home/docker
USER docker

ENTRYPOINT ["/usr/local/bin/R"]