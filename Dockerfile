# dockerfile for postgres

FROM debian:latest

### exposed ARGs override defaults with --build-arg <varname>=<value>

ARG parallel_compile_cores=32
ARG pgsql_version="9.4.1"

EXPOSE 5432/TCP

ARG DEBIAN_FRONTEND=noninteractive

# basic install stuff

RUN apt-get update
RUN apt-get install -y --no-install-recommends apt-utils 
RUN apt-get install -y build-essential
RUN apt-get install -y software-properties-common
RUN apt-get install -y tzdata
RUN apt-get install -y git libssl-dev curl wget
RUN apt-get install -y zlib1g-dev
RUN apt-get install -y pkg-config
RUN apt-get install -y re2c
RUN apt-get install -y vim
RUN apt-get install -y emacs-nox
RUN apt-get install -y telnet
RUN apt-get install -y rsync

# bits to ease development/testing

RUN yes 'y' | ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
RUN cat ~/.ssh/id_rsa.pub
RUN echo "Host host\nHostName 172.17.0.1\nUser ehb" > ~/.ssh/config
# RUN scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null host:.emacs ~/
RUN echo 'env TERM=vt100 emacs -nw $*' > /usr/bin/e && chmod +x /usr/bin/e
RUN touch ~/p
RUN echo 'ls -sxF $*' > /usr/bin/s && chmod +x /usr/bin/s
RUN echo 'ls -lth $* | head' > /usr/bin/lth && chmod +x /usr/bin/lth

#https://ftp.postgresql.org/pub/source/v9.4.1/postgresql-9.4.1.tar.bz2
RUN echo "pgversion - " $pgsql_version " - <<<"
RUN wget https://ftp.postgresql.org/pub/source/v$pgsql_version/postgresql-$pgsql_version.tar.bz2
RUN tar jxf postgresql-$pgsql_version.tar.bz2

RUN cd postgresql-$pgsql_version && ./configure --without-readline
RUN cd postgresql-$pgsql_version && make -j$parallel_compile_cores install

ENV PATH="$PATH:/usr/local/pgsql/bin"
RUN echo 'PATH=$PATH:/usr/local/pgsql/bin' >> /etc/profile

RUN useradd postgres
RUN mkdir /home/postgres
RUN chown postgres:postgres /home/postgres
RUN mkdir /usr/local/pgsql/data
RUN chown postgres /usr/local/pgsql/data
 
RUN su - postgres -c '/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data'
#RUN echo "su - postgres -c '/usr/local/pgsql/bin/postgres -D /usr/local/pgsql/data >/home/postgres/logfile 2>&1 &'" > /bin/start_pg
RUN echo "/usr/local/pgsql/bin/postgres -D /usr/local/pgsql/data >/home/postgres/logfile 2>&1 &" > /bin/start_pg
RUN chmod +x /bin/start_pg

#RUN /usr/local/pgsql/bin/createdb test
#RUN /usr/local/pgsql/bin/psql test
