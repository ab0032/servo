
let bcm2708_peri_base = 0x3F000000 (* Pi 2 *)
let pwm_base          = (bcm2708_peri_base + 0x0020C000)
let addr              = pwm_base
let len               = 4*1024     (* one page *)
let offset            = 0x14/4     (* pwm data register, shouldn't hurt to write there *)

(* mmap some memory *)
let ptr = Mem_map32.mmap (Int32.of_int addr)  len ;;
let _ = print_string ("return value of mmap: " ^ (string_of_int (Int32.to_int ptr)) ^ "\n") ;;

(* do some reading and writing to it *)
let a = Mem_map32.read ptr offset ;;
let _ = print_string ("return value of read: " ^ (string_of_int (Int32.to_int a)) ^ "\n") ;;

let _ = Mem_map32.write ptr offset (Int32.of_int 2) ;;


let b = Mem_map32.read ptr offset ;;
let _ = print_string ("return value of read (should be 2) : " ^ (string_of_int (Int32.to_int b)) ^ "\n") ;;

let _ = Mem_map32.write ptr offset (Int32.of_int 3) ;;

let c = Mem_map32.read ptr offset ;;
let _ = print_string ("return value of read (should be 3) : " ^ (string_of_int (Int32.to_int c)) ^ "\n") ;;

(* lets restore the original value *)
let _ = Mem_map32.write ptr offset a ;;
let _ = print_string ("restored original value\n") ;;
