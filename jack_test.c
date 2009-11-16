// CME: Attempting a minimal JACK client in preparation for building a Tcl extension for JACK, 2009-11-16.
// Using JACK's lsp.c (for jack_lsp) as an example.


#include <stdio.h>

#include <jack/jack.h>


int
main (int argc, char *argv[])
{
	jack_client_t *client;
	jack_status_t status;
	jack_options_t options = JackNoStartServer;
	const char **ports, **connections;
	char *server_name = NULL;

	unsigned int i;


	client = jack_client_open("jack_test", options, &status, server_name);
	if (client == NULL) { fprintf(stderr, "SPLAT!\n"); return 1; }
	
	ports = jack_get_ports(client, NULL, NULL, 0);

	for (i = 0; ports[i]; ++i) {
		printf("%s\n", ports[i]);
	}

	jack_client_close(client);
	exit(0);
}

