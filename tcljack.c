// This is the main implementation of TclJACK, my attempt at a Tcl extension for interacting with a JACK audio server via libjack.


// General overview of how to use it within Tcl:
// % load ./libtcljack.so
// jack_register -> Tcljack_Register()
// [port connection handling is outside this program's control; you can do it with the jack_connect command or qjackctl.  However, this interface should provide a wrapper for the JACK connect function (whatever it's called).]
// JACK server calls this component's process_jack_buffer() function when supplying audio.
// jack_deregister -> Tcljack_Deregister()



/* TODO:
 * Fix apparent memory leak in Tcljack_Ports()!  Also, have it return a proper list (to handle port names containing spaces).
 * Figure out how to handle disconnections from JACK properly.
 * Learn about option/argument handling, and implement for [jack meter -peak -rms -trough -db].
 * Investigate event handling: how does a Tcl extension declare and generate an event?  Or handle a Tcl event?  Or are these only relevant in Tk, which has an event loop?  Ah, see Tcl_CreateEventSource(), and http://wiki.tcl.tk/17195.
 * Determine whether signal handling is useful or necessary for this library.
 * Implement wrappers for the following:
 * jack_set_sample_rate_callback (to avoid needlessly querying for this; could simply update static variable in this, and/or (perhaps better) trigger a Tcl event)
 * jack_set_buffer_size_callback (similar to above)
 * jack_set_xrun_callback (for xrun reporting; ideally would trigger Tcl event to continue with push/event data flow style)
 * jack_on_shutdown (correct way to handle disconnection)
 * jack_on_error (similarly)

 * Various JACK port handling things: getting list of clients and their ports, connecting and disconnecting:
 * jack_set_client_registration_callback
 * jack_set_port_registration_callback
 * jack_set_port_connect_callback (in case connections were made behind our back; also handles disconnections)
	We probably want to be able to return to Tcl a list of ports, perhaps filtered by type.  Each port has relevant properties we might want to know/filter on/sort on as well.  We don't really want to have to implement a whole relational model and query language, though...pity I don't have one lying around I can just use...

 */



#include <tcl.h>
//#include <string.h>?
#include <math.h>
#include <stdbool.h>
#include <stdlib.h>	// for free()
#include <jack/jack.h>



// Hmm, we're gonna need some global variables for holding various items of state, huh?
static int counter = 0;	// This was just for testing
static jack_client_t *client;	// That's us!
static jack_status_t status;
static jack_options_t options = JackNoStartServer;
static jack_nframes_t sampling_frequency;	// (or "sample_rate" or "sampling_rate" or "jack_samplerate"?) in Hz.
static jack_nframes_t buffer_size;	// The current/last-reported JACK buffer size.  Could change dynamically while connected!  Use callback to stay abreast.
static const char *client_name = "tcljack";	// The (preferred) JACK name for this client.  Could be auto-modified by JACK during registering to avoid dups.  "tcljack" or "TclJACK"?  Most other JACK clients use all lowercase.
static char *server_name = NULL;	// NULL -> not picky.
// TODO: maybe also a registered flag, to make it less likely that we'll do something crashworthy like deregistering when we aren't registered.  Of course, we could still get booted without knowing about it...although maybe you can register a callback function with JACK for disconnection and other events.
// http://jackaudio.org/files/docs/html/group__ClientCallbacks.html
// http://jackaudio.org/files/docs/html/group__ErrorOutput.html
static bool registered = false;

// For built-in level metering, we'll need some global variables for storing peak, trough and RMS values for the current buffer.
// ...and of course the ports themselves!  Naming: input_port, meter_port or monitor_port?
// TODO: maintain an array of input ports and allow for creating/destroying them dynamically via Tcl commands.
jack_port_t *input_port;
// jack_port_t *input_port_left;
// jack_port_t *input_port_right;
// Do we need to declare these as volatile or something?
static float buffer_peak = 0.0;
static float buffer_trough = 0.0;
static float buffer_rms = 0.0;
static float buffer_dc_offset = 0.0;
// It might be nice to provide an interface for taking longer-term measurements (i.e. keep accumulating indefinitely (until reset)).
// What about wraparound?!
static unsigned long long long_term_frame_count = 0;
static float long_term_peak = 0.0;
static float long_term_trough = 0.0;
static float long_term_dc_offset = 0.0;
static float long_term_rms_sum_of_squares = 0.0;
// And similarly for periodic metering (accumulate measurements over n frames):
// Not as nice as being able to specify a number of milliseconds for the window size, but easier to implement!
// Oh, what if the JACK buffering scheme changes while measuring?!  Just reset these, I guess.  Callback.
static unsigned long long periodic_frame_count = 0.0;
static float periodic_peak = 0.0;
static float periodic_trough = 0.0;
static float periodic_dc_offset = 0.0;
static float periodic_rms_sum_of_squares = 0.0;
// Perhaps also a convenience boolean to indicate presence of a signal on the input port (or, TODO, ports).
static bool signal_present = false;


