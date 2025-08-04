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

	setup_iface(MY_IFACE, RX_IP);

	local_addr.sin_family = AF_INET;
	local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	local_addr.sin_port = htons(PERF_PORT);

	n_events = get_eventloop(&fds, &sevs, 0, &local_addr, NULL);
	buf = malloc(BUF_LEN);

	printf("Started\n");
	fflush(stdout);

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
				int r = read(fds[idx].fd, buf, BUF_LEN);
				if (r > 0)
					sevs[idx].data += r;
			}
		}

		gettimeofday(&now, NULL);

		delta = (now.tv_sec - before.tv_sec) * US_IN_S + (now.tv_usec - before.tv_usec);
		if (delta >= US_IN_S) {
			uint64_t data = 0;
			for (idx = 1; idx < n_events; idx++) {
				data += sevs[idx].data;
				sevs[idx].data = 0;
			}

			data = data * 8 * US_IN_S / delta;
			printf("bps=%llu; connections=%u;\n", data, n_events - 1);
			fflush(stdout);
			before = now;
		}
	}

	return 0;
}
