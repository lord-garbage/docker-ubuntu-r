docker-ubuntu-r
===============

Ubuntu image intended for dockerized R development.

### Some properties

* Sets up `user` (with sudo rights) so that the container does not need to
  run as root.
* Sets up `/home` for `user` and some basic options in `.Rprofile` and
  `.bashrc` which should be changed to your own needs.
* Installs all recommended `R` dependencies, pulls `R-devel` from `SVN` and
  compiles `R-devel` from source.

There is a nice and semi-easy way of getting graphical output from a
Docker container without having to run an sshd daemon inside of the
container. Docker can provide bare metal performance when running a single
process which in this case is supposed to be R. Running an sshd daemon
will, marginal as it may be, introduce additional overhead. This is not
made better by running the sshd daemon as a child process of the
supervisor daemon. Both can be dispensed with when one makes good use of
bind mounts. After building the image from which the container is supposed
to be run we start an interactive container and bind mount the
`/tmp/.X11-unix` folder into it. I will state the complete command and
explain in detail what it does:

```
docker run -i -t --rm \
# -i sets up an interactive session; -t allocates a pseudo tty; --rm makes
# this container ephemeral
-e DISPLAY=$DISPLAY \
# sets the host display to the local machines display (which will usually
# be :0)
-u chbr \
# -u specify the process should be run by a user (here "chbr") and not by
# root. This step is important (v.i.)!
-v /tmp/.X11-unix:/tmp/.X11-unix \
# - v bind mounts the `X11` socket `/tmp/.X11-unix` into `/tmp/.X11-unix`
# in the container.
--name="rdev" ubuntu-r1 R
# --name="" specify the name of the container (here "rdev"); the image you
# want to run the container from (here "ubuntu-r"); the process you want
# to run in the container (here "R").
```

After issuing this command you should be looking at the beautiful `R`
start output. If you were to try `demo(graphics)` to see if graphical
output is already working you would note that it is not. That is because
of the `Xsecurity` extension preventing you from accessing the socket. You
could now type `xhost +` on your local machine and try `demo(graphics)` in
your container again. You should now have graphical output. This method
however, is strongly discouraged as you allow access to your xsocket to
any remote host you're currently connected to. As long as you're only
interacting with single-user systems this might be somehow justifiable but
as soon as there are multiple users involved this will be absolutely
unsafe! Hence, you should use a less dangerous method. A good way is to
use the server interpreted `xhost +si:localuser:username` which can be
used to specify a single local user (see `man xhost`). This means
`username` should be the name of the user which runs the `X11` server on
your local machine and which runs the `Docker` container. This is also the
reason why it is important that you specify a user when running your
container. Last but not least there is always the more complex solution of
using `xauth` and `.Xauthority` files to grant access to the `X11` socket
(see `man xauth`). This however will also involve a little more knowledge
how `X` works.




























* Runs `ssh` daemon inside (mainly for `X11`-forwarding)

### Small how-to-`ssh`-into-docker-container

1. Build docker image from `Dockerfile`.
   * `sudo docker build -t ubuntu-r Dockerfile`.
   
   The parameter `-t` allows to specify the name of the resulting image.
   In this case `ubuntu-r`.

2. Run container from image as daemon.
   * `docker run -d -P --name="ssd" ubuntu-r`
   
   The parameter `-d` makes the resulting container run as a daemon;
   parameter `-P` publishes all exposed ports to the host system; `--name`
   allows to specify a name for the resulting container and is followed by
   the name of the image from which it will be created (`--name` in our
   case is `ssd` and the image it is run from is `ubuntu-r` which we just
   created before).

3. Find `ip` and `port` of container. One option is to use
   * `docker inspect ssd`.

   It will give you all low-level information about your container
   including `ip` and the `port` to which the standard port `22` is mapped
   on the host. (This is done so that you can have multiple containers
   running each with a different port.)

4. Actually `ssh` into your container as `user` (`root`-login is not
   allowed!).
   * `ssh -X yourusername@ip-adress-you-found-out -p
   port-number-you-found-out`

   e. g.

   * `ssh -X chbr@172.17.0.80 -p 49154`.

   The `-X` flag sets up `X11`-forwarding (So that you can see plots and
   pdfs and so on.). If the port `22` is mapped to another port but the
   connection is refused on that port. Try the default port `22`. Hence,
   try `ssh -X chbr@172.17.0.80` without specifying the `-p` parameter.

### Avoiding the dynamic-ip-problem.

1. What is the dynamic-ip-problem?

   Docker assigns a dynamic ip to every container which can change with
   every login, startup etc. Hence, you would need to run `docker inspect
   inser-your-container-name-here` on every one of your container. This is
   bad!
   
2. I can think of one possible solution. Build the image as explained
   under 1. in `Small how-to-ssh-into-docker-container`. But then start up
   the container with

   * `docker run -d -p 127.0.0.1:5000:22 -P --name="ssd" ubuntu-r`
   
   The `-p` parameter allows to publish a specific port of the `container`
   to a port of the `host`. In our case we publish the containers port
   `22` to the hosts port `5000`. This setting will persist if you stop
   and start or restart your container.

3. You can then use

   * `ssh -X yourusername@localhost -p 5000`

   to `ssh` into your container or create an alias for this command in
   your `.bashrc` file on the `host` or follow the solution outlined in
   the following.

4. Edit `/etc/ssh/ssh_config` on the host by including:

   ```
   Host ssd
   HostName localhost
   Port 5000
   User yourusername
   ForwardX11 yes
   ForwardX11Trusted yes
   RhostsRSAAuthentication yes
   RSAAuthentication no
   ControlMaster auto
   ControlPersist yes
   ControlPath ~/.ssh/socket-%r@%h:%p
   ```

   Once this is done you can use

   * `ssh ssd`
   
   to `ssh` into your container.


