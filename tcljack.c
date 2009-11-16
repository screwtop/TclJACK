#include <tcl.h>
//#include <string.h>?
#include <stdbool.h>
#include <jack/jack.h>


// Note the naming: Tcljack_Xxx, not TclJACK_Xxx, which didn't seem to work ("couldn't find procedure Tcljack_init").


// Hmm, we're gonna need some global variables for holding server connection state, huh?
static int counter = 0;
static jack_client_t *client;
static jack_status_t status;	// unused?
static jack_options_t options = JackNoStartServer;
static char *server_name = NULL;	// NULL -> not picky.
// TODO: maybe also a connected flag, to make it less likely that we'll do something crashworthy like deregistering when we aren't connected.  Of course, we could still get booted without knowing about it...although maybe you can register a callback function with JACK for disconnection and other events.
// http://jackaudio.org/files/docs/html/group__ClientCallbacks.html
// http://jackaudio.org/files/docs/html/group__ErrorOutput.html
static bool connected = false;
// I guess if we used those callbacks appropriately, we could also maintain state such as the sampling rate etc. rather than querying for it every time.


// Just a dummy "hello world" routine:
static int
Tcljack_Hello(ClientData cdata, Tcl_Interp *interp, int objc,  Tcl_Obj * CONST objv[])
{
	Tcl_SetObjResult(interp, Tcl_NewStringObj("TclJACK says 'hello'.", -1));
//	Tcl_SetObjResult(interp, Tcl_NewStringObj(TCL_VERSION, -1));
	return TCL_OK;
}



// Test of global variable and returning an integer via the object interface:
static int
Tcljack_Counter(ClientData cdata, Tcl_Interp *interp, int objc,  Tcl_Obj * CONST objv[])
{
	Tcl_Obj *result_pointer;

	counter++;
	result_pointer = Tcl_GetObjResult(interp);	
	Tcl_SetIntObj(result_pointer, counter);
	return TCL_OK;
}



// Register this client with JACK server:
static int
Tcljack_Register(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	if (connected) {jack_client_close(client);}
	client = jack_client_open("tcljack", options, &status, server_name);
	if (client == NULL) { interp->result = "Error connecting to JACK server."; connected = false; return TCL_ERROR; }
	connected = true;
	return TCL_OK;
}

// Deregister this client from JACK server:
// What's the better way to handle it: only try closing if connected, or return a Tcl error?
static int
Tcljack_Deregister(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	// Only try to disconnect if we think we're connected (to avoid crash!).
	if (connected) {
		jack_client_close(client);
		connected = false;
	}
	return TCL_OK;
}



// Retrieve the server's current sampling frequency:
static int
Tcljack_Samplerate(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	unsigned int sampling_rate = 0;
	char output_buffer[6];	// I doubt that sampling rates in the MHz will be very useful for audio.

	// Don't try to do anything if we're not connected (AFAWCT) (to avoid crash):
	if (!connected) {
		interp->result = "Not connected to JACK server!";
		return TCL_ERROR; 
	}

	// Find and return sampling rate:
	sampling_rate = jack_get_sample_rate(client);
	sprintf(output_buffer, "%d", sampling_rate);
	Tcl_SetResult(interp, output_buffer, TCL_VOLATILE);

	return TCL_OK;
}

// Retrieve the server's current sampling frequency:
// TODO: switch to Tcl object interface?
static int
Tcljack_Cpuload(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	float cpu_load = 0.0;
	char output_buffer[6];	// How big depends on the format in sprintf below, I guess.

	// Don't try to do anything if we're not connected (AFAWCT) (to avoid crash):
	if (!connected) {
		interp->result = "Not connected to JACK server!";
		return TCL_ERROR; 
	}

	// Find and return sampling rate:
	cpu_load = jack_cpu_load(client);	// NOTE: this has already been multiplied by 100%!
	sprintf(output_buffer, "%0.2f", cpu_load);	// Pad with spaces to the left?  1 DP?  Is the returned value in % or not?
	Tcl_SetResult(interp, output_buffer, TCL_VOLATILE);

	return TCL_OK;
}



 /*
  * _Init -- Called when Tcl loads your extension.
  */
int DLLEXPORT
Tcljack_Init(Tcl_Interp *interp)
{
//	if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL)
	if (Tcl_InitStubs(interp, "8.4", 0) == NULL)	// Just to make it work with expect, which is currently 8.4 on my system, even though it's otherwise Tcl 8.5.
	{
		return TCL_ERROR;
	}

	if (Tcl_PkgProvide(interp, "TclJACK", "0.1") == TCL_ERROR)
	{
		return TCL_ERROR;
	}

	// Good to go...
	Tcl_CreateObjCommand(interp, "jack", Tcljack_Hello, NULL, NULL);
	Tcl_CreateObjCommand(interp, "jack_counter", Tcljack_Counter, NULL, NULL);
	Tcl_CreateCommand(interp, "jack_register", Tcljack_Register, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateCommand(interp, "jack_deregister", Tcljack_Deregister, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateCommand(interp, "jack_samplerate", Tcljack_Samplerate, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateCommand(interp, "jack_cpuload", Tcljack_Cpuload, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	// How do we implement subcommands, like [jack register] or [jack info]?  Do we just define a main "jack" command and have it figure out whatever subcommand might be being called from the arguments?
	 
	return TCL_OK;
}

