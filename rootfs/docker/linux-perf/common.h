#include <assert.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <errno.h>
#include <fcntl.h>
#include <getopt.h>
#include <poll.h>
#include <unistd.h>

#include <arpa/inet.h>

#include <linux/sockios.h>

#include <net/if.h>

#include <netinet/ether.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

#include <sys/ioctl.h>
#include <sys/mount.h>
#include <sys/socket.h>
#include <sys/time.h>

#define ETHTOOL_SGSO 0x00000024
#define ETHTOOL_SGRO 0x0000002c

#define XMEM_MAX "2147483647"
#define TCP_XMEM "4096 87380 2147483647"
#define TCP_ADV_WIN_SCALE "1"

#define MAX_LISTENING_EVENTS 1024
#define BUF_LEN (1 << 27)

#define PERF_PORT 4112
#define PERF_CONNECTIONS 1

#define MY_IFACE "eth0"
#define TX_IP "10.1.1.1"
#define RX_IP "10.1.1.2"
#define IFACE_MTU 96

#define die(cond) if (!(cond)) do { fprintf(stderr, "%s: %s\n", __PRETTY_FUNCTION__, (#cond)); exit(-1); } while(false)

struct sock_event {
	int fd;
	enum {
		ESTABLISHED,
		LISTENING
	} sock_type;
	uint64_t data;
};

struct ethtool_value {
	unsigned cmd;
	unsigned data;
};


int get_eventloop(struct pollfd *fds, struct sock_event *sevs, size_t n_sockets, struct sockaddr_in *local_addr, struct sockaddr_in *remote_addr);

void setup_iface(char *bind_iface, char *bind_ip_str);
