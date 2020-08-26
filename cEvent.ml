(* CastANet - cEvent.ml *)

let update_annotations ev =
  begin try
    let key = Char.uppercase_ascii (GdkEvent.Key.string ev).[0] in
    if String.contains CAnnot.codes key then CGUI.Toggles.toggle_any key
  with _ -> () end;
  false

let icons () =
  CGUI.Layers.iter_radios (fun chr ->
    let callback () =
      let clr = match CGUI.Layers.is_active chr with
        | true  -> CDraw.active_layer (); `RGBA
        | false -> `GREY
      in CGUI.Layers.set_image chr (CIcon.get chr clr `SMALL)
    in ignore (CGUI.Layers.set_toggled chr callback)
  );
  CDraw.active_layer ();
  CGUI.Toggles.iter (fun _ chr btn img ->
    let rgba = CIcon.get chr `RGBA `LARGE
    and grey = CIcon.get chr `GREY `LARGE in
    let callback () = img#set_pixbuf (if btn#active then rgba else grey) in
    ignore (btn#connect#toggled ~callback)
  )
  (* CGUI.Layers.export#connect#clicked ~callback:CDraw.display_set *)

let toggles =
  CGUI.Toggles.map (fun _ key toggle _ ->
    let id = toggle#connect#toggled 
      ~callback:(fun () -> CDraw.set_curr_annotation toggle#active key)
    in key, toggle, id
  ) |> List.hd (* FIXME *)
     
let keyboard () =
  let connect = CGUI.window#event#connect in
  connect#key_press (CDraw.Cursor.arrow_key_press ~toggles);
  connect#key_press update_annotations; ()

let drawing_area () =
  let open CGUI.Thumbnail in
  area#event#add [`POINTER_MOTION; `BUTTON_PRESS; `LEAVE_NOTIFY];
  area#event#connect#motion_notify CDraw.MouseTracker.update;
  area#event#connect#leave_notify CDraw.MouseTracker.hide;
  area#event#connect#button_press (CDraw.Cursor.at_mouse_pointer ~toggles);
  ()

let window () =
  let callback _ = CAction.load_image toggles; true in
  CGUI.window#event#connect#delete ~callback;
  ()

let initialize () =
  List.iter (fun f -> ignore (f ()))
    [icons; keyboard; drawing_area; window];
  toggles
