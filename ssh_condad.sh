#!/bin/bash

#
# usage:
#       ./ssh_condad.sh [user] [server_address] [server_ssh_port] [local_listen_port]
#


USER=$1
ADDR=$2
SSH_PORT=$3
LOCAL_LISTEN_PORT=$4

REMOTE_PORT=8888

if [ -z "$LOCAL_LISTEN_PORT" ];
then
    FORWARD_TO_LOCAL=""
else
    FORWARD_TO_LOCAL="-L $LOCAL_LISTEN_PORT:localhost:$REMOTE_PORT"
fi

###############
# ssh Command Line Options
# https://www.attachmate.com/documentation/rsit-unix-802/rsit-unix-guide/data/ssh_options_ap.htm
#
# -L [protocol/][listening_host:] listening_port:host:hostport
#
# Redirects data from the specified local port, through the secure tunnel to the specified destination host and port.
#
# When a Secure Shell connection is established, the Secure Shell client opens a socket on the Secure Shell client
# host using the designated local port (listening_port).
# (On client hosts with multiple interfaces, use listening_host to specify which interface.) Configure your application client
# (the one whose data you want to forward) to send data to the forwarded socket
# (rather than directly to the destination host and port).
#
# When that client establishes a connection, all data sent to the forwarded port is redirected through
# the secure tunnel to the Secure Shell server, which decrypts it and then directs it to the destination socket (host,hostport).
# Unless the gateway ports option is enabled, the forwarded local port is available only to clients running on
# the same computer as the Secure Shell client. The optional protocol can be tcp or ftp.
#
# Multiple client applications can use the forwarded port, but the forward is active only while ssh is running.
# Note: If the final destination host and port are not on the Secure Shell server host,
# data is sent in the clear between the Secure Shell host and the application server host.
# You can also configure local forwarding in the configuration file using the LocalForward keyword.
#
###############
# ssh(1): OpenSSH SSH client - Linux man page
# https://linux.die.net/man/1/ssh
#
# -N' Do not execute a remote command. This is useful for just forwarding ports (protocol version 2 only).
#
# -n' Redirects stdin from /dev/null (actually, prevents reading from stdin).
# This must be used when ssh is run in the background. A common trick is to use this to run X11 programs on a remote machine.
# For example, ssh -n shadows.cs.hut.fi emacs & will start an emacs on shadows.cs.hut.fi, and the X11 connection will be automatically forwarded over an encrypted channel. The ssh program will be put in the background. (This does not work if ssh needs to ask for a password or passphrase; see also the -f option.)
#
################
# How to Port-Forward Jupyter Notebooks – Scott Hawley – Development Blog
# https://drscotthawley.github.io/How-To-Port-Forward-Jupyter-Notebooks/
#
# The server we’ll call “doorkeeper” is visible to the outside world, and so we forward its port 8889 to the one over on “internal” where the notebook is running:
# me@doorkeeper:~$ ssh -N -n -L 127.0.0.1:8889:127.0.0.1:8889 internal
#
# Then on my laptop, I run a similar port-forward so the browser will connected to the port on doorkeeper:
# me@laptop:~$ ssh -N -n -L 127.0.0.1:8889:127.0.0.1:8889 doorkeeper
#
################
# matplotlib - Can one remotely access an IPython Notebook without using inline plotting? - Stack Overflow
# https://stackoverflow.com/questions/11462621/can-one-remotely-access-an-ipython-notebook-without-using-inline-plotting
#
# Note that I've forwarded port 8889 - this means I use http://localhost:8889/ in a browser on my at-home machine.
# For me, this works nicely with the Qt4Agg backend.
#
ssh -X -t $FORWARD_TO_LOCAL $USER@$ADDR -p $SSH_PORT "XAUTH_DIR=/tmp/.docker.xauth; XAUTH=\$XAUTH_DIR/.xauth; touch \$XAUTH; echo \$XAUTH;echo \$DISPLAY; xauth nlist \$DISPLAY | sed -e 's/^..../ffff/' | xauth -f \$XAUTH nmerge -;bash"
