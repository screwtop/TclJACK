#include <tcl.h>
//#include <string.h>?
#include <math.h>
#include <stdbool.h>
#include <jack/jack.h>


// This is the main implementation of TclJACK, my attempt at a Tcl extension for interacting with a JACK audio server via libjack.
// General overview:
// % load ./libtcljack.so
// jack_register -> Tcljack_Register()
//

// Note the naming: Tcljack_Xxx, not TclJACK_Xxx, which didn't seem to work ("couldn't find procedure Tcljack_init").


// Hmm, we're gonna need some global variables for holding server connection state, huh?
static int counter = 0;
static jack_client_t *client;
static jack_status_t status;
static jack_options_t options = JackNoStartServer;
static const char *client_name = "tcljack";	// The JACK name for this client.  Could be auto-modified by JACK during registering to avoid dups.
static char *server_name = NULL;	// NULL -> not picky.
// TODO: maybe also a registered flag, to make it less likely that we'll do something crashworthy like deregistering when we aren't registered.  Of course, we could still get booted without knowing about it...although maybe you can register a callback function with JACK for disconnection and other events.
// http://jackaudio.org/files/docs/html/group__ClientCallbacks.html
// http://jackaudio.org/files/docs/html/group__ErrorOutput.html
static bool registered = false;
// I guess if we used those callbacks appropriately, we could also maintain state such as the sampling rate etc. rather than querying for it every time.

// For built-in level metering, we'll need some global variables for storing peak, trough and RMS values for the current buffer.
// ...and of course the ports themselves!  Naming: input_port, meter_port or monitor_port?
jack_port_t *input_port;
// jack_port_t *input_port_left;
// jack_port_t *input_port_right;
// Do we need to declare these as volatile or something?
static float buffer_peak = 0.0;
static float buffer_trough = 0.0;
static float buffer_rms = 0.0;
// Perhaps also a convenience boolean to indicate presence of a signal on the input port (or, TODO, ports).
static bool signal_present = false;


// Forward/stub/whatever declarations:
int process_jack_buffer(jack_nframes_t nframes, void *arg);


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
	// Crashes can occur if you try to register when you are already registered.
	// If already registered, should we raise a Tcl error, or just disconnect and reconnect?
	if (registered) {jack_client_close(client);}

	client = jack_client_open(client_name, options, &status, server_name);
	if (client == NULL) { interp->result = "Error connecting to JACK server."; registered = false; return TCL_ERROR; }
	registered = true;

	// Check if we got assigned a different client name (and update our idea of it, if so).
	if (status & JackNameNotUnique)
	{
		client_name = jack_get_client_name(client);
		// Can we use stderr in a Tcl extension?
	//	fprintf (stderr, "unique name `%s' assigned\n", client_name);
	}

	// Tell the JACK server what our process() function is:
	jack_set_process_callback(client, process_jack_buffer, 0);

	// On-shutdown callback; applicable?
//	jack_on_shutdown(client, jack_shutdown, 0);

	// For monitoring, set up the input port(s):
	input_port = jack_port_register(client, "input", JACK_DEFAULT_AUDIO_TYPE, JackPortIsInput, 0);
	if ((input_port == NULL)) {	// || (input_port_right == NULL)
		interp->result = "JACK: Unable to register input port with server!";
		return TCL_ERROR; 
	}

	if (jack_activate(client)) {
		interp->result = "JACK: Unable to activate client!";
		return TCL_ERROR; 
	}

	return TCL_OK;
}

// Deregister this client from JACK server:
// What's the better way to handle it: only try closing if registered, or return a Tcl error if deregistering when noc registered?
static int
Tcljack_Deregister(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	// Only try to disconnect if we think we're registered (to avoid crash!).
	if (registered) {
		jack_client_close(client);
		registered = false;
	}
	return TCL_OK;
}



// Retrieve the server's current sampling frequency:
static int
Tcljack_Samplerate(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	unsigned int sampling_rate = 0;
	char output_buffer[6];	// I doubt that sampling rates in the MHz will be very useful for audio.

	// Don't try to do anything if we're not registered (AFAWCT) (to avoid crash):
	if (!registered) {
		interp->result = "Not connected to JACK server!";
		return TCL_ERROR; 
	}

	// Find and return sampling rate:
	sampling_rate = jack_get_sample_rate(client);
	sprintf(output_buffer, "%d", sampling_rate);
	Tcl_SetResult(interp, output_buffer, TCL_VOLATILE);

	return TCL_OK;
}

