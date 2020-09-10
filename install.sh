#!/bin/bash

# partitioning_process () {

# }

main () {
  set -o nounset
  set -o errexit

  echo -e "\nProcess Partitioning\n"
  run-parts --regex=.sh$ process/partitioning

  echo -e "\nProcess Installation\n"
  run-parts --regex=.sh$ process/installation

  echo -e "\nProcess Settings\n"

  exit 0
}

main