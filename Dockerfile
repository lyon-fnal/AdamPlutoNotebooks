# docker build -t lyonfnal/pluto .
# Following https://github.com/lungben/PlutoUtils.jl/blob/master/docker/default/Dockerfile

FROM julia:latest

ENV USER pluto
ENV USER_HOME_DIR /home/${USER}
ENV JULIA_DEPOT_PATH ${USER_HOME_DIR}/.julia
ENV JULIA_NUM_THREADS 100

RUN useradd -m -d ${USER_HOME_DIR} ${USER}

USER ${USER}
WORKDIR ${USER_HOME_DIR}

COPY --chown=$USER ./prestartup.jl ${USER_HOME_DIR}/
COPY --chown=$USER ./Project.toml ${USER_HOME_DIR}/
COPY --chown=$USER ./Manifest.toml ${USER_HOME_DIR}/
RUN julia --project=${USER_HOME_DIR} ${USER_HOME_DIR}/prestartup.jl

COPY --chown=$USER ./IRMA-031-TimingStudy/ ${USER_HOME_DIR}/IRMA-031-TimingStudy/

COPY --chown=$USER ./startup.jl ${USER_HOME_DIR}/

EXPOSE 1234

CMD [ "julia", "--project=/home/pluto", "/home/pluto/startup.jl" ]