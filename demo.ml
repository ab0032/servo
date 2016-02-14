
let test_delay () = (
  (* test delay_microseconds *)
  print_string "delay 1 sec ...\n";
  Time.delay_microseconds(1000000);
  print_string "delay 0.1 sec ...\n";
  Time.delay_microseconds(100000);
  print_string "delay 110 microsec ...\n";
  Time.delay_microseconds(110);
  print_string "delay 10 microsec ...\n";
  Time.delay_microseconds(10);
  print_string "delay 2 microsec ...\n";
  Time.delay_microseconds(2);
  ()
)

let test_mmap () =
  let bcm2708_peri_base = 0x3F000000 in (* Pi 2 *)
  let pwm_base          = (bcm2708_peri_base + 0x0020C000) in
  let addr              = pwm_base in
  let len               = 4*1024 in     (* one page *)
  let offset            = 0x14/4 in     (* pwm data register, shouldn't hurt to write there *)

  (* mmap some memory *)
  let ptr = Mem_map32.mmap (Int32.of_int addr)  len in
  let _ = print_string ("return value of mmap: " ^ (string_of_int (Int32.to_int ptr)) ^ "\n") in

  (* do some reading and writing to it *)
  let a = Mem_map32.read ptr offset in
  let _ = print_string ("return value of read: " ^ (string_of_int (Int32.to_int a)) ^ "\n") in

  let _ = Mem_map32.write ptr offset (Int32.of_int 2) in


  let b = Mem_map32.read ptr offset in
  let _ = print_string ("return value of read (should be 2) : " ^ (string_of_int (Int32.to_int b)) ^ "\n") in

  let _ = Mem_map32.write ptr offset (Int32.of_int 3) in

  let c = Mem_map32.read ptr offset in
  let _ = print_string ("return value of read (should be 3) : " ^ (string_of_int (Int32.to_int c)) ^ "\n") in

  (* lets restore the original value *)
  let _ = Mem_map32.write ptr offset a in
  let _ = print_string ("restored original value\n") in
  ()

open Servo ;;

let test_servo () =

  (* use bcm pins 12 and 13 for demo *)
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
(*
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
*)
  end
;;


open Bcm2835 ;;

let test_bcm () = (
  (*
  default freq = 50Hz
  1st : gpio -g mode 12 pwm # turn pin 12 into pwm mode
  2nd : gpio pwm-ms
  3rd : gpio pwmc 1920      # set clock devisor
  4th : gpio pwmr 200       # set range; 0.1 ms per unit
  5th : gpio -g pwm 12 15   # when div=192 range=200 or 150 
  or
  gpio pwmc 192             # our default clk divisor
  gpio pwmr 2000            # 0.01 ms per unit; our default range
  gpio -g pwm 12 150        # bigger range has more resolution and requires larger numbers
  *)
  let pin12 = Pin.of_int 12 in 
  let _ = print_string "Pwm.init_pin to set the clock divisor\n" in
  let _ = init_pin pin12 in
  let _ = print_string "getting clock divisor...\n" in
  let div_orig = Clock.get_divisor () in
  let _ = print_string ("got clock divisor: " ^ (string_of_int div_orig) ^ "\n") in
  let div_new = 2 * div_orig in
  let _ = print_string ("setting clock divisor to " ^ (string_of_int div_new) ^ "\n") in
  let _ = Clock.set_divisor div_new in (* set clock divisor *)
  let _ = print_string "getting clock divisor...\n"  in
  let div = Clock.get_divisor () in
  let _ = print_string ("got clock divisor: " ^ (string_of_int div) ^ "\n") in
  let _ = if (div == div_new) then
    print_string "Clock.set_divisor working\n"
  else
    print_string "ERROR: Clock.set_divisor broken\n"
  in
  (* before going into further tests, set clock divisor to proper value *)
  let _ = print_string "restore clock divisor\n" in
  let _ = Clock.set_divisor div_orig in (* set clock divisor *)

  let pin12 = Pin.of_int 12 in 
  let _ = print_string "Pwm.init_pin\n" in
  let _ = init_pin pin12 in
  let _ = print_string "getting range for pin 12...\n"  in
  let range0 = Pwm.get_pwm_range pin12 in
  let _ = print_string ("got range0: " ^ (string_of_int range0) ^ "\n") in

  let pin13 = Pin.of_int 13 in 
  let _ = print_string "before Pwm.init_pin\n" in
  let _ = init_pin pin13 in
  let _ = set_frequency pin13 60 in (* setting second pin to 60Hz *)
  let _ = print_string "getting range for pin 13...\n"  in
  let range1 = Pwm.get_pwm_range pin13 in
  let _ = print_string ("got range1: " ^ (string_of_int range1) ^ "\n") in

  let _ = print_string "getting pwm chan0 range...\n"  in
  let range0 = Pwm.get_pwm_range (Pin.of_int 12) in
  let _ = print_string ("got pwm chan0 range: " ^  (string_of_int range0) ^ "\n") in

  let _ = print_string "getting pwm chan1 range...\n"  in
  let range1 = Pwm.get_pwm_range (Pin.of_int 13) in
  let _ = print_string ("got pwm chan1 range1: " ^ (string_of_int range1) ^ "\n") in

  (* play around with pwm *)
  let _ = (
    for k = 1 to 10 do
      for i = 2 to 4 do (
        set_pulse_width pin12 ((float_of_int i) *. 0.5);
        (* Time.delay_microseconds(1000000); *)
        for j = 2 to 4 do (
          set_pulse_width pin13 ((float_of_int j) *. 0.5);
          Time.delay_microseconds(300000)
        ) done;
      ) done;
    done;
    ()
  ) in
  ()
)
;;

(*
test_delay () ;;
test_mmap () ;;
test_bcm () ;;
*)
test_servo () ;;
