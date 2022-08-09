type ('a, 'b) t = ('a, 'b * float) Hashtbl.t * int * int

let get_data (data, _) = data
let now = Unix.gettimeofday
let convert_seq_item (key, data) = (key, (data, now ()))

let refresh_item ~expire_after _ (_, t as item) =
  if int_of_float (now () -. t) >= expire_after then None else Some item

let refresh (h, check_every, expire_after) _ = 
  ignore (Unix.alarm check_every);
  Hashtbl.filter_map_inplace (refresh_item ~expire_after) h

let create ~check_every ~expire_after ?random initial_size =
  let hce = (Hashtbl.create ?random initial_size, check_every, expire_after) in
  ignore Sys.(signal sigalrm (Signal_handle (refresh hce)));
  ignore (Unix.alarm check_every);
  hce

let clear (h, _, _) = Hashtbl.clear h
let reset (h, _, _) = Hashtbl.reset h
let copy (h, c, e) = (Hashtbl.copy h, c, e)
let add (h, _, _) key data = Hashtbl.add h key (data, now ())
let remove (h, _, _) = Hashtbl.remove h
let find (h, _, _) key = Hashtbl.find h key |> get_data
let find_opt (h, _, _) key = Hashtbl.find_opt h key |> Option.map get_data
let find_all (h, _, _) key = Hashtbl.find_all h key |> List.map get_data
let replace (h, _, _) key data = Hashtbl.replace h key (data, now ())
let mem (h, _, _) = Hashtbl.mem h
let iter f (h, _, _) = Hashtbl.iter (fun key (data, _) -> f key data) h
let filter_map_inplace f (h, _, _) =
  Hashtbl.filter_map_inplace (fun key (data, t) -> f key data |> Option.map (fun data -> (data, t)))
                             h
let fold f (h, _, _) = Hashtbl.fold (fun key (data, _) -> f key data) h
let length (h, _, _) = Hashtbl.length h
let stats (h, _, _) = Hashtbl.stats h
let to_seq (h, _, _) = Hashtbl.to_seq h |> Seq.map (fun (key, (data, _)) -> (key, data))
let to_seq_keys (h, _, _) = Hashtbl.to_seq_keys h
let to_seq_values (h, _, _) = Hashtbl.to_seq_values h |> Seq.map get_data
let add_seq (h, _, _) i = Seq.map convert_seq_item i |> Hashtbl.add_seq h
let replace_seq (h, _, _) i = Seq.map convert_seq_item i |> Hashtbl.replace_seq h
let of_seq ~check_every ~expire_after i =
  let i' = Seq.map convert_seq_item i in
  (Hashtbl.of_seq i', check_every, expire_after)

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
