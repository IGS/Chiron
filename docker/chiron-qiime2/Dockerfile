FROM umigs/chiron-core:1.2.0

###########
## Qiime ##
###########

RUN apt-get -q -y update \
  && apt-get -q install -y --no-install-recommends libgl1-mesa-glx

# Configure matplotlib for a headless environment
#   https://forum.qiime2.org/t/matplotlib-configuration-issues/185/2?u=thermokarst
#RUN mkdir -p ~/.config/matplotlib
#RUN echo "backend : Agg" > ~/.config/matplotlib/matplotlibrc

# Attempt to resolve python Click library errors
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8

# Dependency: miniconda
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
RUN bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda
ENV PATH $PATH:/opt/miniconda/bin
RUN rm Miniconda3-latest-Linux-x86_64.sh

# Primary: Qiime2-2017.5
ARG QIIME2_VERSION=qiime2-2017.5
RUN conda create -n $QIIME2_VERSION --file https://data.qiime2.org/distro/core/$QIIME2_VERSION-conda-linux-64.txt

# Trying to avoid having to `source activate qiime2-2017.5
ENV PATH /opt/miniconda/envs/$QIIME2_VERSION/bin:$PATH
ENV CONDA_PREFIX /opt/miniconda/envs/$QIIME2_VERSION
ENV CONDA_DEFAULT_ENV $QIIME2_VERSION

# Change backend in Conda from Qt5Agg to Agg since we are using a headless environment (AKA Docker)
RUN echo "backend : Agg" > $CONDA_PREFIX/lib/python3.5/site-packages/matplotlib/mpl-data/matplotlibrc
