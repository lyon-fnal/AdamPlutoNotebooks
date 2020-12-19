# docker build -t lyonfnal/pluto .

FROM julia:latest

ENV USER pluto
ENV USER_HOME_DIR /home/${USER}
ENV JULIA_DEPOT_PATH ${USER_HOME_DIR}/.julia
ENV JULIA_NUM_THREADS 100

RUN useradd -m -d ${USER_HOME_DIR} ${USER}

COPY ./prestartup.jl ${USER_HOME_DIR}/
COPY ./Project.toml ${USER_HOME_DIR}/
COPY ./Manifest.toml ${USER_HOME_DIR}/
RUN julia --project=${USER_HOME_DIR} ${USER_HOME_DIR}/prestartup.jl

COPY ./IRMA-031-TimingStudy/ ${USER_HOME_DIR}/IRMA-031-TimingStudy/

COPY ./startup.jl ${USER_HOME_DIR}/
RUN  chown -R ${USER} ${USER_HOME_DIR}

USER ${USER}

EXPOSE 1234
WORKDIR ${USER_HOME_DIR}

CMD [ "julia", "--project=/home/pluto", "/home/pluto/startup.jl" ]