// Program info and usage:
//static const unsigned int tcljack_version_major = 0;
//static const unsigned int tcljack_version_minor = 1;
static const char* tcljack_version = "0.1";

// + version, usage, 
static char usage_string[] = "Usage forms:"
	"\n	jack register"
	"\n	jack deregister"
	"\n	jack transport"
	"\n	jack timecode"
	"\n	jack meter"
	"\n	jack samplerate"
	"\n	jack buffersize [frames]"
	"\n	jack cpuload"
	"\n	jack servername"
	"\n	jack clientname"
	"\n	jack info"
	"\n	jack version"
	"\n	jack ports"
//	"	jack meter -peak -rms -trough\n"
;

// Not sure if we can actually make use of this is interp->result assignment.
#define NOT_REGISTERED_ERROR_STRING "Not connected to JACK server! Try 'jack register'."


// A separate function for checking whether we are currently registered to a JACK server and aborting if not.
// Actually, since this will have to set up a return value, it might have to be a preprocessor macro.
#define CHECK_JACK_REGISTRATION_STATUS if (!registered) {Tcl_SetObjResult(interp, Tcl_NewStringObj(NOT_REGISTERED_ERROR_STRING, -1)); return TCL_ERROR; }




// Now we come to some actual functionality.  There are a few test functions (procedures?) lying around here still.


// Forward stub declarations for our callback implementations:
int process_jack_buffer(jack_nframes_t nframes, void *arg);
int sample_rate_callback(jack_nframes_t frames_per_second, void *arg);	// or set_sample_rate_callback()?
int buffer_size_callback(jack_nframes_t buffer_size_arg, void *arg);
void client_registration_callback(const char* name, int registering, void *arg);
// TODO: port_registration_callback
// TODO: port_connection_callback




// Note the naming of the command procedures: Tcljack_Xxx, not TclJACK_Xxx, which didn't seem to work ("couldn't find procedure Tcljack_init").


// Just a dummy "hello world" routine for testing:
// TODO: turn this into a "version" command, perhaps (reporting libjack's or TclJACK's version?).
static int
Tcljack_Hello(ClientData cdata, Tcl_Interp *interp, int objc,  Tcl_Obj * CONST objv[])
{
	Tcl_SetObjResult(interp, Tcl_NewStringObj("TclJACK says 'hello'.", -1));
//	Tcl_SetObjResult(interp, Tcl_NewStringObj(TCL_VERSION, -1));
	return TCL_OK;
}



// More testing: this extension maintains a global variable and this function returns its value as an integer via the object interface:
static int
Tcljack_Counter(ClientData cdata, Tcl_Interp *interp, int objc,  Tcl_Obj * CONST objv[])
{
	Tcl_Obj *result_pointer;

	counter++;
	result_pointer = Tcl_GetObjResult(interp);
	Tcl_SetIntObj(result_pointer, counter);

	// Can that just be simplified to the following?:
//	Tcl_SetObjResult(interp, Tcl_NewIntObj(++counter));
	return TCL_OK;
}



