//
// File:		    accel_hook.c
// Programmer:		Trent Thompson
// Date:		    November 14, 2019
// Description:		This file contains the C code needed to implement the LED accelerometer game.
//





// Libraries
#include <stdio.h>
#include <stdint.h>
#include <ctype.h>
#include "stm32f3_discovery.h"
#include "common.h"
#include "Drivers/BSP/Components/lsm303dlhc/lsm303dlhc.h"



// Constants
#define DELAY_FACTOR 1000



// Prototypes
void setup_game(int winTime, int winningLed);
void determine_outcome();
void determine_light();
int win_stopwatch();




// Data declaration
int tick = 0; // The current count of the tick



//
// Function:    dhttA4
// Description: Gets parameters from the user input and initiates the LED accelerometer game
// Parameters:  int action
// Returns:     void
//
void dhttA4(int action)
{
  if(action==CMD_SHORT_HELP) return;
  if(action==CMD_LONG_HELP) {
    printf("LED Game\n\n"
   "This command begins the LED game\n"
   );
    return;
  }

  // If there is no game currently running
  if (tick == 0) {
    // Variable Declaration
    uint32_t winTime;
    uint32_t winningLed;
    uint32_t gameTime;
    int fetch_status;

    // Fetch a value for the winTime (in ms)
    fetch_status = fetch_uint32_arg(&winTime);
    if (fetch_status) {
      // Default value
      winTime = 500;
    }

    // Fetch a value for the winningLed
    fetch_status = fetch_uint32_arg(&winningLed);
    if (fetch_status) {
      // Default value
      winningLed = 0;
    }

    // Fetch a value for the gameTime (in s)
    fetch_status = fetch_uint32_arg(&gameTime);
    if (fetch_status) {
      // Default value
      gameTime = 30;
    }

    // Call the setup_game function to store variables and turn off all led's
    setup_game(winTime, winningLed);

    // Give the tick a value based on the gameTime * DELAY_FACTOR, thus initiating the game
    tick = gameTime * DELAY_FACTOR;
  }
}



//
// Function:    handleTick
// Description: Drives the delay for the LED accelerometer game based on the tick value
// Parameters:  void
// Returns:     void
//
void handleTick(void) {
  // If we have a running game
  if (tick > 0) {
    // Poll accelerometer if the tick is an increment of 100
    if (tick % 100 == 0) {
      determine_light();
    }

    // If the win stopwatch returns 0 we know the game should just continue
    if (win_stopwatch() == 0) {
      tick--;
    }
    // Otherwise, it has returned a 1 meaning the user has won and the game has ended
    else {
      // Set the tick to 1 to indicate that the game has ended
      tick = 1;
    }

    // When the tick is set to 1, (either by running out of time, or winning the game), blink the lights accordingly
    if (tick == 1) {
      determine_outcome();

      // Set the tick to 0 indicating there is no game currently running
      tick = 0;
    }
  }
}

ADD_CMD("dhttGame", dhttA4,"<delay> <target> <game_time>  Play a fun LED game")