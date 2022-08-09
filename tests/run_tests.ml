(** This module tests the package with Alcotest *)

open Alcotest

(** Two checks for value expiration *)
let test_single_expiration () =
  let cache = Timed_cache.create ~check_every:1 ~expire_after:2 1 in
  Timed_cache.add cache 0 1;
  check (option int) "value present" (Some 1) (Timed_cache.find_opt cache 0);
  Unix.sleep 3;
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 0)

let test_expiration () =
  let cache = Timed_cache.create ~check_every:1 ~expire_after:5 3 in
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 0);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 1);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 2);
  Timed_cache.add cache 0 1;
  check (option int) "value present" (Some 1) (Timed_cache.find_opt cache 0);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 1);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 2);
  Unix.sleep 2;
  Timed_cache.add cache 1 2;
  check (option int) "value present" (Some 1) (Timed_cache.find_opt cache 0);
  check (option int) "value present" (Some 2) (Timed_cache.find_opt cache 1);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 2);
  Unix.sleep 2;
  Timed_cache.add cache 2 3;
  check (option int) "value present" (Some 1) (Timed_cache.find_opt cache 0);
  check (option int) "value present" (Some 2) (Timed_cache.find_opt cache 1);
  check (option int) "value present" (Some 3) (Timed_cache.find_opt cache 2);
  Unix.sleep 2;
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 0);
  check (option int) "value present" (Some 2) (Timed_cache.find_opt cache 1);
  check (option int) "value present" (Some 3) (Timed_cache.find_opt cache 2);
  Unix.sleep 2;
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 0);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 1);
  check (option int) "value present" (Some 3) (Timed_cache.find_opt cache 2);
  Unix.sleep 2;
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 0);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 1);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 2)

(** A check for wrapped functions *)
let test_wrap () =
  let f x = x + 10 in
  let cache = Timed_cache.create ~check_every:1 ~expire_after:5 3 in
  let g = Timed_cache.wrap_with cache ~accept:(fun i _ -> i <> 3) f in
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 0);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 1);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 2);
  check int "coherent wrapped result" (f 0) (g 0);
  check (option int) "value present" (Some 10) (Timed_cache.find_opt cache 0);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 1);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 2);
  Unix.sleep 2;
  check int "coherent wrapped result" (f 1) (g 1);
  check (option int) "value present" (Some 10) (Timed_cache.find_opt cache 0);
  check (option int) "value present" (Some 11) (Timed_cache.find_opt cache 1);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 2);
  Unix.sleep 2;
  check int "coherent wrapped result" (f 2) (g 2);
  check (option int) "value present" (Some 10) (Timed_cache.find_opt cache 0);
  check (option int) "value present" (Some 11) (Timed_cache.find_opt cache 1);
  check (option int) "value present" (Some 12) (Timed_cache.find_opt cache 2);
  check int "coherent wrapped result" (f 0) (g 0);
  check int "coherent wrapped result" (f 1) (g 1);
  check int "coherent wrapped result" (f 2) (g 2);
  check (option int) "value present" (Some 10) (Timed_cache.find_opt cache 0);
  check (option int) "value present" (Some 11) (Timed_cache.find_opt cache 1);
  check (option int) "value present" (Some 12) (Timed_cache.find_opt cache 2);
  check int "coherent wrapped result" (f 3) (g 3);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 3);
  Unix.sleep 2;
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 0);
  check (option int) "value present" (Some 11) (Timed_cache.find_opt cache 1);
  check (option int) "value present" (Some 12) (Timed_cache.find_opt cache 2);
  Unix.sleep 2;
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 0);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 1);
  check (option int) "value present" (Some 12) (Timed_cache.find_opt cache 2);
  Unix.sleep 2;
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 0);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 1);
  check (option int) "value absent" (None) (Timed_cache.find_opt cache 2)

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
