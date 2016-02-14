# servo
Servo control in OCaml for the Raspberry Pi 2 (BCM2836)

This program is written for and tested on the Raspberry Pi 2.
It should also work on the Raspberry Pi after changing the base address of the BCM2835 in the file bcm2835.ml,
but this is untested.

Calling `make` will compile the files and create the excutable `demo`.
This needs to be run as root to access /dev/mem to read and write to the Broadcom BCM2835 registers.

The Raspberry Pi 2 has four pins, which can be used to output pwm signals for servos.
Internally the BCM2835 only has two pwm channels, so only two independent pwm signals can be output concurrently.

The two pwm channels can be run at different frequencies simultaniously.

For advanced users: The two pwm channels share a clock divisor.
This divisor can be changed from the user interface on initialization of a servo/pwm pin.
Changing it for one pwm pin will effect the other pwm pin as this divisor is shared between the two channels.
A default value for the clock divisor is set which allows both pwm outputs to be run at frequencies in the range of
less than 50Hz to above 500Hz without changing this default clock divisor.
This should be sufficient for all common servos, including fast 560µs heli tail servos, running at 300, 333Hz or higher,
so a change of the common divisor should normally not be necessary.

Typical usage would look like this:

    let servo = Servo.make 12 in       (* create a servo running at the default 50Hz frequency connected to pin 12 *)
    begin
      Servo.goto servo (-1.);          (* let the servo go to a certain angle given in radians *)
      Time.delay_microseconds(500000); (* give the servo some time to move *)
      Servo.goto_relative servo 1.;    (* make a relative move from the last position *)
      Time.delay_microseconds(500000); (* give the servo some time to move *)
    end

The bcm pins 12, 13, 18 and 19 may be used. Pins 12 and 18 are on channel 0 and pins 13 and 19 on channel 1.
Bcm pin 12 is physical pin 32 on the header.
Bcm pin 13 is physical pin 33 on the header.
Bcm pin 18 is physical pin 12 on the header.
Bcm pin 19 is physical pin 35 on the header.

