(** This module tests the package with Alcotest *)

open Alcotest

module TC1 = Timed_cache.Make(Timed_cache.Strategy.Alarm)
module TC2 = Timed_cache.Make(Timed_cache.Strategy.Synchronous)
module TC3 = Timed_cache.Make(Timed_cache.Strategy.Lazy)

(** Two checks for value expiration *)
let test_single_expiration () =
  let cache2 = TC2.create ~check_every:1 ~expire_after:2 1 in
  let cache3 = TC3.create ~check_every:1 ~expire_after:2 1 in
  TC2.add cache2 0 1;
  TC3.add cache3 0 1;
  check (option int) "value present" (Some 1) (TC2.find_opt cache2 0);
  check (option int) "value present" (Some 1) (TC3.find_opt cache3 0);
  Unix.sleep 3;
  check (option int) "value absent" (None) (TC2.find_opt cache2 0);
  check (option int) "value absent" (None) (TC3.find_opt cache3 0)

let test_expiration () =
  let cache1 = TC1.create ~check_every:1 ~expire_after:5 3 in
  let cache2 = TC2.create ~check_every:1 ~expire_after:5 3 in
  let cache3 = TC3.create ~check_every:1 ~expire_after:5 3 in
  check (option int) "value absent" (None) (TC1.find_opt cache1 0);
  check (option int) "value absent" (None) (TC2.find_opt cache2 0);
  check (option int) "value absent" (None) (TC3.find_opt cache3 0);
  check (option int) "value absent" (None) (TC1.find_opt cache1 1);
  check (option int) "value absent" (None) (TC2.find_opt cache2 1);
  check (option int) "value absent" (None) (TC3.find_opt cache3 1);
  check (option int) "value absent" (None) (TC1.find_opt cache1 2);
  check (option int) "value absent" (None) (TC2.find_opt cache2 2);
  check (option int) "value absent" (None) (TC3.find_opt cache3 2);
  TC1.add cache1 0 1;
  TC2.add cache2 0 1;
  TC3.add cache3 0 1;
  check (option int) "value present" (Some 1) (TC1.find_opt cache1 0);
  check (option int) "value present" (Some 1) (TC2.find_opt cache2 0);
  check (option int) "value present" (Some 1) (TC3.find_opt cache3 0);
  check (option int) "value absent" (None) (TC1.find_opt cache1 1);
  check (option int) "value absent" (None) (TC2.find_opt cache2 1);
  check (option int) "value absent" (None) (TC3.find_opt cache3 1);
  check (option int) "value absent" (None) (TC1.find_opt cache1 2);
  check (option int) "value absent" (None) (TC2.find_opt cache2 2);
  check (option int) "value absent" (None) (TC3.find_opt cache3 2);
  Unix.sleep 2;
  TC1.add cache1 1 2;
  TC2.add cache2 1 2;
  TC3.add cache3 1 2;
  check (option int) "value present" (Some 1) (TC1.find_opt cache1 0);
  check (option int) "value present" (Some 1) (TC2.find_opt cache2 0);
  check (option int) "value present" (Some 1) (TC3.find_opt cache3 0);
  check (option int) "value present" (Some 2) (TC1.find_opt cache1 1);
  check (option int) "value present" (Some 2) (TC2.find_opt cache2 1);
  check (option int) "value present" (Some 2) (TC3.find_opt cache3 1);
  check (option int) "value absent" (None) (TC1.find_opt cache1 2);
  check (option int) "value absent" (None) (TC2.find_opt cache2 2);
  check (option int) "value absent" (None) (TC3.find_opt cache3 2);
  Unix.sleep 2;
  TC1.add cache1 2 3;
  TC2.add cache2 2 3;
  TC3.add cache3 2 3;
  check (option int) "value present" (Some 1) (TC1.find_opt cache1 0);
  check (option int) "value present" (Some 1) (TC2.find_opt cache2 0);
  check (option int) "value present" (Some 1) (TC3.find_opt cache3 0);
  check (option int) "value present" (Some 2) (TC1.find_opt cache1 1);
  check (option int) "value present" (Some 2) (TC2.find_opt cache2 1);
  check (option int) "value present" (Some 2) (TC3.find_opt cache3 1);
  check (option int) "value present" (Some 3) (TC1.find_opt cache1 2);
  check (option int) "value present" (Some 3) (TC2.find_opt cache2 2);
  check (option int) "value present" (Some 3) (TC3.find_opt cache3 2);
  Unix.sleep 2;
  check (option int) "value absent" (None) (TC1.find_opt cache1 0);
  check (option int) "value absent" (None) (TC2.find_opt cache2 0);
  check (option int) "value absent" (None) (TC3.find_opt cache3 0);
  check (option int) "value present" (Some 2) (TC1.find_opt cache1 1);
  check (option int) "value present" (Some 2) (TC2.find_opt cache2 1);
  check (option int) "value present" (Some 2) (TC3.find_opt cache3 1);
  check (option int) "value present" (Some 3) (TC1.find_opt cache1 2);
  check (option int) "value present" (Some 3) (TC2.find_opt cache2 2);
  check (option int) "value present" (Some 3) (TC3.find_opt cache3 2);
  Unix.sleep 2;
  check (option int) "value absent" (None) (TC1.find_opt cache1 0);
  check (option int) "value absent" (None) (TC2.find_opt cache2 0);
  check (option int) "value absent" (None) (TC3.find_opt cache3 0);
  check (option int) "value absent" (None) (TC1.find_opt cache1 1);
  check (option int) "value absent" (None) (TC2.find_opt cache2 1);
  check (option int) "value absent" (None) (TC3.find_opt cache3 1);
  check (option int) "value present" (Some 3) (TC1.find_opt cache1 2);
  check (option int) "value present" (Some 3) (TC2.find_opt cache2 2);
  check (option int) "value present" (Some 3) (TC3.find_opt cache3 2);
  Unix.sleep 2;
  check (option int) "value absent" (None) (TC1.find_opt cache1 0);
  check (option int) "value absent" (None) (TC2.find_opt cache2 0);
  check (option int) "value absent" (None) (TC3.find_opt cache3 0);
  check (option int) "value absent" (None) (TC1.find_opt cache1 1);
  check (option int) "value absent" (None) (TC2.find_opt cache2 1);
  check (option int) "value absent" (None) (TC3.find_opt cache3 1);
  check (option int) "value absent" (None) (TC1.find_opt cache1 2);
  check (option int) "value absent" (None) (TC2.find_opt cache2 2);
  check (option int) "value absent" (None) (TC3.find_opt cache3 2)

