# docker build . -t krisp-sdk-python:v9.0.0-linux --platform=linux/amd64
FROM python:3.11-slim AS base
COPY --from=ghcr.io/astral-sh/uv:0.5.29 /uv /uvx /bin/ 

WORKDIR /app

COPY pyproject.toml /app/pyproject.toml
COPY uv.lock /app/uv.lock

# RUN uv venv --system
RUN uv pip install -r pyproject.toml --system

FROM base AS build

RUN apt update
RUN apt-get install -y make cmake build-essential
RUN apt-get install -y libsndfile1-dev
RUN pip install pybind11[global]

COPY cmake/ /app/cmake
COPY makefile /app/makefile
COPY src/ /app/src
COPY krisp-audio-sdk-9.0.0-lin_x64-nc /app/krisp-audio-sdk-9.0.0-lin_x64-nc

ENV KRISP_SDK_PATH=/app/krisp-audio-sdk-9.0.0-lin_x64-nc
RUN mkdir /app/LIBSNDFILE_INC
RUN mkdir /app/LIBSNDFILE_LIB
ENV LIBSNDFILE_INC=/app/LIBSNDFILE_INC
ENV LIBSNDFILE_LIB=/app/LIBSNDFILE_LIB
RUN make build python

FROM base AS runner

COPY test/ /app/test
COPY --from=build /app/bin /app/bin
WORKDIR /app/krisp-audio-sdk-9.0.0-lin_x64-nc/external
COPY /krisp-audio-sdk-9.0.0-lin_x64-nc/external/*.so* .

WORKDIR /app/test
RUN "./test-python.sh"
CMD ["sh"]
# CMD ["which", "python3"]
