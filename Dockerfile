FROM adoptopenjdk:11.0.3_7-jre-hotspot

ARG HADOOP_VERSION=3.3.0
ARG HDFS_PORT=9000
ARG HADOOP_USERNAME=hadoop

EXPOSE $HDFS_PORT
EXPOSE 9870
EXPOSE 8088

ADD https://downloads.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz /usr/local
COPY scripts/hadoop-startup /usr/sbin/

WORKDIR /usr/local

RUN apt-get update && apt-get install -y ssh pdsh sudo \
	#nano mc net-tools \
	&& rm -rf /var/lib/apt/lists/*

# Setting up hadoop user
RUN useradd -m -s /bin/bash -U ${HADOOP_USERNAME} \
	&& mkdir /home/${HADOOP_USERNAME}/.ssh \
	&& ssh-keygen -t ed25519 -C "hadoop" -f /home/${HADOOP_USERNAME}/.ssh/id_ed25519 -q -N "" \
	&& cat /home/${HADOOP_USERNAME}/.ssh/id_ed25519.pub >> /home/${HADOOP_USERNAME}/.ssh/authorized_keys \
	&& chmod 0600 /home/${HADOOP_USERNAME}/.ssh/authorized_keys \
	&& echo "export JAVA_HOME=/opt/java/openjdk" >> /home/${HADOOP_USERNAME}/.bashrc \
	&& echo "export HADOOP_CONF_DIR=/etc/hadoop" >> /home/${HADOOP_USERNAME}/.bashrc \
	&& echo "export HADOOP_COMMON_HOME=/usr/local/hadoop" >> /home/${HADOOP_USERNAME}/.bashrc \
	&& echo "export HADOOP_HDFS_HOME=$HADOOP_COMMON_HOME" >> /home/${HADOOP_USERNAME}/.bashrc \
	&& echo "export HADOOP_YARN_HOME=$HADOOP_COMMON_HOME" >> /home/${HADOOP_USERNAME}/.bashrc \
	&& echo "export HADOOP_MAPRED_HOME=$HADOOP_COMMON_HOME" >> /home/${HADOOP_USERNAME}/.bashrc \
	&& echo "export HADOOP_LOG_DIR=/var/log/hadoop" >> /home/${HADOOP_USERNAME}/.bashrc \
	&& echo "export $PATHHADOOP_COMMON_HOME=/usr/local/hadoop" >> /home/${HADOOP_USERNAME}/.bashrc \
	&& chown -R ${HADOOP_USERNAME}:${HADOOP_USERNAME} /home/${HADOOP_USERNAME}/ \
# Creating lins to /usr/bin
	&& ln -s /usr/local/hadoop-${HADOOP_VERSION} /usr/local/hadoop \
	&& ln -s /usr/local/hadoop/bin/yarn /usr/bin/ \
	&& ln -s /usr/local/hadoop/bin/test-container-executor /usr/bin/ \
	&& ln -s /usr/local/hadoop/bin/oom-listener /usr/bin/ \
	&& ln -s /usr/local/hadoop/bin/mapred /usr/bin/ \
	&& ln -s /usr/local/hadoop/bin/hdfs /usr/bin/ \
	&& ln -s /usr/local/hadoop/bin/hadoop /usr/bin/ \
	&& ln -s /usr/local/hadoop/bin/container-executor /usr/bin/ \
	&& ln -s /usr/local/hadoop/libexec /usr/ \
	&& ln -s /usr/local/hadoop/include /usr/include/hadoop \
	&& ln -s /usr/local/hadoop/sbin/distribute-exclude.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/hadoop-daemon.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/hadoop-daemons.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/httpfs.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/kms.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/mr-jobhistory-daemon.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/refresh-namenodes.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/start-all.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/start-balancer.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/start-dfs.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/start-secure-dns.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/start-yarn.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/stop-all.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/stop-balancer.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/stop-dfs.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/stop-secure-dns.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/stop-yarn.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/workers.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/yarn-daemon.sh /usr/sbin/ \
	&& ln -s /usr/local/hadoop/sbin/yarn-daemons.sh /usr/sbin/ \
	&& chmod +x /usr/sbin/hadoop-startup \
# Setting up pdsh
	&& echo "ssh" > /etc/pdsh/rcmd_default \
# Moving configuration files to /etc.
	&& ln -s /usr/local/hadoop/etc/hadoop /etc/ \
	&& chown root:${HADOOP_USERNAME} /etc/hadoop \
	&& chmod g+s /etc/hadoop/ \
# Configuring hadoop.
	&& sed -i "s/# export JAVA_HOME=/export JAVA_HOME=\/opt\/java\/openjdk/g" /etc/hadoop/hadoop-env.sh \
	&& sed -i "s/# export HADOOP_HOME=/export HADOOP_HOME=\/usr\/local\/hadoop/g" /etc/hadoop/hadoop-env.sh \
	&& sed -i "s/# export HADOOP_CONF_DIR=\${HADOOP_HOME}\/etc\/hadoop/export HADOOP_CONF_DIR=\/etc\/hadoop/g" /etc/hadoop/hadoop-env.sh \
	&& sed -i "s/# export HADOOP_LOG_DIR=\${HADOOP_HOME}\/logs/export HADOOP_LOG_DIR=\/var\/log\/hadoop/g" /etc/hadoop/hadoop-env.sh \
	&& sed -i "/^<\/configuration>.*/i \
	<property>\n\
		<name>fs.defaultFS</name>\n\
		<value>hdfs://localhost:${HDFS_PORT}</value>\n\
	</property>\n\
	<property>\n\
		<name>hadoop.tmp.dir</name>\n\
		<value>/var/hadoop</value>\n\
	</property>\n" /etc/hadoop/core-site.xml \
	&& sed -i "/^<\/configuration>.*/i \
	<property>\n\
		<name>dfs.replication</name>\n\
		<value>1</value>\n\
	</property>\n" /etc/hadoop/hdfs-site.xml \
# Configuring YARN on a Single Node
	&& sed -i "/^<\/configuration>.*/i \
	<property>\n\
		<name>mapreduce.framework.name</name>\n\
		<value>yarn</value>\n\
	</property>\n\
		<property>\n\
		<name>mapreduce.application.classpath</name>\n\
		<value>\$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:\$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>\n\
	</property>\n" /etc/hadoop/mapred-site.xml \
	&& sed -i "/^<\/configuration>.*/i \
		<property>\n\
		<name>yarn.nodemanager.aux-services</name>\n\
		<value>mapreduce_shuffle</value>\n\
	</property>\n\
	<property>\n\
		<name>yarn.nodemanager.env-whitelist</name>\n\
		<value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>\n\
	</property>\n" /etc/hadoop/yarn-site.xml \
# Creating log dir.
	&& mkdir -p /var/log/hadoop \
	&& chown -R ${HADOOP_USERNAME}:${HADOOP_USERNAME} /var/log/hadoop/ \
	&& chmod g+s /var/log/hadoop/ \
# Creating data directory.
	&& mkdir -p /var/hadoop \
	&& chown -R ${HADOOP_USERNAME}:${HADOOP_USERNAME} /var/hadoop/ \
	&& chmod g+s /var/hadoop/ \
# Disabling IPv6
	&&  echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf \
	&&  echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf

CMD [ "hadoop-startup" ]
