(** This module implements the timed cache expiration strategies *)


open Util


module type STRATEGY = sig
  type metadata
  val at_create : ?check_every:int -> int -> (int -> unit) -> int option * int * metadata
  val before_read : int option * int * metadata -> (int -> unit) -> unit
  val after_read : int option * int * metadata -> 'a * float -> 'a option
end


(** Require the [check_every] argument to be set *)
let require strategy = function
  | None -> raise (Invalid_argument (strategy ^ " requires `check_every' to be set"))
  | _ -> ()

(** Forbid the [check_every] argument to be set *)
let forbid strategy = function
  | None -> raise (Invalid_argument (strategy ^ " requires `check_every' to be unset"))
  | _ -> ()


module Alarm : STRATEGY = struct
  type metadata = unit

  let can_create = ref true

  let at_create ?check_every expire_after refresh =
    require "Clock" check_every;
    if !can_create then can_create := false else raise (Sys_error "Only one clock is allowed");
    let interval = Option.get check_every in
    let refresh_signal _ =
      ignore (Unix.alarm interval);
      refresh expire_after in
    ignore Sys.(signal sigalrm (Signal_handle refresh_signal));
    ignore (Unix.alarm interval);
    (check_every, expire_after, ())

  let before_read _ _ = ()

  let after_read _ (data, _) = Some data
end


module Synchronous : STRATEGY = struct
  type metadata = float ref

  let at_create ?check_every expire_after _ =
    require "Synchronous" check_every;
    (check_every, expire_after, ref (now ()))

  let before_read (check_every, expire_after, last_checkpoint) refresh =
    let checkpoint = now () in
    if int_of_float (checkpoint -. !last_checkpoint) >= (Option.get check_every) then
      (last_checkpoint := checkpoint; refresh expire_after)

  let after_read _ (data, _) = Some data
end


module Lazy : STRATEGY = struct
  type metadata = unit

  let at_create ?check_every expire_after _ =
    forbid "Lazy" check_every;
    (check_every, expire_after, ())

  let before_read _ _ = ()

  let after_read (_, expire_after, _) (data, t) =
    if int_of_float (now () -. t) >= expire_after then None
    else Some data
end
