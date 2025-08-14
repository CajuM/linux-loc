#include "common.h"

static bool running = true;

int main(int argc, char **argv)
{
	struct pollfd *fds;
	struct sock_event *sevs;

	int n_events;

	struct sockaddr_in local_addr;
	struct sockaddr_in remote_addr;

	void *buf;

	setup_iface(MY_IFACE, TX_IP);

	local_addr.sin_family = AF_INET;
	local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	local_addr.sin_port = htons(0);

	remote_addr.sin_family = AF_INET;
	die(inet_aton(RX_IP, &remote_addr.sin_addr) != 0);
	remote_addr.sin_port = htons(PERF_PORT);

	fds = malloc(PERF_CONNECTIONS * sizeof(struct pollfd));
	sevs = malloc(PERF_CONNECTIONS * sizeof(struct sock_event));

	n_events = get_eventloop(fds, sevs, PERF_CONNECTIONS, &local_addr, &remote_addr);
	buf = malloc(BUF_LEN);

	printf("Started\n");
	fflush(stdout);

	while (running) {
		size_t idx;
		int r;

		r = poll(fds, PERF_CONNECTIONS, -1);
		if (r <= 0)
			continue;

		for (idx = 0; idx < n_events; idx++) {
			if (fds[idx].revents & POLLHUP) {
				close(fds[idx].fd);

				fprintf(stderr, "Connection closed");
				return -1;
			}

			if (fds[idx].revents & POLLOUT) {
				r = write(fds[idx].fd, buf, BUF_LEN);

				if (r < 0) {
					r = errno;
					die((r == EAGAIN) || (r == ENOSPC));
				}
			}
		}
	}

	return 0;
}
