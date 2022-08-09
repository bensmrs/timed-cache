(** This timed cache is just a wrapper around {!Hashtbl}. Its interface is almost compatible.
    See {!Hashtbl} documentation for more details. *)

type ('a, 'b) t

(** Create a timed cache, where a SIGALRM check will happen every [check_every] seconds to remove
    keys older than [expire_after] seconds. *)
val create : check_every:int -> expire_after:int -> ?random:bool -> int -> ('a, 'b) t

val clear : ('a, 'b) t -> unit
val reset : ('a, 'b) t -> unit
val copy : ('a, 'b) t -> ('a, 'b) t
val add : ('a, 'b) t -> 'a -> 'b -> unit
val remove : ('a, 'b) t -> 'a -> unit
val find : ('a, 'b) t -> 'a -> 'b
val find_opt : ('a, 'b) t -> 'a -> 'b option
val find_all : ('a, 'b) t -> 'a -> 'b list
val replace : ('a, 'b) t -> 'a -> 'b -> unit
val mem : ('a, 'b) t -> 'a -> bool
val iter : ('a -> 'b -> unit) -> ('a, 'b) t -> unit
val filter_map_inplace : ('a -> 'b -> 'b option) -> ('a, 'b) t -> unit
val fold : ('a -> 'b -> 'c -> 'c) -> ('a, 'b) t -> 'c -> 'c
val length : ('a, 'b) t -> int
val stats : ('a, 'b) t -> Hashtbl.statistics
val to_seq : ('a, 'b) t -> ('a * 'b) Seq.t
val to_seq_keys : ('a, 'b) t -> 'a Seq.t
val to_seq_values : ('a, 'b) t -> 'b Seq.t
val add_seq : ('a, 'b) t -> ('a * 'b) Seq.t -> unit
val replace_seq : ('a, 'b) t -> ('a * 'b) Seq.t -> unit

(** See {!Hashtbl.of_seq} and {!create} for more details *)
val of_seq : check_every:int -> expire_after:int -> ('a * 'b) Seq.t -> ('a, 'b) t

(** Wrap a unary function to cache its return values using a timed cache *)
val wrap : check_every:int -> expire_after:int -> ?random:bool -> ?initial_size:int -> ('a -> 'b) ->
           ?accept:('a -> 'b -> bool) -> 'a -> 'b

(** Wrap a function to cache its return values using a timed cache *)
val wrap' : check_every:int -> expire_after:int -> ?random:bool -> ?initial_size:int ->
            ('a -> 'b) -> transform:('a -> 'c) -> ?accept:('c -> 'b -> bool) -> 'a -> 'b

(** Wrap a unary function with an existing cache *)
val wrap_with : ('a, 'b) t -> ('a -> 'b) -> ?accept:('a -> 'b -> bool) -> 'a -> 'b

(** Wrap a function with an existing cache *)
val wrap_with' : ('a, 'b) t -> ('c -> 'b) -> transform:('c -> 'a) -> ?accept:('a -> 'b -> bool) ->
                 'c -> 'b
