(* CastANet - cIcon.ml *)

type style = [
    | `RGBA
    | `RGBA_LOCKED
    | `GREY
    | `GREY_LOCKED
]

type size = [
    | `SMALL
    | `LARGE
]

type palette = [
    | `CIVIDIS 
    | `VIRIDIS 
    | `PLASMA
]

(* Icon sources. Load icons as pixbufs of 24 (small) or 48 (large) pixels. *)
module Source = struct
  let pixbuf n (c, s) = (c, GdkPixbuf.from_file_at_size ~width:n ~height:n s)
  let pixbuf_list n = List.map (pixbuf n)
  let import f s = f (if s = `SMALL then 24 else 48)
  let load = import pixbuf
  let load_multiple = import pixbuf_list
end

module type IconSet = sig
  val large : (char * GdkPixbuf.pixbuf) list
  val small : (char * GdkPixbuf.pixbuf) list
end

(* Icon set builder. Retrieve paths to icon files and load all icon flavours. *)
module Build = struct
  let path_list suf =
    let make_pair chr = Printf.sprintf "%c_%s.png" chr suf
      |> Filename.concat "data/icons"
      |> (fun path -> chr, path)
    in List.map make_pair CAnnot.all_chars_list
  let icon_set suf =
    let names = path_list suf in
    let module M = struct
      let large = Source.load_multiple `LARGE names
      let small = Source.load_multiple `SMALL names
    end in (module M : IconSet)
end

let m_rgba = Build.icon_set "rgba"
let m_rgba_lock = Build.icon_set "hold"
let m_grey = Build.icon_set "grey"
let m_grey_lock = Build.icon_set "lock"

module Palette = struct
  let pixbuf n s = 
    let path = Filename.concat "data/icons" s in
  GdkPixbuf.from_file_at_size ~width:n ~height:n path
  let import f s = f (if s = `SMALL then 20 else 48)
  let load = import pixbuf
  let cividis = load `SMALL "cividis.png", load `LARGE "cividis.png"
  let viridis = load `SMALL "viridis.png", load `LARGE "viridis.png"
  let plasma = load `SMALL "plasma.png", load `LARGE "plasma.png"
  let get_func = function `SMALL -> fst | `LARGE -> snd
end

let get_palette = function
  | `CIVIDIS -> Palette.(fun sz -> get_func sz cividis)
  | `VIRIDIS -> Palette.(fun sz -> get_func sz viridis)
  | `PLASMA  -> Palette.(fun sz -> get_func sz plasma)

(* Joker icon for display any annotation (irrespective of their type). *)
module Joker = struct
  let make suf =
    let ico = Printf.sprintf "Joker_%s.png" suf
      |> Filename.concat "data/icons"
      |> (fun path -> '*', path)
    in Source.(snd (load `SMALL ico), snd (load `LARGE ico))
  (* There are no constraints on the joker icon (no _lock variants). *)
  let rgba = make "rgba"
  let grey = make "grey"
end

let get_joker sty sz =
  let select = match sz with 
    |`SMALL -> fst 
    | `LARGE -> snd in
  match sty with
  | `RGBA -> select Joker.rgba
  | `GREY -> select Joker.grey
  |   _   -> invalid_arg "AmfIcon.get_joker" 



let get_standard chr sty sz =

    let set = match sty with
        | `RGBA -> m_rgba
        | `GREY -> m_grey
        | `RGBA_LOCKED -> m_rgba_lock
        | `GREY_LOCKED -> m_grey_lock
    in

    let open (val set : IconSet) in

    match sz with
    | `SMALL -> List.assoc chr small 
    | `LARGE -> List.assoc chr large



let get = function
  | '*' -> get_joker
  | chr -> get_standard chr
