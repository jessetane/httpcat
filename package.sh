#!/usr/bin/env bash
#
# .package for httpcat
#

name() {
  echo "httpcat"
}

version() {
  echo "0.0.4"
}

repository() {
  echo "https://github.com/jessetane/httpcat"
}

dependencies() {
  echo "argue 0.0.5"
}

fetch() {
  git clone "$(repository)" "$src"
}

update() {
  git fetch --all
  git fetch --tags
}

build() {
  mkdir -p "$lib"/"$build"
  cd "$lib"/"$build"
  cp -R "$src"/.git ./
  git reset --hard "$version"
}
