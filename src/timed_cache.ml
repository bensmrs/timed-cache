(** This module provides a hashmap implementation with expiring values *)


open Util
module Strategy = Strategy


(** Add a timestamp to a sequence item *)
let convert_seq_item (key, data) = (key, (data, now ()))


(** Refresh a single item *)
let refresh_item ~expire_after _ (_, t as item) =
  if int_of_float (now () -. t) >= expire_after then None else Some item


(** Refresh a whole hashmap *)
let refresh h expire_after = 
  Hashtbl.filter_map_inplace (refresh_item ~expire_after) h


module type CACHE = sig
  type ('a, 'b) t
  val create : ?check_every:int -> expire_after:int -> ?random:bool -> int -> ('a, 'b) t
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
  val of_seq : ?check_every:int -> expire_after:int -> ('a * 'b) Seq.t -> ('a, 'b) t
  val wrap : check_every:int -> expire_after:int -> ?random:bool -> ?initial_size:int ->
             ('a -> 'b) -> ?accept:('a -> 'b -> bool) -> 'a -> 'b
  val wrap' : check_every:int -> expire_after:int -> ?random:bool -> ?initial_size:int ->
              ('a -> 'b) -> transform:('a -> 'c) -> ?accept:('c -> 'b -> bool) -> 'a -> 'b
  val wrap_with : ('a, 'b) t -> ('a -> 'b) -> ?accept:('a -> 'b -> bool) -> 'a -> 'b
  val wrap_with' : ('a, 'b) t -> ('c -> 'b) -> transform:('c -> 'a) -> ?accept:('a -> 'b -> bool) ->
                   'c -> 'b
end

module Make (S : Strategy.STRATEGY) : CACHE = struct
  type ('a, 'b) t = ('a, 'b * float) Hashtbl.t * (int option * int * S.metadata)

  let create ?check_every ~expire_after ?random initial_size =
    let h = Hashtbl.create ?random initial_size in
    let metadata = S.at_create ?check_every expire_after (refresh h) in
    (h, metadata)

  let rec remove_all h key = if Hashtbl.mem h key then (Hashtbl.remove h key; remove_all h key)

  let clear (h, _) = Hashtbl.clear h

  let reset (h, _) = Hashtbl.reset h

  let copy (h, (check_every, expire_after, _)) =
    let h' = Hashtbl.copy h in
    (h', S.at_create ?check_every expire_after (refresh h'))

  let add (h, _) key data = Hashtbl.add h key (data, now ())

  let remove (h, _) = Hashtbl.remove h

  let find (h, metadata) key =
    S.before_read metadata (refresh h);
    try Hashtbl.find h key |> S.after_read metadata |> Option.get with
    | Invalid_argument _ -> remove_all h key; raise Not_found

  let find_opt (h, metadata) key =
    S.before_read metadata (refresh h);
    let o = Hashtbl.find_opt h key in
    Option.bind o (fun v -> match S.after_read metadata v with
      | None -> remove_all h key; None
      | data -> data)

  let find_all (h, metadata) key =
    S.before_read metadata (refresh h);
    try Hashtbl.find_all h key |> List.map (fun v -> S.after_read metadata v |> Option.get) with
    | Invalid_argument _ -> remove_all h key; []

  let replace (h, _) key data = Hashtbl.replace h key (data, now ())

  let mem hm key = find_opt hm key |> Option.is_some

  let iter f (h, (_, expire_after, _)) =
    refresh h expire_after;
    Hashtbl.iter (fun key (data, _) -> f key data) h

  let filter_map_inplace f (h, (_, expire_after, _)) =
    refresh h expire_after;
    Hashtbl.filter_map_inplace (fun key (data, t) -> f key data
                                                     |> Option.map (fun data -> (data, t))) h

  let fold f (h, (_, expire_after, _)) =
    refresh h expire_after;
    Hashtbl.fold (fun key (data, _) -> f key data) h

  let length (h, (_, expire_after, _)) =
    refresh h expire_after;
    Hashtbl.length h

  let stats (h, (_, expire_after, _)) =
    refresh h expire_after;
    Hashtbl.stats h

  let to_seq (h, (_, expire_after, _)) =
    refresh h expire_after;
    Hashtbl.to_seq h |> Seq.map (fun (key, (data, _)) -> (key, data))

  let to_seq_keys (h, (_, expire_after, _)) =
    refresh h expire_after;
    Hashtbl.to_seq_keys h

  let to_seq_values (h, (_, expire_after, _)) =
    refresh h expire_after;
    Hashtbl.to_seq_values h |> Seq.map (fun (value, _) -> value)

  let add_seq (h, _) i = Seq.map convert_seq_item i |> Hashtbl.add_seq h

  let replace_seq (h, _) i = Seq.map convert_seq_item i |> Hashtbl.replace_seq h

  let of_seq ?check_every ~expire_after i =
    let i' = Seq.map convert_seq_item i in
    let h = Hashtbl.of_seq i' in
    (h, S.at_create ?check_every expire_after (refresh h))

  let wrap_with' c f ~transform ?(accept=fun _ _ -> true) key =
    let key' = transform key in
    match find_opt c key' with
    | Some data -> data
    | None -> let data = f key in if accept key' data then add c key' data; data

  let wrap_with c f = wrap_with' c f ~transform:(fun x -> x)

  let wrap' ~check_every ~expire_after ?random ?(initial_size=32) =
    wrap_with' (create ~check_every ~expire_after ?random initial_size)

  let wrap ~check_every ~expire_after ?random ?(initial_size=32)=
    wrap_with (create ~check_every ~expire_after ?random initial_size)
end
