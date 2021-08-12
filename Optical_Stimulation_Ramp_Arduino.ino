/* ---------------------------------------------------------------------- *
 * Program: Optical_Interval_Stimulation.ino                              *
 * Authors: Stephen Ma, Trevor Nash                                                     *
 * Last Updated: 8/12\/2021                                                *
 *                                                                        *
 * This program controls the optical stimulation of cells.  The		  *
 * parameters are set in the initial setup section of the code.  The ramp *
 * is executed by the main control loop.                                  * 
 * ---------------------------------------------------------------------- */

// Set up the variables to control voltage, level, frequency, period, and pulse
volatile float startFrequency;
volatile float endFrequency;
volatile float steps;
volatile float ddFrequency;
volatile float dynamicFrequency;
volatile float pulseperMinute;
volatile float restInterval;
volatile float pulseLength;

// Variables that count the milliseconds on the arduino internal clock
volatile unsigned long start;
volatile unsigned long startCode;
volatile unsigned long startSync;
volatile unsigned long stopSync;

/* Define parameters for the ramp */

void setup() 
{

  // starts serial communication with the computer
  Serial.begin(9600);
  
  // set the output pins:
  pinMode (4, OUTPUT);						// Blue LED output
  pinMode (2, OUTPUT);						// Red LED output
  
  // Sets parameters
 
  steps = 30;
  startFrequency = 0.5;                         	  	// given in Hz
  endFrequency = 3;                            			// given in Hz
  ddFrequency = (startFrequency - endFrequency) / steps; 	// change in frequency with each blink
  dynamicFrequency = startFrequency;               		// dynamic frequency is updated after each blink
  
  pulseperMinute = 60000 / (1000 / dynamicFrequency);  		// given in pulses per minute
  restInterval = 60000 / pulseperMinute;        		// delay in milliseconds
  pulseLength = 100;                            		// given in milliseconds
  
}

/* Main control loop */

void loop()
{

      // creates variables for use with serial communication 
      char character;
      String serialIn = "";

      // read strings from serial
      while(Serial.available()) 
      {
        // Read character by character
        character = Serial.read();
    
        // Add each new character to the string
        serialIn.concat(character);
    
        // Debouncing such that an entire string will be read together
        delay(10);
       }

      // Start ramp code if "Start" is send via serial 
      if (serialIn.equalsIgnoreCase("Start"))
      {
          Serial.println("Starting Ramp Protocol");

          // 5s delay between turning on the red LED and the start of the stimulation
          startSync = millis();
          delay(1000);
          digitalWrite(2, HIGH);
          while ((millis()-startSync) < 5000);
            
          // Set initial frequency to the start frequency
          dynamicFrequency = startFrequency;
          
          // Start of ramp
          for(int i=0; i < steps; i++)
          {
            start = millis();
            pulseperMinute = 60000 / (1000 / dynamicFrequency);  	// Updates pulses per minute
            restInterval = 60000 / pulseperMinute;        		// Updates delay in milliseconds
    
    	      // We are using channel 4 for the LED
            digitalWrite (4, HIGH);        				// Turns on blue LED
            while ((millis()-start) < pulseLength);  		// Leaves the blue LED on for desired pulse length
          
            digitalWrite (4, LOW);            			// Turns off the blue LED
            while ((millis()-start) < restInterval); 		// Leaves the blue LED off
            dynamicFrequency = dynamicFrequency - ddFrequency;	// Updates the dynamic frequency
          }
          
          digitalWrite(2, LOW);					// Turns off the red LED when finished

        }


}