// Retrieve the server's current CPU DSP load:
// TODO: switch to Tcl object interface?
static int
Tcljack_Cpuload(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	float cpu_load = 0.0;
	char output_buffer[6];	// How big depends on the format in sprintf below, I guess.

	// Don't try to do anything if we're not registered (AFAWCT) (to avoid crash):
	if (!registered) {
		interp->result = "Not connected to JACK server!";
		return TCL_ERROR; 
	}

	// Find and return sampling rate:
	cpu_load = jack_cpu_load(client);	// NOTE: this has already been multiplied by 100%!
	sprintf(output_buffer, "%0.2f", cpu_load);	// Pad with spaces to the left?  1 DP?  Is the returned value in % or not?
	Tcl_SetResult(interp, output_buffer, TCL_VOLATILE);

	return TCL_OK;
}


// CTTOI, we probably want a single command for level metering, to ensure that we use the same measurement window for all measurements.  Returning a tuple, essentially (as a Tcl list, I guess).
// TODO: handle args for different measurements.  Currently just does peak (testing).  Should support peak, trough, RMS.  Could perhaps optionally do conversion to dB (either numeric or AES-17 dB FS), Stevens RMS loudness, etc. as well.
static int
Tcljack_Meter(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	char output_buffer[10];	// How big depends on the format in sprintf below, I guess.

	// Don't try to do anything if we're not registered (AFAWCT) (to avoid crash):
	if (!registered) {
		interp->result = "Not connected to JACK server!";
		return TCL_ERROR; 
	}

	sprintf(output_buffer, "%1.8f", buffer_rms);
	Tcl_SetResult(interp, output_buffer, TCL_VOLATILE);

	return TCL_OK;
}


// Return the last recorded per-buffer peak sample value (as a raw numeric float, not dB or anything).
// This will be read asynchronously, but as meters are only going to be refreshing up to say 60 Hz, that's probably fine.  1 / 60 Hz = ~17 ms.  At p=64 Fs=96 kHz, each period would last 666 microseconds.
// How many digits of precision do we need?  With DSP being applied, who knows, but for plain 24-bit audio: 1 / 2 ^ 24 = ~6e-08, so 8 decimal places is probably reasonable.  JACK floating-point data should not normally exceed 1, so 1 digit before the decimal should be fine.
static int
Tcljack_Peak(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	char output_buffer[10];	// How big depends on the format in sprintf below, I guess.

	// Don't try to do anything if we're not registered (AFAWCT) (to avoid crash):
	if (!registered) {
		interp->result = "Not connected to JACK server!";
		return TCL_ERROR; 
	}

	sprintf(output_buffer, "%1.8f", buffer_peak);
	Tcl_SetResult(interp, output_buffer, TCL_VOLATILE);

	return TCL_OK;
}


// For monitoring, we'll need to set up a port (or two, or n) to receive audio, and define a JACK process() callback fuction.
// This will have level metering capability, calculating statistics over the current JACK sample buffer, and copying the results into the relevant global variables from which they can be read asynchronously from Tcl.
int
process_jack_buffer(jack_nframes_t nframes, void *arg)
{
	jack_default_audio_sample_t *in;
//	jack_default_audio_sample_t *in_right;
	unsigned int i;		// For for-loop index.
	jack_default_audio_sample_t max_sample = 0.0;		// For peak (largest encountered) value
	jack_default_audio_sample_t min_sample = 0.0;	// For trough (smallest non-zero) value
	jack_default_audio_sample_t rms_sum_of_squares = 0.0;	// For RMS level
	jack_default_audio_sample_t offset_average = 0.0;	// for DC offset measurement
	
	in = jack_port_get_buffer (input_port, nframes);
	for (i = 0; i < nframes; i++)
	{
		const float current_sample = fabs(in[i]);

		// For peak:
		if (current_sample > max_sample) { max_sample = current_sample; }

		// For trough:
		if (current_sample < min_sample) { min_sample = current_sample; }

		// For RMS:
		rms_sum_of_squares += pow(current_sample,2.0);
	}

	// Copy ultimate peak value to global variable:
	// Or maybe just use buffer_peak in the loop above, why not?
	buffer_peak = max_sample;
	buffer_rms = sqrt(rms_sum_of_squares / nframes);

	return 0;
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

	Tcl_CreateCommand(interp, "jack_peak", Tcljack_Peak, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateCommand(interp, "jack_meter", Tcljack_Meter, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	// How do we implement subcommands, like [jack register] or [jack info]?  Do we just define a main "jack" command and have it figure out whatever subcommand might be being called from the arguments?
	 
	return TCL_OK;
}

