# https://docs.docker.com/engine/reference/builder/#arg
# @remark Please never modify it, the auto/release.sh will update it automatically.
ARG tag=v4.0.39
ARG url=https://gitee.com/winlinvip/srs.oschina.git

############################################################
# build
############################################################
ARG repo=registry.cn-hangzhou.aliyuncs.com/ossrs/srs:dev
FROM ${repo} AS build
ARG tag
ARG url
# Install required tools.
RUN yum install -y gcc make gcc-c++ patch unzip perl git
RUN cd /tmp && git clone --depth=1 --branch ${tag} ${url} srs
RUN cd /tmp/srs/trunk && ./configure --gb28181=on && make && make install
# All config files for SRS.
COPY conf /usr/local/srs/conf
# The default index.html and srs-console.
COPY index.html /usr/local/srs/objs/nginx/html/index.html
COPY srs-ngb/trunk/research/srs-console /usr/local/srs/objs/nginx/html/console
COPY srs-ngb/trunk/src/3rdparty /usr/local/srs/objs/nginx/html/console/js/3rdparty
COPY srs-ngb/trunk/src/bravo_alert /usr/local/srs/objs/nginx/html/console/js/bravo_alert
COPY srs-ngb/trunk/src/bravo_popover /usr/local/srs/objs/nginx/html/console/js/bravo_popover

############################################################
# dist
############################################################
FROM centos:7 AS dist
# RTMP/1935, API/1985, HTTP/8080, SIP/5060, RTP/9000
EXPOSE 1935 1985 8080 5060/udp 9000/udp
# FFMPEG 4.1
COPY --from=build /usr/local/bin/ffmpeg /usr/local/srs/objs/ffmpeg/bin/ffmpeg
# SRS binary, config files and srs-console.
COPY --from=build /usr/local/srs /usr/local/srs
# Default workdir and command.
WORKDIR /usr/local/srs
CMD ["./objs/srs", "-c", "conf/push.gb28181.conf"]
