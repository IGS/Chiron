FROM umigs/chiron-core:latest

###########
## Qiime ##
###########

RUN apt-get -q -y update \
  && apt-get -q install -y --no-install-recommends libgl1-mesa-glx

# Configure matplotlib for a headless environment
#   https://forum.qiime2.org/t/matplotlib-configuration-issues/185/2?u=thermokarst
RUN mkdir -p ~/.config/matplotlib
RUN echo "backend: Agg" > ~/.config/matplotlib/matplotlibrc

# Attempt to resolve python Click library errors
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

# Dependency: miniconda
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda
ENV PATH $PATH:/opt/miniconda/bin
RUN rm Miniconda3-latest-Linux-x86_64.sh

# Primary: Qiime2-2017.5
RUN conda create -n qiime2-2017.5 --file https://data.qiime2.org/distro/core/qiime2-2017.5-conda-linux-64.txt

# Trying to avoid having to `source activate qiime2-2017.5
ENV PATH /opt/miniconda/envs/qiime2-2017.5/bin:$PATH
ENV CONDA_PREFIX /opt/miniconda/envs/qiime2-2017.5
ENV CONDA_DEFAULT_ENV qiime2-2017.5
