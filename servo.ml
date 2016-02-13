
exception Not_implemented of string

type servo = {
  pin              : Bcm2835.Pin.pin;
  frequency        : int;
  speed            : float;
  min_pulse_width  : float;
  max_pulse_width  : float;
  zero_pulse_width : float;
  min_angle        : float;
  max_angle        : float;
}

let make
      pin                        (* integer pin number to allocate and initialize *)
      ?(frequency = 50)          (* pwm frequency in Hz *)
      ?(speed = 0.3)             (* time it takes to turn 60 degrees in seconds *)
      ?(min_pulse_width = 0.5)   (* minimum allowed pulse width in ms *)
      ?(max_pulse_width = 2.5)   (* maximum allowed pulse width in ms *)
      ?(zero_pulse_width = 1.5)  (* pulse width for center position *)
      ?(min_angle = (-2.))         (* minimum possible angle in radians taken when min_pulse_width is used *)
                                 (* use +1 for min_angle if servo is not limited to 360 degrees *)
      ?(max_angle = 2.)         (* maximum possible angle in radians taken when max_pulse_width is applied *)
      ()                         (* use -1 for max_angle if servo is not limited to 360 degrees *)
                                 (* standard servos should be at 0 degree with a pulse length of 1.5 ms,
                                    at plus 90 degree with 2ms pulses and at minus 90 with 1ms *)
  =
    let pin = Bcm2835.Pin.of_int pin in
    let _ = Bcm2835.Pwm.init_pin pin in
    let _ = Bcm2835.set_frequency pin frequency in
    { pin; frequency; speed; min_pulse_width; max_pulse_width; zero_pulse_width; min_angle; max_angle; }

(* for internal use only *)
let angle_to_pulse_width servo angle =
  if angle < 0. then
    let slope = (servo.min_pulse_width -. servo.zero_pulse_width) /. servo.min_angle in
    servo.zero_pulse_width +. angle *. slope
  else (* angle > 0 *)
    let slope = (servo.max_pulse_width -. servo.zero_pulse_width) /. servo.max_angle in
    servo.zero_pulse_width +. angle *. slope

(* for internal use only *)
let angle_of_pulse_width servo pulse_width =
  if pulse_width < servo.zero_pulse_width then
    let slope = servo.min_angle /. (servo.min_pulse_width -. servo.zero_pulse_width) in
    (pulse_width -. servo.zero_pulse_width) *. slope
  else (* pulse_width > servo.zero_pulse_width *)
    let slope = servo.max_angle /. (servo.max_pulse_width -. servo.zero_pulse_width) in
    (pulse_width -. servo.zero_pulse_width) *. slope

(* find out where a servo really is, has the servo finished turning? *)
let get_position servo = (* this actually returns where it is going, not where it is right now *)
  let pw = Bcm2835.get_pulse_width servo.pin in
  angle_of_pulse_width servo pw

let goto servo angle =
  let pulse_width = angle_to_pulse_width servo angle in
  Bcm2835.set_pulse_width servo.pin pulse_width

(* current implementation is relative to the last command,
   not relative to current dynamic position if command is issued while moving *)
let goto_relative servo angle =
  let angle_now = get_position servo in
  goto servo (angle_now +. angle)

(* how fast is the servo currently moving? in rad per sec *)
let get_speed servo = raise (Not_implemented "get_speed")
  (* linear acceleration through motor? v=vo+t*a/2 *)

let get_eta servo = raise (Not_implemented "get_eta")
  (* do some math, estimate when the last command will be fullfilled if no new goto(angle) arrives *)

let tell_position angle = raise (Not_implemented "tell_position")
  (* tell the servo where it is to train/calibrate the servo to make better estimates about position, speed and eta *)


let test =
  let servo_top    = make 12 () in
  let servo_bottom = make 13 () in
  begin
    let div = Bcm2835.Clock.get_divisor () in
    print_string ("got clock divisor: " ^ (string_of_int div) ^ "\n");
    print_string ("center top servo and move it\n");
    let range0 = Bcm2835.Pwm.get_pwm_range servo_top.pin in
    print_string ("got range0: " ^ (string_of_int range0) ^ "\n");
    let freq = Bcm2835.get_frequency servo_top.pin in
    print_string ("got frequency[Hz] for top servo: " ^ (string_of_int freq) ^ "\n");
    let range1 = Bcm2835.Pwm.get_pwm_range servo_bottom.pin in
    print_string ("got range1: " ^ (string_of_int range1) ^ "\n");

    goto servo_top 0.;
    let pulse_width = Bcm2835.get_pulse_width servo_top.pin in
    print_string ("got pulse width[ms] for center position: " ^ (string_of_float pulse_width) ^ "\n");
    Time.delay_microseconds(500000);
    goto servo_top (-1.);
    let pulse_width = Bcm2835.get_pulse_width servo_top.pin in
    print_string ("got pulse width[ms] for -1 position: " ^ (string_of_float pulse_width) ^ "\n");
    Time.delay_microseconds(500000);
    goto servo_top 1.;
    let pulse_width = Bcm2835.get_pulse_width servo_top.pin in
    print_string ("got pulse width[ms] for 1 position: " ^ (string_of_float pulse_width) ^ "\n");
    Time.delay_microseconds(500000);
    goto_relative servo_top (-1.);

    goto servo_bottom 0.;
    Time.delay_microseconds(500000);
    goto servo_bottom (-1.);
    Time.delay_microseconds(500000);
    goto servo_bottom 1.;
    Time.delay_microseconds(500000);
    goto_relative servo_bottom (-1.);

    (* play around with pwm *)
(*
    for k = 0 to 10 do (
      for i = 0 to 1 do (
        let pos = 0.2 *. float_of_int (2 * i - 1) in
        goto servo_top pos;
        Time.delay_microseconds(40000);
        for j = 0 to 1 do (
          let pos = 0.5 *. float_of_int (2 * j - 1) in
          goto servo_bottom pos;
          Time.delay_microseconds(40000);
        ) done;
      ) done;
    ) done;
*)

    goto servo_top 0.;
    goto servo_bottom 0.;

    (* try to make laser go in a circle *)
    let range = 800 in
    let pulse = 20000 in
    let delay = 2 * pulse in
    for i = 0 to range do (
      let pos_x = 0.35 *. (cos (0.4 *. (float_of_int i))) in
      let pos_y = 0.2 *. (sin (0.4 *. (float_of_int i))) in
      goto servo_top pos_x;
      goto servo_bottom pos_y;
      Time.delay_microseconds(delay);
    ) done;
  end
