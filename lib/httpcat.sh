#!/usr/bin/env bash
#
# httpcat - an http server in bash using netcat
#

httpcat() {
  
  # vars
  pid="$$"
  cwd="$(pwd)"
  uname="$(uname)"
  port="80"
  status="200"
  
  # cd to own dir
  cd "$(dirname "$BASH_SOURCE")"

  # deps
  source argue/0.0.1/lib/argue.sh || return 1
  
  # parse arguments
  args=("$@")
  argue "-p, --port, +"\
        "-s, --status, +" || return 1
  
  # args & options
  index="${args[0]}"
  [ -n "${opts[0]}" ] && port="${opts[0]}"
  [ -n "${opts[2]}" ] && status="${opts[2]}"
  
  # sanity
  
  echo "one: $cwd - $index"
  [ -z "$index" ] && echo "please specify a file to serve" >&2 && exit 1
  [ ! -f "$cwd/$index" ] && echo "$index: file does not exist" >&2 && exit 1
  
  # 
  serve
}

serve() {
  
  # load the file to serve into memory
  index="$(cat "$cwd/$index")" || quit 1
  
  # make some fifos
  mkfifo request
  mkfifo response
  
  # trap ctrl-C
  trap "echo -n ' '; quit" SIGTERM SIGINT SIGQUIT SIGKILL
  
  # start listening
  echo "listening on $port"
  listen
}

listen() {
  
  # implementations may vary
  case "$uname" in
    "Darwin") cat response | nc -l "$port" > request &;;
    *)        cat response | netcat -l -p "$port" > request &;;
  esac
  
  # wait for request
  handle
}

handle() {
  got_request=false

  # read request
  while read line
  do
    got_request=true
    
    # log to stdout
    echo "$line"
    
    # only read up to first empty line
    test "${#line}" = 1 && break
  done < request
  
  # if we didn't get a request, there was an error
  [ $got_request = false ] && quit 1
  
  # respond
  echo -e "HTTP/1.1 $status\r\n\r\n$index" > response
  
  # killing netcat seems to be the 
  # only way to close the connection
  close
  
  # start listening again
  listen
}

# kills all child processes
close() {
  while read process
  do
    child="$(echo "$process" | sed "s/[ ]*\([^ ]*\).*/\1/")"
    if [ "$child" != "$pid" ]
    then
      kill "$child" 2> /dev/null
    fi
  done < <(ps -o pid -o pgid -o command | grep "$pid")
}

quit() {
  
  # kill children
  close
  
  # remove fifos
  rm -rf request
  rm -rf response
  
  # runtime error
  [ -n "$1" ] && exit "$1"
  
  # graceful
  echo "bye!"
  exit 0
}
