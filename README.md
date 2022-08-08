# `timed-cache`

`timed-cache` is a package to implement timed caches. This is not a LRU or a FIFO cache! The number of elements is not limited and the only automatic deletion mechanism is based on a clock, more precisely on SIGALRM signals. For the moment, only one timed cache per process is allowed. Its signature is almost compatible with `Hashtbl`.

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
let c = Timed_cache.create ~check_every:10 ~expire_after:60 10 in
Timed_cache.add c 10 20;
(* a slow function *)
Timed_cache.add c 20 30;
(* ... *)
```

### As a function cache

Let us suppose now that we want to fetch information from a slow backend. We could cache the data using a LRU cache, but we want to guarantee that our local information is not too old. We could wrap a function calling this backend with the following code:

```ocaml
let fetch data = (* slow function *)
let fetch' = Timed_cache.wrap ~check_every:10 ~expire_after:60 fetch
```

Because only one timed cache can exist per process, only one function can safely be wrapped.