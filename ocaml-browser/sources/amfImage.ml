(* CastANet - cImage.ml *)

open Printf

module Aux = struct
    let blank =
        let pix = GdkPixbuf.create ~width:180 ~height:180 () in
        GdkPixbuf.fill pix 0l;
        pix
end



class image path edge = 

    (* File settings. *)
    let file = ImgFile.create path in

    (* Source object. *)   
    let pixbuf = GdkPixbuf.from_file path in
    let source = ImgSource.create pixbuf edge in
    
    (* Drawing parameters. *)   
    let brush = ImgBrush.create source in
    let cursor = ImgCursor.create source brush
    and pointer = ImgPointer.create source brush in
    
    (* Image segmentation. *)   
    let small_tiles = ImgTileMatrix.create pixbuf source brush#edge
    and large_tiles = ImgTileMatrix.create pixbuf source 180 in

    (* Annotations, predictions and activations. *)
    let annotations, predictions, activations = 
        let zip = match Sys.file_exists file#archive with
            | true  -> Some (Zip.open_in file#archive)
            | false -> None in
        let annotations = ImgAnnotations.create ?zip source
        and predictions = ImgPredictions.create ?zip source
        and activations = ImgActivations.create ?zip source in
        Option.iter Zip.close_in zip;
        (annotations, predictions, activations) in

object (self)

    val draw = ImgDraw.create 
        small_tiles
        brush
        cursor
        annotations
        predictions

    val ui = ImgUI.create
        cursor
        annotations
        predictions

    val mutable exit_funcs = []

    initializer
        (* Cursor drawing functions. *)
        cursor#set_paint draw#cursor;
        cursor#set_paint (fun ?sync:_ ~r:_ ~c:_ -> self#magnified_view);
        cursor#set_erase self#draw_annotated_tile;
        cursor#set_erase brush#clear_margin;
        (* Pointer drawing functions. *)
        pointer#set_paint draw#pointer;
        pointer#set_erase self#draw_annotated_tile;
        annotations#current_level
        |> predictions#ids
        |> AmfUI.Predictions.set_choices

    method at_exit f = exit_funcs <- f :: exit_funcs

    method ui = ui
    method file = file
    method brush = brush
    method cursor = cursor
    method source = source
    method pointer = pointer
    method small_tiles = small_tiles
    method large_tiles = large_tiles
    method annotations = annotations
    method predictions = predictions

    method show_predictions () =
        let preds = AmfUI.Predictions.get_active () in
        predictions#set_current preds;
        self#mosaic ~sync:true ()

    method predictions_to_annotations ?(erase = false) () =
        assert predictions#active;
        let set_annot ~r ~c (chr, _) =
            let annot = annotations#get ~r ~c () in
            if annot#is_empty then annot#add chr
            else if erase then annot#set chr
        in predictions#iter (`MAX set_annot);
        (* Things below should be part of ui. *)
        AmfUI.Predictions.overlay#set_active false
    
    method update_statistics () = self#update_counters ()

    (* TODO: it should be possible to choose the folder! *)
    method screenshot () =
        let screenshot = AmfUI.Magnifier.screenshot () in
        let r, c = cursor#get in
        let filename = sprintf "AMF_screenshot_R%d_C%d.jpg" r c in
        AmfLog.info "Saving screenshot as %S" filename;
        GdkPixbuf.save ~filename ~typ:"jpeg" screenshot

    (* + self#magnified_view () and toggle buttons *)
    method private draw_annotated_tile ?(sync = false) ~r ~c () =
        draw#tile ~sync:false ~r ~c ();
        if pointer#at ~r ~c then brush#pointer ~sync:false ~r ~c ()
        else begin
            draw#overlay ~sync:false ~r ~c ();
            if cursor#at ~r ~c then brush#cursor ~sync:false ~r ~c ()
        end;
        if sync then brush#sync ()

    method private may_overlay_cam ~i ~j ~r ~c =
        if i = 1 && j = 1 && predictions#active && activations#active then (
             match predictions#current with
             | None -> large_tiles#get (* No active prediction set. *)
             | Some id -> match annotations#current_layer with
                | '*' -> (* let's find the top layer. *)
                    begin match predictions#max_layer ~r ~c with
                        | None -> large_tiles#get
                        | Some (max, _) -> activations#get id max
                    end
                | chr -> activations#get id chr
        ) else large_tiles#get

    method magnified_view () =
        let r, c = cursor#get in
        for i = 0 to 2 do
            for j = 0 to 2 do
                let ri = r + i - 1 and cj = c + j - 1 in
                let get = self#may_overlay_cam ~i ~j ~r:ri ~c:cj in            
                let pixbuf = match get ~r:ri ~c:cj with
                    | None -> Aux.blank
                    | Some x -> x
                in AmfUI.Magnifier.set_pixbuf ~r:i ~c:j pixbuf
            done
        done;
        ui#update ()

    method private update_counters () =
        let source =
            match predictions#active with
            | true  -> predictions#statistics
            | false -> annotations#statistics (annotations#current_level)
        in List.iter (fun (c, n) -> AmfUI.Layers.set_label c n) source

    method mosaic ?(sync = false) () =
        brush#background ~sync:false ();
        small_tiles#iter (fun ~r ~c pixbuf ->
            self#draw_annotated_tile ~sync:false ~r ~c ()
        );
        if predictions#active then brush#palette ();
        if sync then brush#sync ()

    method show () =
        self#mosaic ();
        self#magnified_view ();
        self#update_counters ()

    method save () =
        List.iter (fun f -> f ()) exit_funcs;
        let zip = file#archive in
        let och = Zip.open_out zip in
        annotations#dump och;
        predictions#dump och;
        activations#dump och;
        Zip.close_out och

end



let create ~edge path =
    if Sys.file_exists path then new image path edge
    else invalid_arg "AmfImage.load: File not found"
