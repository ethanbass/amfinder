(* CastANet - cTile.ml *)

open CExt
open Scanf
open Printf

type t = {
  mutable user : string;
  mutable lock : string;
  mutable hold : string;
}

type layer = [ `USER | `HOLD | `LOCK ]

let create () = { user = ""; lock = ""; hold = "" }

let to_string t = sprintf "%s %s %s" t.user t.lock t.hold

let of_string s = 
  let import s = sscanf s "%[A-Z] %[A-Z] %[A-Z]"
    (fun x y z -> {user = x; lock = y; hold = z})
  in try import s with _ -> invalid_arg s

let get t = function
  | `USER -> t.user
  | `LOCK -> t.lock
  | `HOLD -> t.hold

let apply f t = function
  | `USER -> (fun x -> t.user <- f t.user x)
  | `LOCK -> (fun x -> t.lock <- f t.lock x)
  | `HOLD -> (fun x -> t.hold <- f t.hold x)

let set = apply (fun _ x -> x)
let add = apply (fun x y -> EStringSet.union x (String.make 1 y))
let remove = apply (fun x y -> EStringSet.diff x (String.make 1 y))
