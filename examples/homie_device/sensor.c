#define _GNU_SOURCE
#include <arpa/inet.h>
#include <sys/socket.h>
#include <netdb.h>
#include <ifaddrs.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <linux/if_link.h>

/* TODO: Avoid ambient authority! */
void pony_cpu_temperature(char *temp) {
	int i;
	char *buf;
	FILE *fp;
	buf = temp;
    fp = fopen("/sys/class/thermal/thermal_zone2/temp", "r");
	for (i = 0; i < 5; i++) {
		*buf++ = fgetc(fp);
		if (buf - temp == 2) {
			*buf++ = '.';
		}
	}
	*buf++ = '\0';
	fclose(fp);
}

/* TODO: Avoid ambient authority! */
void pony_network_address(char *ip, char *mac) {
	struct ifaddrs *ifaddr, *ifa;
	int family, s, n, i;
	char host[NI_MAXHOST], path[23 + NI_MAXHOST], *buf;
	FILE *fp;
	if (getifaddrs(&ifaddr) == -1) {
		return;
	}
	path[0] = '\0';

	/* Walk through linked list, maintaining head pointer so we
	   can free list later */
	for (ifa = ifaddr, n = 0; ifa != NULL; ifa = ifa->ifa_next, n++) {
		if (ifa->ifa_addr == NULL) continue;
		family = ifa->ifa_addr->sa_family;
		if (family == AF_INET) {
			s = getnameinfo(ifa->ifa_addr,
			                sizeof(struct sockaddr_in),
			                host, NI_MAXHOST,
			                NULL, 0, NI_NUMERICHOST);
			if (s == 0) {
				if (memcmp(ifa->ifa_name, "lo", 2) != 0 &&
				    memcmp(ifa->ifa_name, "docker", 6) != 0) {
					sprintf(path, "/sys/class/net/%s/address", ifa->ifa_name);
					strcpy(ip, host);
					break;
				}
			}
		}
	}
	freeifaddrs(ifaddr);
	if (path[0] == '\0') {
		return;
	}

	/* Now get MAC from /sys/class/net/<interface>/address */
	buf = mac;
	fp = fopen(path, "r");
	for (i = 0; i < 17; i++) {
		*buf++ = fgetc(fp);
	}
	*buf++ = '\0';
	fclose(fp);
}