(** A check for wrapped functions *)
let test_wrap () =
  let f x = x + 10 in
  let cache2 = TC2.create ~check_every:1 ~expire_after:5 3 in
  let cache3 = TC3.create ~check_every:1 ~expire_after:5 3 in
  let g2 = TC2.wrap_with cache2 ~accept:(fun i _ -> i <> 3) f in
  let g3 = TC3.wrap_with cache3 ~accept:(fun i _ -> i <> 3) f in
  check (option int) "value absent" (None) (TC2.find_opt cache2 0);
  check (option int) "value absent" (None) (TC3.find_opt cache3 0);
  check (option int) "value absent" (None) (TC2.find_opt cache2 1);
  check (option int) "value absent" (None) (TC3.find_opt cache3 1);
  check (option int) "value absent" (None) (TC2.find_opt cache2 2);
  check (option int) "value absent" (None) (TC3.find_opt cache3 2);
  check int "coherent wrapped result" (f 0) (g2 0);
  check int "coherent wrapped result" (f 0) (g3 0);
  check (option int) "value present" (Some 10) (TC2.find_opt cache2 0);
  check (option int) "value present" (Some 10) (TC3.find_opt cache3 0);
  check (option int) "value absent" (None) (TC2.find_opt cache2 1);
  check (option int) "value absent" (None) (TC3.find_opt cache3 1);
  check (option int) "value absent" (None) (TC2.find_opt cache2 2);
  check (option int) "value absent" (None) (TC3.find_opt cache3 2);
  Unix.sleep 2;
  check int "coherent wrapped result" (f 1) (g2 1);
  check int "coherent wrapped result" (f 1) (g3 1);
  check (option int) "value present" (Some 10) (TC2.find_opt cache2 0);
  check (option int) "value present" (Some 10) (TC3.find_opt cache3 0);
  check (option int) "value present" (Some 11) (TC2.find_opt cache2 1);
  check (option int) "value present" (Some 11) (TC3.find_opt cache3 1);
  check (option int) "value absent" (None) (TC2.find_opt cache2 2);
  check (option int) "value absent" (None) (TC3.find_opt cache3 2);
  Unix.sleep 2;
  check int "coherent wrapped result" (f 2) (g2 2);
  check int "coherent wrapped result" (f 2) (g3 2);
  check (option int) "value present" (Some 10) (TC2.find_opt cache2 0);
  check (option int) "value present" (Some 10) (TC3.find_opt cache3 0);
  check (option int) "value present" (Some 11) (TC2.find_opt cache2 1);
  check (option int) "value present" (Some 11) (TC3.find_opt cache3 1);
  check (option int) "value present" (Some 12) (TC2.find_opt cache2 2);
  check (option int) "value present" (Some 12) (TC3.find_opt cache3 2);
  check int "coherent wrapped result" (f 0) (g2 0);
  check int "coherent wrapped result" (f 0) (g3 0);
  check int "coherent wrapped result" (f 1) (g2 1);
  check int "coherent wrapped result" (f 1) (g3 1);
  check int "coherent wrapped result" (f 2) (g2 2);
  check int "coherent wrapped result" (f 2) (g3 2);
  check (option int) "value present" (Some 10) (TC2.find_opt cache2 0);
  check (option int) "value present" (Some 10) (TC3.find_opt cache3 0);
  check (option int) "value present" (Some 11) (TC2.find_opt cache2 1);
  check (option int) "value present" (Some 11) (TC3.find_opt cache3 1);
  check (option int) "value present" (Some 12) (TC2.find_opt cache2 2);
  check (option int) "value present" (Some 12) (TC3.find_opt cache3 2);
  check int "coherent wrapped result" (f 3) (g2 3);
  check int "coherent wrapped result" (f 3) (g3 3);
  check (option int) "value absent" (None) (TC2.find_opt cache2 3);
  check (option int) "value absent" (None) (TC3.find_opt cache3 3);
  Unix.sleep 2;
  check (option int) "value absent" (None) (TC2.find_opt cache2 0);
  check (option int) "value absent" (None) (TC3.find_opt cache3 0);
  check (option int) "value present" (Some 11) (TC2.find_opt cache2 1);
  check (option int) "value present" (Some 11) (TC3.find_opt cache3 1);
  check (option int) "value present" (Some 12) (TC2.find_opt cache2 2);
  check (option int) "value present" (Some 12) (TC3.find_opt cache3 2);
  Unix.sleep 2;
  check (option int) "value absent" (None) (TC2.find_opt cache2 0);
  check (option int) "value absent" (None) (TC3.find_opt cache3 0);
  check (option int) "value absent" (None) (TC2.find_opt cache2 1);
  check (option int) "value absent" (None) (TC3.find_opt cache3 1);
  check (option int) "value present" (Some 12) (TC2.find_opt cache2 2);
  check (option int) "value present" (Some 12) (TC3.find_opt cache3 2);
  Unix.sleep 2;
  check (option int) "value absent" (None) (TC2.find_opt cache2 0);
  check (option int) "value absent" (None) (TC3.find_opt cache3 0);
  check (option int) "value absent" (None) (TC2.find_opt cache2 1);
  check (option int) "value absent" (None) (TC3.find_opt cache3 1);
  check (option int) "value absent" (None) (TC2.find_opt cache2 2);
  check (option int) "value absent" (None) (TC3.find_opt cache3 2)

let tests = [
  ("test_single_expiration", `Quick, test_single_expiration);
  ("test_expiration", `Quick, test_expiration);
  ("test_wrap", `Quick, test_wrap)
]

let test_suites: unit test list = [
  "cache", tests;
]

(** Run the test suites *)
let () = run "timed-cache" test_suites
