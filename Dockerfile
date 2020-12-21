# docker build -t lyonfnal/pluto .
# Following https://github.com/lungben/PlutoUtils.jl/blob/master/docker/default/Dockerfile

FROM julia:latest

# We need gcc to build shared object
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		build-essential \
	; \
	rm -rf /var/lib/apt/lists/*

ENV USER pluto
ENV USER_HOME_DIR /home/${USER}
ENV JULIA_DEPOT_PATH ${USER_HOME_DIR}/.julia
ENV JULIA_NUM_THREADS 100

RUN useradd -m -d ${USER_HOME_DIR} ${USER}

WORKDIR ${USER_HOME_DIR}

COPY --chown=$USER ./prestartup.jl ${USER_HOME_DIR}/
COPY --chown=$USER ./Project.toml ${USER_HOME_DIR}/
COPY --chown=$USER ./Manifest.toml ${USER_HOME_DIR}/
COPY --chown=$USER ./precompile.jl ${USER_HOME_DIR}/

RUN julia --project=${USER_HOME_DIR} ${USER_HOME_DIR}/prestartup.jl

RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

RUN chown -R ${USER} ${USER_HOME_DIR}

COPY --chown=$USER ./IRMA-031-TimingStudy/ ${USER_HOME_DIR}/IRMA-031-TimingStudy/

COPY --chown=$USER ./startup.jl ${USER_HOME_DIR}/

USER ${USER}

EXPOSE 1234

CMD [ "julia", "--project=/home/pluto", "/home/pluto/startup.jl" ]