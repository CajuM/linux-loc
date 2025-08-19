#include "common.h"

int get_eventloop(struct pollfd *fds, struct sock_event *sevs, size_t n_sockets, struct sockaddr_in *local_addr, struct sockaddr_in *remote_addr)
{
	size_t idx;
	int sockfd;
	int flags;

	for (idx = 0; idx < n_sockets; idx++) {
		sockfd = socket(AF_INET, SOCK_STREAM, 0);
		die(sockfd >= 0);

		die(bind(sockfd, (struct sockaddr *) local_addr, sizeof(struct sockaddr_in)) >= 0);

		fds[idx].fd = sockfd;
		sevs[idx].data = 0;

		if (remote_addr == NULL) {
			fds[idx].events = POLLIN;
			sevs[idx].sock_type = LISTENING;

			die(listen(sockfd, 1024) >= 0);
		} else {
			fds[idx].events = POLLOUT;
			sevs[idx].sock_type = ESTABLISHED;

			die(connect(sockfd, (struct sockaddr *) remote_addr, sizeof(struct sockaddr_in)) >= 0);
		}

		flags = fcntl(sockfd, F_GETFL, 0);
		fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);
	}

	return n_sockets;
}

void setup_iface(char *bind_iface, char *bind_ip_str)
{
	struct in_addr bind_ip;

	int ifr_fd;
	struct ifreq ifr;
	struct ethtool_value eval;
	struct sockaddr_in sin;

	int r;
	int fd;

	die(inet_aton(bind_ip_str, &bind_ip) != 0);

	ifr_fd = socket(AF_INET, SOCK_DGRAM, 0);
	die(ifr_fd >= 0);

	strncpy(ifr.ifr_name, bind_iface, IFNAMSIZ);

	ifr.ifr_data = (void *) &eval;

	eval.cmd = ETHTOOL_SGSO;
	eval.data = 0;
	r = ioctl(ifr_fd, SIOCETHTOOL, &ifr);
	if (r < 0) {
		r = errno;
		die(r == EOPNOTSUPP);
	}

	eval.cmd = ETHTOOL_SGRO;
	eval.data = 0;
	r = ioctl(ifr_fd, SIOCETHTOOL, &ifr);
	if (r < 0) {
		r = errno;
		die(r == EOPNOTSUPP);
	}

	ifr.ifr_data = NULL;

	memset(&sin, 0, sizeof(struct sockaddr_in));
	sin.sin_family = AF_INET;

	sin.sin_addr = bind_ip;
	memcpy(&ifr.ifr_addr, &sin, sizeof(struct sockaddr_in));
	die(ioctl(ifr_fd, SIOCSIFADDR, &ifr) >= 0);

	die(ioctl(ifr_fd, SIOCGIFFLAGS, &ifr) >= 0);
	ifr.ifr_flags |= IFF_UP | IFF_RUNNING;
	die(ioctl(ifr_fd, SIOCSIFFLAGS, &ifr) >= 0);

	ifr.ifr_mtu = IFACE_MTU;
	die(ioctl(ifr_fd, SIOCSIFMTU, &ifr) >= 0);

	die(mount("proc", "/proc", "proc", 0, NULL) >= 0);
	die(mount("sys", "/sys", "sysfs", 0, NULL) >= 0);

	fd = open("/proc/sys/net/core/rmem_max", O_RDWR);
	die(fd >= 0);
	die(write(fd, XMEM_MAX, strlen(XMEM_MAX)) > 0);
	close(fd);

	fd = open("/proc/sys/net/core/wmem_max", O_RDWR);
	die(fd >= 0);
	die(write(fd, XMEM_MAX, strlen(XMEM_MAX)) > 0);
	close(fd);

	fd = open("/proc/sys/net/ipv4/tcp_rmem", O_RDWR);
	die(fd >= 0);
	die(write(fd, TCP_XMEM, strlen(TCP_XMEM)) > 0);
	close(fd);

	fd = open("/proc/sys/net/ipv4/tcp_wmem", O_RDWR);
	die(fd >= 0);
	die(write(fd, TCP_XMEM, strlen(TCP_XMEM)) > 0);
	close(fd);

	fd = open("/proc/sys/net/ipv4/tcp_adv_win_scale", O_RDWR);
	die(fd >= 0);
	die(write(fd, TCP_ADV_WIN_SCALE, strlen(TCP_ADV_WIN_SCALE)) > 0);
	close(fd);
}