// Uh, does this return the version of the JACK server, or the library we're linked with?  I have a feeling it's the latter.
// TODO: separate commands for the name of the current server (if registered), version of TclJACK, etc.
static int
Tcljack_Version(ClientData cdata, Tcl_Interp *interp, int objc,  Tcl_Obj * CONST objv[])
{
	Tcl_Obj *result_pointer = Tcl_GetObjResult(interp);
	// AFAICT, jack_get_version_string() is for the libjack version, not the jackd we're connected to, so the following is not necessary:
//	CHECK_JACK_REGISTRATION_STATUS;
	Tcl_AppendStringsToObj(result_pointer, jack_get_version_string(), NULL);

/*
	// First attempt using jack_get_version() instead:
	// Hmm, this just gives 0.0.0.0.  Ah, apparently it's not really implemented; try jack_get_version_string() instead!
	int major, minor, micro, proto;
	jack_get_version(&major, &minor, &micro, &proto);
	Tcl_Obj *resultPtr = Tcl_GetObjResult(interp);

//	Tcl_AppendStringsToObj(resultPtr, "v", "[ersion]", NULL);
	Tcl_AppendObjToObj(resultPtr, Tcl_NewIntObj(major));
	Tcl_AppendStringsToObj(resultPtr, ".", NULL);
	Tcl_AppendObjToObj(resultPtr, Tcl_NewIntObj(minor));
	Tcl_AppendStringsToObj(resultPtr, ".", NULL);
	Tcl_AppendObjToObj(resultPtr, Tcl_NewIntObj(micro));
	Tcl_AppendStringsToObj(resultPtr, ".", NULL);
	Tcl_AppendObjToObj(resultPtr, Tcl_NewIntObj(proto));
	Tcl_AppendStringsToObj(resultPtr, NULL);
	Tcl_SetObjResult(interp, resultPtr);
*/

	Tcl_SetObjResult(interp, result_pointer);
	return TCL_OK;
}



