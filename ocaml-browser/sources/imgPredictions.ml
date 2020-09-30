(* CastANet browser - imgPredictions.ml *)

open Printf
open Morelib


module Aux = struct
    let line_to_assoc r c t =
        String.split_on_char '\t' t
        |> List.map Float.of_string
        |> (fun t -> (r, c), t)

    let of_string data =
        let raw = List.map 
            (fun s ->
                Scanf.sscanf s "%d\t%d\t%[^\n]" line_to_assoc
            ) (List.tl (String.split_on_char '\n' (String.trim data))) in
        let nr = List.fold_left (fun m ((r, _), _) -> max m r) 0 raw + 1
        and nc = List.fold_left (fun m ((_, c), _) -> max m c) 0 raw + 1 in
        let table = Matrix.init nr nc (fun ~r:_ ~c:_ -> []) in  
        List.iter (fun ((r, c), t) -> table.(r).(c) <- t) raw;
        table

    let to_string level table =
        let buf = Buffer.create 100 in
        (* TODO: improve this! *)
        let header = CLevel.to_header level
            |> List.map (String.make 1)
            |> String.concat "\t" in
        bprintf buf "row\tcol\t%s\n" header;
        Matrix.iteri (fun ~r ~c t ->
            List.map Float.to_string t
            |> String.concat "\t"
            |> bprintf buf "%d\t%d\t%s\n" r c
        ) table;
        Buffer.contents buf
end


class predictions input = object (self)

    val mutable curr : string option = 
        match input with
        | [] -> None (* TODO: Find a better solution to this! *)
        | (id, _) :: _ -> Some id

    method current = curr
    method set_current x = curr <- Some x

    method private current_data = Option.map (fun x -> List.assoc x input) curr
    method private table = Option.map (fun (_, y) -> y) self#current_data
    method private level = Option.map (fun (x, _) -> x) self#current_data

    method get ~r ~c = 
        match self#table with
        | None -> None
        | Some t -> Matrix.get_opt t ~r ~c

    method max_layer ~r ~c =
        match self#current_data with
        | None -> None
        | Some (level, table) ->
            Option.map (fun preds ->
                fst @@ List.fold_left2 (fun ((_, x) as z) y chr ->
                    if y > x then (chr, y) else z
                ) ('0', 0.0) preds (CLevel.to_header level)
            ) (Matrix.get_opt table ~r ~c)

    method iter f =
        match self#table with
        | None -> ()
        | Some matrix -> Matrix.iteri f matrix

    method to_string () = 
        match self#current_data with
        | None -> "" (* TODO: Find a better solution to this! *)
        | Some (level, table) -> Aux.to_string level table

end


let filter entries =
    List.filter (fun {Zip.filename; _} ->
        Filename.dirname filename = "predictions"
    ) entries

let level_of_filename s =
    String.split_on_char '.' s
    |> List.rev
    |> List.hd
    |> CLevel.of_string


let create ?zip source =
    match zip with
    | None -> new predictions []
    | Some ich -> let entries = Zip.entries ich in
        let assoc =
            List.map (fun ({Zip.filename; _} as entry) ->
                let level = level_of_filename filename in
                let matrix = Aux.of_string (Zip.read_entry ich entry)
                and id = Filename.(basename (chop_extension filename)) in
                id, (level, matrix)
            ) (filter entries)
        in new predictions assoc
