FROM ubuntu:latest

MAINTAINER Christian Brauner christianvanbrauner[at]gmail.com

# # Change to your needs
# RUN locale-gen en_IE.UTF-8
# ENV LANG en_IE.UTF-8
# ENV LANGUAGE en_GB:en
# ENV LC_ALL en_GB.UTF-8

# Update repos
RUN apt-get update -qq
# Run full system upgrade
RUN apt-get dist-upgrade -y

# Install some tools to make life with R easier
RUN apt-get install -y software-properties-common
RUN apt-get install -y --no-install-recommends less
RUN apt-get install -y --no-install-recommends wget
RUN apt-get install -y --no-install-recommends littler

# ssh dependencies and X11-forwarding tools
RUN apt-get install -y --no-install-recommends ssh
RUN apt-get install -y --no-install-recommends xauth

# Needed in order to run multiple processes in one container.
RUN apt-get install -y --no-install-recommends supervisor

# Needed in order to download recommended R packages later on
RUN apt-get install -y --no-install-recommends rsync

# Convenience
RUN apt-get install -y --no-install-recommends mupdf
RUN apt-get install -y --no-install-recommends vim

# R recommended dependencies
RUN apt-get install -y --no-install-recommends gcc g++ gfortran libblas-dev liblapack-dev tcl8.5-dev tk8.5-dev bison groff-base libncurses5-dev libreadline-dev debhelper texinfo libbz2-dev liblzma-dev libpcre3-dev xdg-utils zlib1g-dev libpng-dev libjpeg-dev libx11-dev libxt-dev x11proto-core-dev libpango1.0-dev libcairo2-dev libtiff5-dev xvfb xauth xfonts-base texlive-base texlive-latex-base texlive-generic-recommended texlive-fonts-recommended texlive-fonts-extra texlive-extra-utils texlive-latex-recommended texlive-latex-extra default-jdk mpack bash-completion subversion

# R devel branch
RUN cd /tmp && svn co http://svn.r-project.org/R/trunk R-devel
# R download recommended packages
RUN cd /tmp/R-devel && tools/rsync-recommended
# R set maximum width for R output higher than 10000
# RUN cd /tmp/R-devel/src/include/ && sed -i "s/10000/200000/" Print.h

# Build and install
RUN cd /tmp/R-devel && R_PAPERSIZE=a4 R_BATCHSAVE="--no-save --no-restore" R_BROWSER=xdg-open R_PDFVIEWER=mupdf PAGER=/usr/bin/pager PERL=/usr/bin/perl R_UNZIPCMD=/usr/bin/unzip R_ZIPCMD=/usr/bin/zip R_PRINTCMD=/usr/bin/lpr LIBnn=lib AWK=/usr/bin/awk CFLAGS="-pipe -std=gnu99 -Wall -pedantic -O3" CXXFLAGS="-pipe -Wall -pedantic -O3" ./configure
RUN cd /tmp/R-devel && make && make install

# Adding some packages that are required by some R packages
# For R devtools
RUN apt-get install -y --no-install-recommends libcurl4-gnutls-dev

# For lme4 Github version
RUN apt-get install -y --no-install-recommends lmodern

# Set root passwd; change passwd accordingly
RUN echo "root:test" | chpasswd

# Add user so that no root-login is required; change username and password
# accordingly
RUN useradd -m chbr
RUN echo "chbr:test" | chpasswd
RUN usermod -s /bin/bash chbr
RUN usermod -aG sudo chbr
ENV HOME /home/chbr

# set standard repository to download packages from
RUN cd && printf "options(repos=structure(c(CRAN='http://stat.ethz.ch/CRAN/')))" > /home/chbr/.Rprofile

# set vim as default editor; vi-editing mode for bash
RUN cd && printf "# If not running interactively, don't do anything\n[[ \$- != *i* ]] && return\n\nalias ls='ls --color=auto'\n\nalias grep='grep --color=auto'\n\nPS1='[\u@\h \W]\\$ '\n\ncomplete -cf sudo\n\n# Set default editor.\nexport EDITOR=vim xterm\n\n# Enable vi editing mode.\nset -o vi" > /home/chbr/.bashrc

# Set vi-editing mode for R
RUN cd && printf "set editing-mode vi\n\nset keymap vi-command" > /home/chbr/.inputrc

RUN mkdir /var/run/sshd
RUN mkdir -p /var/log/supervisor

# copy servisord.conf which lists the processes to be spawned once this
# container is started
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 22
CMD ["/usr/bin/supervisord"]