// Register this client with JACK server:
static int
Tcljack_Register(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	// NOTE: Crashes can occur if you try to register when you are already registered.
	// If already registered, should we raise a Tcl error, or just disconnect and reconnect?
	if (registered) {jack_client_close(client);}

	client = jack_client_open(client_name, options, &status, server_name);
	if (client == NULL) { Tcl_SetObjResult(interp, Tcl_NewStringObj("Error connecting to JACK server.", -1)); registered = false; return TCL_ERROR; }
	registered = true;

	// Check if we got assigned a different client name (and update our idea of it, if so).
	if (status & JackNameNotUnique)
	{
		client_name = jack_get_client_name(client);	// Is this going to work OK with it being a const char*?  Memory management?!
		// Can we use stderr in a Tcl extension?  A: yep.
		fprintf (stderr, "tcljack: registered as client name \"%s\" \n", client_name);
	}

	// Tell the JACK server what our process() function is:
	jack_set_process_callback(client, process_jack_buffer, 0);

	// Sampling frequency notification callback function registration:
	jack_set_sample_rate_callback(client, sample_rate_callback, 0);

	// Buffer size notification callback function registration:
	jack_set_buffer_size_callback(client, buffer_size_callback, 0);

	// Client connection/disconnection callback registration:
	jack_set_client_registration_callback(client, client_registration_callback, 0);

	// TODO: port registration and connection/disconnection callbacks:
	// int jack_set_port_registration_callback 
	// int jack_set_port_connect_callback 
	// int jack_set_xrun_callback 

	// On-shutdown callback; applicable?
//	jack_on_shutdown(client, jack_shutdown, 0);

	// For monitoring, set up the input port(s):
	input_port = jack_port_register(client, "input", JACK_DEFAULT_AUDIO_TYPE, JackPortIsInput, 0);
	if ((input_port == NULL)) {	// || (input_port_right == NULL)
		Tcl_SetObjResult(interp, Tcl_NewStringObj("JACK: Unable to register input port with server!", -1));
		return TCL_ERROR; 
	}

	// Don't forget to activate this client:
	if (jack_activate(client)) {
		Tcl_SetObjResult(interp, Tcl_NewStringObj("JACK: Unable to activate client!", -1));
		return TCL_ERROR; 
	}

	// Maybe this should return "1", "OK", the name of the server or client, or something.  Then again, perhaps nothing is fine.
	//Tcl_SetObjResult(interp, Tcl_NewStringObj(??server name?? | 1 | whatevs, -1));
	//interp->result = "1";
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


static int
Tcljack_Clientname(ClientData cdata, Tcl_Interp *interp, int objc,  Tcl_Obj * CONST objv[])
{
	CHECK_JACK_REGISTRATION_STATUS;
	Tcl_SetObjResult(interp, Tcl_NewStringObj(client_name, -1));
	return TCL_OK;
}


// Retrieve the server's current sampling frequency:
// TODO: can we also change Fs via libjack?  I'm thinking not.
static int
Tcljack_Samplerate(ClientData cdata, Tcl_Interp *interp, int objc,  Tcl_Obj * CONST objv[])
{
	unsigned int sampling_rate = 0;
//	char output_buffer[6];	// I doubt that sampling rates in the MHz will be very useful for audio.
	Tcl_Obj *result_pointer;

	// Don't try to do anything if we're not registered (AFAWCT) (to avoid crash):
	CHECK_JACK_REGISTRATION_STATUS;

	// Find and return sampling rate:
	sampling_rate = jack_get_sample_rate(client);

	result_pointer = Tcl_GetObjResult(interp);
	Tcl_SetIntObj(result_pointer, sampling_rate);

	// For string interface:
//	sprintf(output_buffer, "%d", sampling_rate);
//	Tcl_SetResult(interp, output_buffer, TCL_VOLATILE);

	return TCL_OK;
}


// Report the JACK buffer size:
static int
Tcljack_Buffersize(ClientData cdata, Tcl_Interp *interp, int objc,  Tcl_Obj * CONST objv[])
{
	CHECK_JACK_REGISTRATION_STATUS;
	Tcl_SetObjResult(interp, Tcl_NewIntObj(buffer_size));
	return TCL_OK;
}


// Get timecode from JACK server:
// The actual timecode is only fleetingly accurate, so I don't think there's any point in storing it in a global variable, and it would be inefficient to query it during the process() callback, so we'll just query it on demand here.
// This will just return the current frame number; further formatting can be done in higher layers.
// Actually, JACK seems to have its own timecode feature, which is separate from the basic reporting of transport frame position, AFAICT, so maybe this procedure and the Tcl command it implements is mis-named.
static int
Tcljack_Timecode(ClientData cdata, Tcl_Interp *interp, int objc,  Tcl_Obj * CONST objv[])
{
	jack_position_t current_position;
	jack_transport_state_t transport_state;
	jack_nframes_t current_frame_time;
	Tcl_Obj *result_pointer;

	CHECK_JACK_REGISTRATION_STATUS;

	// Get time info from server:
	transport_state = jack_transport_query(client, &current_position);
	current_frame_time = jack_frame_time(client);

	// Currently returns only the current frame position.
	result_pointer = Tcl_GetObjResult(interp);
	Tcl_SetIntObj(result_pointer, current_position.frame);
	return TCL_OK;
}


// Retrieve the server's current CPU DSP load:
// TODO: switch to Tcl object interface?
// This should probably pass a value with as much precision as received; rounding can be done further up if required.
static int
Tcljack_Cpuload(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	float cpu_load = 0.0;
	char output_buffer[14];	// How big depends on the format in sprintf below, I guess.

	CHECK_JACK_REGISTRATION_STATUS;

	// Find and return sampling rate:
	cpu_load = jack_cpu_load(client);	// NOTE: this has already been multiplied by 100%!
	sprintf(output_buffer, "%3.10f", cpu_load);	// Pad with spaces to the left?  1 DP?  Is the returned value in % or not?
	Tcl_SetResult(interp, output_buffer, TCL_VOLATILE);

	return TCL_OK;
}


// This function provides a single command for level metering, to ensure that we use the same measurement window for all measurements.  Returning a tuple, essentially (as a Tcl list, I guess).
// TODO: handle args for different measurements.  Peak, trough, and RMS are recorded by process_jack_buffer(); here we just have to output them.
// TODO: could perhaps optionally do conversion to dB (either numeric or AES-17 dB FS), Stevens RMS loudness, etc. as well.  That stuff isn't happening at the audio data rate, so delegating to the Tcl layer shouldn't be a performance problem.
// Would be better I think to pass the floats as objects and not have to worry about string formatting here.  TODO: investigate.
static int
//Tcljack_Meter(ClientData cdata, Tcl_Interp *interp, int objc,  Tcl_Obj * CONST objv[])
Tcljack_Meter(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	Tcl_Obj *result_pointer;
	char output_buffer[(1 + 3 + 4 * (1 + 1 + 16)) + 1];	// How big depends on the format in sprintf below: 1 for terminating null, 2 spaces, 3 numbers, 1 digit, 1 for decimal point, 8 DP.  Should maybe #define some of these and use in the format below (TODO).
	// Tcl uses 16 DP for floats, FWIW.
	// Oh, DC offset could be negative!  Need to reserve space for that possibility.

	CHECK_JACK_REGISTRATION_STATUS;

	sprintf(output_buffer, "%1.16f %1.16f %1.16f %1.16f", buffer_peak, buffer_rms, buffer_trough, buffer_dc_offset);
	Tcl_SetResult(interp, output_buffer, TCL_VOLATILE);

//	Tcl_SetObjResult(interp, Tcl_???());

	return TCL_OK;
}


// DEPRECATED.  New design uses [jack meter -peak].  See Tcljack_Meter.
// Return the last recorded per-buffer peak sample value (as a raw numeric float, not dB or anything).
// This will be read asynchronously, but as meters are only going to be refreshing up to say 60 Hz, that's probably fine.  1 / 60 Hz = ~17 ms.  At p=64 Fs=96 kHz, each period would last 666 microseconds.
// How many digits of precision do we need?  With DSP being applied, who knows, but for plain 24-bit audio: 1 / 2 ^ 24 = ~6e-08, so 8 decimal places is probably reasonable.  JACK floating-point data should not normally exceed 1, so 1 digit before the decimal should be fine.
/*
static int
Tcljack_Peak(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	char output_buffer[10];	// How big depends on the format in sprintf below, I guess.

	CHECK_JACK_REGISTRATION_STATUS;

	sprintf(output_buffer, "%1.8f", buffer_peak);
	Tcl_SetResult(interp, output_buffer, TCL_VOLATILE);

	return TCL_OK;
}
*/



// Some basic transport-related commands; perhaps bundle these into a single procedure for "transport".
static int
Tcljack_Transport(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	CHECK_JACK_REGISTRATION_STATUS;

	// argv[0] is the subcommand name, which would be "transport".
	if (argc < 2)
	{
		Tcl_SetResult(interp, "Usage: jack transport ( start | stop | locate <frame> )", TCL_STATIC);
		return TCL_ERROR;
	}
	if (strcmp(argv[1], "start") == 0 || strcmp(argv[1], "play") == 0 || strcmp(argv[1], "unpause") == 0)
	{
		jack_transport_start(client);
		return TCL_OK;
	}
	else if (strcmp(argv[1], "stop") == 0 || strcmp(argv[1], "pause") == 0)
	{
		jack_transport_stop(client);
		return TCL_OK;
	}
	else if (strcmp(argv[1], "locate") == 0 || strcmp(argv[1], "seek") == 0 || strcmp(argv[1], "position") == 0)
	{
		if (argc == 3)
			jack_transport_locate(client, atoi(argv[2]));
		else
		{
			// TODO: "locate"-specific usage message:
			Tcl_SetResult(interp, "Usage: jack transport locate <frame>", TCL_STATIC);
			return TCL_ERROR;
		}
	}
	else
	{
		// TODO: "transport"-specific usage message:
		Tcl_SetResult(interp, "Usage: jack transport ( start | stop | locate <frame> )", TCL_STATIC);
		return TCL_ERROR;
	}
	return TCL_OK;
}



// Request that the JACK server switch to a new buffer size (must be a power of 2; should we check for that here, or just rely on the JACK server reporting a failure?).
static int
Tcljack_Setbuffersize(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
        CHECK_JACK_REGISTRATION_STATUS;

	// Args will be like "buffersize 512", i.e. argc == 2, argv[1] == 512

	if (argc != 2) {
		Tcl_SetObjResult(interp, Tcl_NewStringObj("JACK: Tcljack_Setbuffersize: wrong number of arguments!", -1));
		return TCL_ERROR;
	}

	if (jack_set_buffer_size(client, atoi(argv[1])) != 0) {
		Tcl_SetObjResult(interp, Tcl_NewStringObj("JACK: failed to set requested buffer size!", -1));
		return TCL_ERROR;
	} else
		return TCL_OK;
}




// Returns a list of all port names (input, output, system, whatever) available/registered on the JACK server we're registered with.
// TODO: convert to Tcl_Obj interface.
static int
Tcljack_Ports(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	const char **ports, **connections;
	unsigned int i;
//	Tcl_Obj *result_pointer = Tcl_GetObjResult(interp);
	char *result_list_string;
	Tcl_Obj *result_list = Tcl_NewListObj(0, NULL);

	CHECK_JACK_REGISTRATION_STATUS;

	// Retrieve the names of all ports from the JACK server
	// Note that this won't necessarily include all clients (some may have no ports!).
	ports = jack_get_ports(client, NULL, NULL, 0);
	for (i = 0; ports[i]; ++i) {
	//	jack_port_t *port = jack_port_by_name(client, ports[i]);
		// Can we assume that the only ':' in a fully-qualified port name will be the separator between client and port name elements?
		// Oh, actually, we can use Tcl_Merge() to build the (properly-structured) list, so we only need this loop to determine the number of elements in the ports array.
	//	Tcl_AppendStringsToObj(result_pointer, ports[i], NULL);
	//	Tcl_AppendStringsToObj(result_pointer, " ", NULL);
		Tcl_ListObjAppendElement(interp, result_list, Tcl_NewStringObj(ports[i], -1));
	}
//	Tcl_SetObjResult(interp, result_pointer);
	// Since jack_get_ports() returns a pointer to an array of chars, I guess we can just use Tcl_Merge() on it, like so:
//	result_list_string = Tcl_Merge(i, ports);
//	Tcl_Free((char *) result_pointer);
//	Tcl_SetResult(interp, result_list_string, TCL_DYNAMIC);
	// Free "result_list_string", and/or "ports" somehow?
//	ckfree()?!
//	Tcl_Free((char *) result_list_string);
	Tcl_SetObjResult(interp, result_list);
	free(ports);
	return TCL_OK;
}




// Various callback functions internal to TclJACK follow:

// First, the JACK audio buffer size (nperiods x period size) callback
int
buffer_size_callback(jack_nframes_t nframes, void *arg)
{
	buffer_size = nframes;
	fprintf(stderr, "tcljack: JACK buffer size changed to %d.\n", buffer_size);
	return 0;
}

int
sample_rate_callback(jack_nframes_t sample_rate_arg, void *arg)
{
	sampling_frequency = sample_rate_arg;
	fprintf(stderr, "tcljack: JACK sampling frequency changed to %d Hz.\n", sampling_frequency);
	return 0;
}


void
client_registration_callback(const char* client_name, int registering, void *arg)
{
	// Can we print to stderr or some log stream or something?
	fprintf(stderr, "tcljack: a client (%s) was %s.\n", client_name, registering ? "registered" : "deregistered");
}


// For monitoring, we'll need to set up a port (or two, or n) to receive audio, and define a JACK process() callback fuction.  We've called it process_jack_buffer.
// This will have level metering capability, calculating statistics over the current JACK sample buffer, and copying the results into the relevant global variables from which they can be read asynchronously from Tcl.
int
process_jack_buffer(jack_nframes_t nframes, void *arg)
{
	jack_default_audio_sample_t *input;
//	jack_default_audio_sample_t *in_right;
	unsigned int i;		// For for-loop index.
	jack_default_audio_sample_t max_sample = 0.0;		// For peak (largest encountered) value
	jack_default_audio_sample_t min_sample = 1.0;	// For trough (smallest non-zero) value
	jack_default_audio_sample_t rms_sum_of_squares = 0.0;	// For RMS level
	jack_default_audio_sample_t offset_sum = 0.0;	// for DC offset measurement
	
	input = jack_port_get_buffer (input_port, nframes);
	for (i = 0; i < nframes; i++)
	{
		const float current_sample_abs = fabs(input[i]);

		// For peak:
		if (current_sample_abs > max_sample) { max_sample = current_sample_abs; }

		// For trough:
		if (current_sample_abs < min_sample) { min_sample = current_sample_abs; }

		// For RMS:
		rms_sum_of_squares += pow(current_sample_abs, 2.0);

		// For DC offset (NOTE: don't use current_sample, which is an absolute value!):
		offset_sum += input[i];
	}

	// Copy the resulting values to their respective global variables, from which they can be read from the Tcl side.
	// (Or maybe just use buffer_peak in the loop above, why not?  Ah, but can't do that trick with the RMS value.)
	buffer_peak = max_sample;
	buffer_trough = min_sample;
	buffer_rms = sqrt(rms_sum_of_squares / nframes);
	buffer_dc_offset = offset_sum / nframes;	// Integer division? Do not want!

	return 0;
}




// Here's where/how subcommands are handled: a dispatcher function to identify and run subcommands of [jack]:
// Can we use the Tcl object interface with this approach, or do all the subcommands uniformly have to return strings?
static int
Tcljack_Dispatcher(ClientData cdata, Tcl_Interp *interp, int argc,  CONST char *argv[])
{
	// argv[0] is the command name, which would be "jack".
	if (argc < 2)
	{
		Tcl_SetResult(interp, usage_string, TCL_STATIC);
		return TCL_ERROR;
	}
	if (strcmp(argv[1], "register") == 0)
		return Tcljack_Register(cdata, interp, argc-1, &argv[1]);
	else if (strcmp(argv[1], "deregister") == 0)
		return Tcljack_Deregister(cdata, interp, argc-1, &argv[1]);
	else if (strcmp(argv[1], "version") == 0)
		return Tcljack_Version(cdata, interp, 0, NULL);
	else if (strcmp(argv[1], "clientname") == 0)
		return Tcljack_Clientname(cdata, interp, 0, NULL);
	else if (strcmp(argv[1], "samplerate") == 0)
		return Tcljack_Samplerate(cdata, interp, 0, NULL);
	else if (strcmp(argv[1], "buffersize") == 0 && argc == 3)	// e.g. "jack buffersize 512"
		return Tcljack_Setbuffersize(cdata, interp, argc-1, &argv[1]);
        else if (strcmp(argv[1], "buffersize") == 0)
                return Tcljack_Buffersize(cdata, interp, 0, NULL);
	else if (strcmp(argv[1], "timecode") == 0)
		return Tcljack_Timecode(cdata, interp, 0, NULL);
	else if (strcmp(argv[1], "cpuload") == 0)
		return Tcljack_Cpuload(cdata, interp, 0, NULL);
	else if (strcmp(argv[1], "meter") == 0)
		return Tcljack_Meter(cdata, interp, argc-1, &argv[1]);
	else if (strcmp(argv[1], "transport") == 0)
		return Tcljack_Transport(cdata, interp, argc-1, &argv[1]);
	else if (strcmp(argv[1], "ports") == 0)
		return Tcljack_Ports(cdata, interp, 0, NULL);
	else
	{
		Tcl_SetResult(interp, usage_string, TCL_STATIC);
		return TCL_ERROR;
	}
}


 /*
  * _Init -- Called when Tcl loads your extension.
  */
int DLLEXPORT
Tcljack_Init(Tcl_Interp *interp)
{
//	if (Tcl_InitStubs(interp, TCL_VERSION, 0) == NULL)
	if (Tcl_InitStubs(interp, "8.4", 0) == NULL)	// Just to make it work on my test system, which has a messy Tcl 8.4 + 8.5 setup.
	{
		return TCL_ERROR;
	}

	if (Tcl_PkgProvide(interp, "TclJACK", tcljack_version) == TCL_ERROR)
	{
		return TCL_ERROR;
	}

	// Good to go...
	
	// Main command is "jack", with subcommands identified and handled by Tcljack_Dispatcher():
	Tcl_CreateCommand(interp, "jack", Tcljack_Dispatcher, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

	// The following will all be deprecated by having subcommands, handled by Tcljack_Dispatcher():
	Tcl_CreateObjCommand(interp, "jack_counter", Tcljack_Counter, NULL, NULL);
	Tcl_CreateCommand(interp, "jack_register", Tcljack_Register, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateCommand(interp, "jack_deregister", Tcljack_Deregister, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
//	Tcl_CreateCommand(interp, "jack_samplerate", Tcljack_Samplerate, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateCommand(interp, "jack_cpuload", Tcljack_Cpuload, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);

//	Tcl_CreateCommand(interp, "jack_peak", Tcljack_Peak, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
	Tcl_CreateCommand(interp, "jack_meter", Tcljack_Meter, (ClientData)NULL, (Tcl_CmdDeleteProc *)NULL);
 
	return TCL_OK;
}

