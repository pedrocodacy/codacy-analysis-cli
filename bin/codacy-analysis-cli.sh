#!/usr/bin/env bash

#
# Codacy Analysis CLI Wrapper
#

log_error() {
  local message=$1

  cat >&2 <<-EOF
		We encountered a problem with your Docker setup:
		  > ${message}
		
		Please check https://github.com/codacy/codacy-analysis-cli for alternative instructions.
		
	EOF
  exit 3
}

test_docker_socket() {
  if [ ! -S /var/run/docker.sock ]; then
    log_error "/var/run/docker.sock must exist as a Unix domain socket"
  elif [ -n "${DOCKER_HOST}" ] && [ "${DOCKER_HOST}" != "unix:///var/run/docker.sock" ]; then
    log_error "invalid DOCKER_HOST=${DOCKER_HOST}, must be unset or unix:///var/run/docker.sock"
  fi
}

run() {
  docker run \
    --rm \
    --env CODACY_CODE="$CODACY_CODE" \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$CODACY_CODE":"$CODACY_CODE" \
    --volume /tmp:/tmp \
    codacy/codacy-analysis-cli -- \
    "$@"
}

analysis_file() {
  local filename="";
  local is_filename=0;
  for arg; do
    case "$arg" in
      -*)
        case ${arg} in
          -d | --directory)
            is_filename=1 # next argument will be the directory or file
            ;;
        esac
        ;;
      *)
        if [ ${is_filename} -eq 1 ]; then
          if [ -n "$filename" ]; then
            echo "Please provide only one file or directory to analyse" >&2
            exit 1
          else
            is_filename=0
            filename="$arg"
          fi
        fi
        ;;
    esac
  done

  if [ -n "$filename" ]; then
    CODACY_CODE="$filename"
  else
    CODACY_CODE="$(pwd)"
  fi
}

test_docker_socket

analysis_file "$@"

run "$@"
