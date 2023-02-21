# syslog-replay
This repository is a combination Dockerfile and example docker-compose.yml file that demonstrates replaying the syslog UDP stream from a previously captured pcap file to an adjacent running Docker container.

This allows for a "live" syslog datastream that plays out over time, and is primarily useful in building custom demos, workshops, proving concepts, etc.

Why do this? When provisioning a demo environment with docker-compose, you won't know the IP address of any of the running containers ahead of time, and it's nice to have a something *automatically* start sending data over the wire when it starts up.

The `rewrite_pcap.sh` startup script does the heavy lifting:

* Determines the private IP of an adjacent running Docker container and rewrites the destination IP and destination MAC of an arbitrary host in the pcap.  This is determined by the `hostname` field for this host in `docker-compose.yml`  

    * Note: this is strictly for delivering the packets (altering headers) and does NOT change the syslog content (altering payload).

* It then uses tcpreplay to replay the edited pcap on a loop.  It's kind of a parlor trick that won't work with syslog over TCP.

The `docker-compose.yml` file included as an example is from [docs.cribl.io](https://docs.cribl.io/stream/deploy-docker) and uses a Cribl Worker node as a syslog receiver.

The included `syslog.pcap` file originally used 192.168.1.107:5140 as the UDP syslog listener.  When using your own pcap, adjust the `rewrite_pcap.sh` script accordingly.

## Example Usage
```git clone https://github.com/berthayes/syslog-replay && cd syslog-replay```

```docker build -t syslog-replay .```

```docker-compose up -d```

When using the included example pcap, configure your Cribl worker to listen on UDP 5140 for syslog.  Events will flow like tap water, not a firehose.

## Using your own pcap file
Ideally, capture packets on the listening interface of your syslog server.  
* Note that the `rewrite_pcap.sh` script does NOT change the destination port of syslog packets in the saved pcap.

```sudo tcpdump -s0 udp and port 5140 -w syslog.pcap```