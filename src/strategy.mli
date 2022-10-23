(** Expiration strategies for the timed cache *)


(** Key expiration strategy *)
module type STRATEGY = sig
  type metadata

  (** Action run at cache creation *)
  val at_create : ?check_every:int -> int -> (int -> unit) -> int option * int * metadata

  (** Action run before a read operation *)
  val before_read : int option * int * metadata -> (int -> unit) -> unit

  (** Post-processing after a read operation *)
  val after_read : int option * int * metadata -> 'a * float -> 'a option
end

(** Unix SIGALRM signal strategy *)
module Alarm : STRATEGY

(** Strategy to remove several keys synchronously before reading *)
module Synchronous : STRATEGY

(** Strategy to remove one key on demand after reading *)
module Lazy : STRATEGY
