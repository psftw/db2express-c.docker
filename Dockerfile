#
#  Build docker image of db2 express-C v10.5 FP5 (64bit)
#
# # Authors:
#   * Leo (Zhong Yu) Wu       <leow@ca.ibm.com>
#
# Copyright 2015, IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM centos:7

MAINTAINER Leo Wu <leow@ca.ibm.com>

RUN groupadd db2iadm1 && useradd -G db2iadm1 db2inst1

RUN yum install -y \
    libaio \
    libstdc++.i686 \
    pam.i686 \
    passwd \
    && yum clean all

# TODO do we actually need any of these?
#    sudo \
#    sg3_utils \
#    dapl \
#    numactl \
#    numactl.i686 \
#    libibverbs-devel \
#    dapl-devel \
#    rsyslog \
#    compat-libstdc++-33 \
#    libstdc++-devel \
#    libstdc++-devel.i686 \
#    libaio.i686 \
#    ncurses-libs.i686 \
#    pam \
#    initscripts \
#    system-config-language \ -- this one brings in lots of X11 stuff
#    kernel-devel && \
#    e2fsprogs \
#    gcc-c++ \

ENV DB2EXPRESSC_SHA256 a5c9a3231054047f1f63e7144e4da49c4feaca25d8fce4ad97539d72abfc93d0
ENV DB2EXPRESSC_URL https://s3.amazonaws.com/db2-expc105-64bit-centos/v10.5fp5_linuxx64_expc.tar.gz
#ENV DB2EXRPESSC_URL http://192.168.1.70/v10.5fp5_linuxx64_expc.tar.gz
RUN curl -fSLo /tmp/expc.tar.gz $DB2EXPRESSC_URL \
    && echo "$DB2EXPRESSC_SHA256 /tmp/expc.tar.gz" | sha256sum -c - \
    && cd /tmp && tar xf expc.tar.gz \
    && su - db2inst1 -c "/tmp/expc/db2_install -b /home/db2inst1/sqllib" \
    && su - db2inst1 -c "cat /home/db2inst1/sqllib/db2profile >> /home/db2inst1/.bash_profile" \
    && sed -ri 's/ENABLE_OS_AUTHENTICATION=NO/ENABLE_OS_AUTHENTICATION=YES/g' /home/db2inst1/sqllib/instance/db2rfe.cfg \
    && sed -ri 's/RESERVE_REMOTE_CONNECTION=NO/RESERVE_REMOTE_CONNECTION=YES/g' /home/db2inst1/sqllib/instance/db2rfe.cfg \
    && sed -ri 's/\*SVCENAME=db2c_db2inst1/SVCENAME=db2c_db2inst1/g' /home/db2inst1/sqllib/instance/db2rfe.cfg \
    && sed -ri 's/\*SVCEPORT=48000/SVCEPORT=50000/g' /home/db2inst1/sqllib/instance/db2rfe.cfg \
    && su - db2inst1 -c "db2set DB2COMM=TCPIP && db2stop force" \
    && cd /home/db2inst1/sqllib/instance && ./db2rfe -f ./db2rfe.cfg \
    && rm -rf /tmp

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

VOLUME /home/db2inst1
EXPOSE 50000
