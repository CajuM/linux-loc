#include "common.h"

#define US_IN_S 1000000UL

static bool running = true;

int main(int argc, char **argv)
{
	struct sockaddr_in local_addr;

	struct pollfd *fds;
	struct sock_event *sevs;

	int n_events;

	void *buf;

	struct timeval before;
	struct timeval now;

	unsigned long long prev_rx_packets;

	setup_iface(MY_IFACE, RX_IP);

	local_addr.sin_family = AF_INET;
	local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	local_addr.sin_port = htons(PERF_PORT);

	fds = malloc(sizeof(struct pollfd));
	sevs = malloc(sizeof(struct sock_event));

	n_events = get_eventloop(fds, sevs, 1, &local_addr, NULL);
	buf = malloc(BUF_LEN);

	printf("Started\n");
	fflush(stdout);

	prev_rx_packets = 0;

	while (running) {
		size_t idx;
		uint64_t delta;
		int r;

		r = poll(fds, n_events, -1);
		if (r <= 0)
			continue;

		for (idx = 0; idx < n_events; idx++) {
			if ((fds[idx].revents & POLLIN) && (sevs[idx].sock_type == LISTENING)) {
				int asockfd = accept(fds[idx].fd, NULL, NULL);

				int flags = fcntl(asockfd, F_GETFL, 0);
				fcntl(asockfd, F_SETFL, flags | O_NONBLOCK);

				n_events++;
				sevs = realloc(sevs, n_events * sizeof(struct sock_event));
				fds = realloc(fds, n_events * sizeof(struct pollfd));

				fds[n_events - 1].fd = asockfd;
				fds[n_events - 1].events = POLLIN;

				sevs[n_events - 1].sock_type = ESTABLISHED;
				sevs[n_events - 1].data = 0;
			}

			if (fds[idx].revents & POLLHUP) {
				close(fds[idx].fd);

				perror("Connection closed");
				return -1;
			}

			if ((fds[idx].revents & POLLIN) && (sevs[idx].sock_type == ESTABLISHED)) {
				(void)read(fds[idx].fd, buf, BUF_LEN);
			}
		}

		gettimeofday(&now, NULL);

		delta = (now.tv_sec - before.tv_sec) * US_IN_S + (now.tv_usec - before.tv_usec);
		if (delta >= US_IN_S) {
			unsigned long long rx_packets;
			FILE * rx_packets_f;

			rx_packets_f = fopen("/sys/class/net/eth0/statistics/rx_packets", "rt");
			die(rx_packets_f != NULL);

			fscanf(rx_packets_f, "%llu\n", &rx_packets);
			printf("pps=%llu;\n", (rx_packets - prev_rx_packets) * US_IN_S / delta);

			prev_rx_packets = rx_packets;
			before = now;
			fclose(rx_packets_f);
		}
	}

	return 0;
}
