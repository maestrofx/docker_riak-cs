FROM ubuntu

run locale-gen en_US.UTF-8
run update-locale LANG=en_US.UTF-8
env DEBIAN_FRONTEND noninteractive
env LC_ALL C
env LC_ALL en_US.UTF-8

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN apt-get update
RUN apt-get clean

# Install sshd & Supervisor
RUN apt-get install -y openssh-server supervisor
RUN mkdir -p /var/run/sshd
RUN chmod 744 /var/run/sshd
RUN mkdir -p /var/log/supervisor

# Install required packages to install riak
RUN apt-get install -y curl logrotate lsb-release

# Add basho apt distribution site
RUN curl http://apt.basho.com/gpg/basho.apt.key | sudo apt-key add -
RUN echo "deb http://apt.basho.com $(lsb_release -sc) main" > /etc/apt/sources.list.d/basho.list
RUN apt-get update

# Install riak, riak-cs, riak-cs-control and stanchion
RUN apt-get -y install riak riak-cs riak-cs-control stanchion

RUN sed -i.bak 's/127.0.0.1/0.0.0.0/' /etc/riak/app.config
RUN sed -i.bak 's/127.0.0.1/0.0.0.0/' /etc/stanchion/app.config
RUN sed -i.bak -e 's/127.0.0.1/0.0.0.0/' -e 's/anonymous_user_creation, false/anonymous_user_creation, true/' /etc/riak-cs/app.config
RUN echo "ulimit -n 4096" >> /etc/default/riak
#RUN dpkg-divert --local --rename --add /sbin/initctl
#RUN ln -s /bin/true /sbin/initctl

# Add app.config
ADD app.config /etc/riak/app.config

# Add supervisor's configuration file
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

ADD id_rsa.pub /tmp/id_rsa.pub
RUN mkdir /root/.ssh
RUN chmod 700 /root/.ssh
RUN cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys
RUN rm /tmp/id_rsa.pub
RUN chown -R root /root/.ssh

EXPOSE 22 8080 9001

CMD ["/usr/bin/supervisord"]
