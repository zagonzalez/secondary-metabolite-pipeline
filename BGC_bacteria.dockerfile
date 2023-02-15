# ***** BEGIN common configuration lines
# Some of these tools could be removed if you're sure you won't need them

FROM ubuntu:20.04

LABEL Copyright 2022, SolareaBio

ENV DEBIAN_FRONTEND=noninteractive
RUN apt -y update
RUN apt -y upgrade -y

# Set the time zone to EST
RUN apt -y install tzdata
ENV TZ="America/New_York"

# Required for some packages
ENV LANG C.UTF-8

# Install the driver for accessing the EFS
RUN apt-get -y install nfs-common

# Setup Python
# RUN apt -y install python-pip
RUN apt -y install python3-pip
RUN pip3 install -U pip
RUN ln -sfn /usr/bin/python3.7 /usr/bin/python

# Install Java
RUN apt -y install openjdk-11-jre-headless

# Install the AWS CLI
RUN pip3 install --upgrade pip awscli
RUN aws configure set region us-east-1

# Install bc
RUN apt -y install bc

# Install jq
RUN apt -y install jq

# Install tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN useradd -m docker
RUN echo "docker:docker" | chpasswd
RUN adduser docker sudo

RUN mkdir -p /container/app/
ENV PATH="/container/app:${PATH}"

VOLUME /EFS
WORKDIR /container/app

# ***** END of common configuration lines




# ***** BEGIN custom configuration lines
# Install Ruby
RUN apt -y install ruby-full

# Setup CheckM
# HMMER
# RUN apt -y install hmmer
# diamond
# ENV PATH="/EFS/tools/diamond-2.0.6:${PATH}"
# glimmrhmm
# ENV PATH="EFS/tools/GlimmerHMM-3.0.4:${PATH}"
# prodigal
# ENV PATH="/EFS/tools/Prodigal:${PATH}"
# pplacer
ENV PATH="/EFS/tools/pplacer-v1.1.alpha19:${PATH}"
# blast
# ENV PATH="/EFS/tools/ncbi-blast-2.10.0+:${PATH}" 
# ENV PATH="/EFS/tools/miniconda:${PATH}"
# RUN conda env create


# Python libraries required for CheckM
RUN pip3 install numpy matplotlib pysam
# CheckM itself
RUN pip3 install checkm-genome
# Install Jinja2
RUN pip3 install Jinja2==3.1.1



# Install antismash
RUN apt-get -y update
RUN apt-get -y install -y apt-transport-https
RUN apt-get -y install wget
RUN wget http://dl.secondarymetabolites.org/antismash-stretch.list -O /etc/apt/sources.list.d/antismash.list
RUN wget -q -O- http://dl.secondarymetabolites.org/antismash.asc | apt-key add -
RUN apt-get -y update
RUN apt-get -y install hmmer2 hmmer diamond-aligner fasttree prodigal ncbi-blast+ muscle
RUN wget https://dl.secondarymetabolites.org/releases/6.1.1/antismash-6.1.1.tar.gz
RUN tar -zxf antismash-6.1.1.tar.gz
RUN pip3 install ./antismash-6.1.1
ENV ANTISMASH_DB=/EFS/database/antismash

# Setup conda (for deepbgc)
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py37_4.12.0-Linux-x86_64.sh -O ~/miniconda.sh && \
     /bin/bash ~/miniconda.sh -b -p /opt/conda
# set conda to path
ENV PATH=$CONDA_DIR/bin:$PATH
# Source conda
# RUN source /EFS/tools/miniconda/etc/profile.d/conda.sh
# create deepbgc environment
# RUN conda config --add channels bioconda
# RUN conda config --add channels conda-forge
# RUN conda create -n deepbgc3 python=3.7 hmmer prodigal
# ENV PATH="/EFS/tools/miniconda/etc/profile.d:${PATH}"
# RUN . /EFS/tools/miniconda/etc/profile.d/conda.sh
# RUN conda init bash
# RUN conda activate deepbgc3
# RUN pip install deepbgc
# RUN deepbgc download
# RUN conda deactivate

# Install deepbgc
# RUN pip3 install deepbgc

# Setup bagel
ENV PATH="/EFS/tools/BAGEL/bagel4_2022:${PATH}"
RUN export PERL5LIB=/data/pg-molgen/software/bagel4/lib
RUN perl -MCPAN -e'install "LWP::Simple"'

# Setup code
COPY BGC_bacteria.sh /container/app/
RUN chmod +x /container/app/BGC_bacteria.sh

COPY run_long_process.sh /container/app/
RUN chmod +x /container/app/run_long_process.sh

# ***** END custom configuration lines




# ***** BEGIN common execution lines

ENTRYPOINT ["/tini", "--", "./BGC_bacteria.sh"]
CMD ["--help"]

# ***** END common execution lines




