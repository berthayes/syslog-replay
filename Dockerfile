FROM debian:stable-slim

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y  python3 libpcap-dev libssl-dev python3-dev libpython3-dev swig zlib1g-dev git tcpreplay clang net-tools iproute2 softflowd curl wget vim-common tcpdump jq bind9-dnsutils inetutils-ping

COPY rewrite_pcap.sh /rewrite_pcap.sh
RUN chmod +x /rewrite_pcap.sh
ENTRYPOINT ["/rewrite_pcap.sh"]
