# `timed-cache`

`timed-cache` is a package to implement timed caches. This is not a LRU or a FIFO cache! The number of elements in timed caches is not limited and a deletion strategy handles automatic key deletion. The signature of timed caches is almost compatible with `Hashtbl`.

Even though the timed cache implementation relies on `Hashtbl`, we strongly discourage you to add several bindings for a single key, as it will probably break the deletion logic.


## Strategies

Three deletion strategies are currently implemented:

### `Alarm`

This strategy relies on Unix `SIGALRM` signals to perform periodic key deletion. Only one such cache is allowed in a program, as mixing signals often leads to undesirable results. The (required) `check_every` parameter controls the alarm period; every `check_every` seconds, the keys older than `expire_after` are deleted. You should probably not use this strategy if your program blocks or already uses `SIGALRM` signals.

### `Synchronous`

This strategy perform mass deletion of old keys before some of the read operations. The (required) `check_every` parameter tells the stategy how much to wait between two mass deletions. Before a read operation happens, if the last mass deletion has not occurred in the last `check_every` seconds, the keys older than `expire_after` are deleted.

### `Lazy`

This strategy deletes old keys after they are read. The `check_every` parameter is forbidden here. After a read operation occurs, if the value read has been inserted before `expire_after` seconds ago, it is removed.


## Usage

### As a hashmap

Let us suppose that we have a piece of code using `Hashtbl`:

```ocaml
let h = Hashtbl.create 10 in
Hashtbl.add h 10 20;
(* a slow function *)
Hashtbl.add h 20 30;
(* ... *)
```

If we want the elements stored in `h` to expire after 60 seconds, with checks (almost) every 10 seconds, we can write:

```ocaml
module TC = Timed_cache.Make (Timed_cache.Strategy.Alarm)
let c = TC.create ~check_every:10 ~expire_after:60 10 in
Timed_cache.add c 10 20;
(* a slow function *)
Timed_cache.add c 20 30;
(* ... *)
```

### As a function cache

Let us suppose now that we want to fetch information from a slow backend. We could cache the data using a LRU cache, but we want to guarantee that our local information is not too old. We could wrap a function calling this backend with the following code:

```ocaml
module TC = Timed_cache.Make (Timed_cache.Strategy.Synchronous)
let fetch data = (* slow function *)
let fetch' = TC.wrap ~check_every:10 ~expire_after:60 fetch
```
