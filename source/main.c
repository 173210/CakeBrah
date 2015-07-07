#include <3ds.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <malloc.h>
#include "brahma.h"
#include "hid.h"
#include "menus.h"
#include "sochlp.h"

#ifndef LAUNCHER_PATH
#define LAUNCHER_PATH "Cakes.dat"
#endif

s32 main (void) {
	// Initialize services
	srvInit();
	aptInit();
	hidInit(NULL);
	gfxInitDefault();
	fsInit();
	sdmcInit();
	hbInit();
	qtmInit();

    // Make sure the settings applied by gfxInitDefault come into effect
    gfxSwapBuffers();

    // Memory for the arm9 payload
    u32 payload_size = 0x10000;
    void *payload = malloc(payload_size);
    if (!payload) goto error;

    int rc;

    // Load the arm9 payload into memory
    FILE *file = fopen("/" LAUNCHER_PATH, "r");
    if (!file) goto error;
    rc = fseek(file, 0x20000, SEEK_SET);
    if (rc != 0) goto error;
    fread(payload, payload_size, 1, file);
    if (ferror(file) != 0) goto error;
    fclose(file);

    if (brahma_init()) {
        rc = load_arm9_payload_from_mem(payload, payload_size);
        if (rc != 1) goto error;
        firm_reboot();
        brahma_exit();
    }

    free(payload);

	hbExit();
	sdmcExit();
	fsExit();
	gfxExit();
	hidExit();
	aptExit();
	srvExit();
	// Return to hbmenu
	return 0;

error:
    consoleInit(GFX_BOTTOM, NULL);
    printf("An error occurred while loading the payload.\nMake sure your launcher is located at:\n/" LAUNCHER_PATH "\n\nPress any key to exit");
    wait_key();

    if (payload) free(payload);

	hbExit();
	sdmcExit();
	fsExit();
	gfxExit();
	hidExit();
	aptExit();
	srvExit();
    return 1;
}
