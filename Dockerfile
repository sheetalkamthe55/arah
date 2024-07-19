FROM python

WORKDIR /app

# install python
RUN apt-get update
RUN apt-get install -y curl git python3-pip python3-dev python-is-python3
RUN rm -rf /var/lib/apt/lists/*

# clone streamlit app
RUN git clone https://github.com/sheetalkamthe55/ARHChat.git
RUN curl -s https://raw.githubusercontent.com/sheetalkamthe55/ARHChat/main/requirements.txt?token=GHSAT0AAAAAACTVPEVXMSJSPWCKUYTKAIBCZTZUUDQ | xargs pip install

FROM debian:12-slim AS env-build

WORKDIR /srv

# install build tools and clone and compile llama.cpp
RUN apt-get update && apt-get install -y make git clang-16 libomp-16-dev

RUN git clone https://github.com/ggerganov/llama.cpp.git \
  && cd llama.cpp \
  && make -j CC=clang-16 CXX=clang++-16

FROM debian:12-slim AS env-deploy

# copy openmp libraries
ENV LD_LIBRARY_PATH=/usr/local/lib
COPY --from=0 /usr/lib/llvm-16/lib/libomp.so.5 ${LD_LIBRARY_PATH}/libomp.so.5

# copy llama.cpp binaries
COPY --from=0 /srv/llama.cpp/llama-cli /usr/local/bin/llama-cli
COPY --from=0 /srv/llama.cpp/llama-server /usr/local/bin/llama-server

# create llama user and set home directory
RUN useradd --system --create-home llama

USER llama

WORKDIR /home/llama

EXPOSE 8009

# copy and set entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]