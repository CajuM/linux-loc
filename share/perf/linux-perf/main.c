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

#include <netinet/ether.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

#include <sys/socket.h>
#include <sys/time.h>

#define MAX_LISTENING_EVENTS 1024
#define US_IN_S 1000000UL
#define BUF_LEN (1 << 27)

static bool running = true;
struct sock_event {
	int fd;
	enum {
		ESTABLISHED,
		LISTENING
	} sock_type;
	uint64_t data;
};

#define die(cond) if (!(cond)) do { printf("%s: %s\n", __PRETTY_FUNCTION__, (#cond)); exit(-1); } while(false)


int get_eventloop(struct pollfd **fds, struct sock_event **sevs, size_t n_sockets, struct sockaddr_in *local_addr, struct sockaddr_in *remote_addr)
{
	size_t idx;
	int sockfd;
	int flags;

	if (remote_addr == NULL)
		n_sockets = 1;

	*fds = malloc(n_sockets * sizeof(struct pollfd));
	*sevs = malloc(n_sockets * sizeof(struct sock_event));

	for (idx = 0; idx < n_sockets; idx++) {
		sockfd = socket(AF_INET, SOCK_STREAM, 0);
		die(sockfd >= 0);

		flags = fcntl(sockfd, F_GETFL, 0);
		fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);

		die(bind(sockfd, (struct sockaddr *) local_addr, sizeof(struct sockaddr_in)) >= 0);

		(*fds)[idx].fd = sockfd;
		(*sevs)[idx].data = 0;

		if (remote_addr == NULL) {
			(*fds)[idx].events = POLLIN;
			(*sevs)[idx].sock_type = LISTENING;

			die(listen(sockfd, 1024) >= 0);
		} else {
			(*fds)[idx].events = POLLOUT;
			(*sevs)[idx].sock_type = ESTABLISHED;


			if ((connect(sockfd, (struct sockaddr *) remote_addr, sizeof(struct sockaddr_in)) < 0) && (errno != EINPROGRESS))
				die(false);
		}
	}

	return n_sockets;
}

int main(int argc, char **argv)
{
	static struct option long_options[] = {
		{ "listen", no_argument, 0,  0 },
		{ "connect-ip", required_argument, 0,  0 },
		{ "bind-port", required_argument, 0,  0 },
		{ "connect-port", required_argument, 0,  0 },
		{ "timeout", required_argument, 0, 0 },
		{ "connections", required_argument, 0, 0 },
		{ NULL, 0, 0, 0 }
	};

	char opt;
	int option_index;

	uint16_t bind_port = 0;

	bool listening = false;

	bool connecting = false;
	struct in_addr connect_ip;
	uint16_t connect_port = 0;

	uint64_t timeout = 0;
	uint64_t connections = 0;

	struct sockaddr_in local_addr;
	struct timeval timeout_tv;

	struct pollfd *fds;
	struct sock_event *sevs;

	int n_events;

	struct sockaddr_in remote_addr;

	void *buf;

	struct timeval before;
	struct timeval now;

	while ((opt = getopt_long(argc, argv, "", long_options, &option_index)) != -1) {
		die(opt == 0);

		switch (option_index) {
			case 0:
				listening = true;
				break;

			case 1:
				die(inet_aton(optarg, &connect_ip) != 0);
				connecting = true;
				break;

			case 2:
				bind_port = atoi(optarg);
				break;

			case 3:
				connect_port = atoi(optarg);
				break;

			case 4:
				timeout = atoi(optarg);
				break;

			case 5:
				connections = atoi(optarg);
				die(connections > 0);
				break;

			default:
				die(false);
				break;
		}
	}

	die(listening ^ connecting);
	die((timeout && connecting) || !timeout);
	die(!(connections && !connecting));
	die(!(bind_port && !listening));
	die(!(connecting && !connect_port));

	local_addr.sin_family = AF_INET;
	local_addr.sin_addr.s_addr = htonl(INADDR_ANY);

	if (connecting) {
		local_addr.sin_port = 0;
		
		remote_addr.sin_family = AF_INET;
		remote_addr.sin_addr = connect_ip;
		remote_addr.sin_port = htons(connect_port);

		n_events = get_eventloop(&fds, &sevs, connections, &local_addr, &remote_addr);

		buf = malloc(BUF_LEN);

		gettimeofday(&timeout_tv, NULL);

		while (running) {
			size_t idx;
			int r;

			r = poll(fds, connections, -1);
			if (r <= 0)
				continue;

			for (idx = 0; idx < n_events; idx++) {
				if (fds[idx].revents & POLLHUP) {
					close(fds[idx].fd);

					perror("Connection closed");
					return -1;
				}

				if (fds[idx].revents & POLLOUT) {
					int r = write(fds[idx].fd, buf, BUF_LEN);
					if ((r < 0) && ((errno != EAGAIN) || (errno != ENOSPC)))
						perror("write");
				}
			}

			if (timeout) {
				gettimeofday(&now, NULL);

				if ((now.tv_sec - timeout_tv.tv_sec) >= timeout)
					break;
			}
		}
	} else {
		local_addr.sin_port = htons(bind_port);

		n_events = get_eventloop(&fds, &sevs, connections, &local_addr, NULL);

		buf = malloc(BUF_LEN);

		gettimeofday(&before, NULL);

		while (running) {
			int r;
			size_t idx;
			uint64_t delta;

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
				before = now;
			}
		}
	}

	return 0;
}
