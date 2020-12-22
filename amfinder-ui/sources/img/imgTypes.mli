(* AMFinder - img/imgTypes.mli
 *
 * MIT License
 * Copyright (c) 2021 Edouard Evangelisti
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 *)

(** Class types. *)


(** {2 File manager} *)

class type file = object

    method path : string
    (** Path to the input image. *)

    method base : string
    (** File base name. *)

    method archive : string
    (** Name of the output archive. *)

end



(** {2 Image source} *)

class type source = object

    method width : int
    (** Image width, in pixels. *)

    method height : int
    (** Image height, in pixels. *) 
 
    method edge : int
    (** Tile size (in pixels) used to segment the source image. *)

    method rows : int
    (** Row count. *)

    method columns : int
    (** Column count. *)

    method save_settings : Zip.out_file -> unit
    (** Saves settings. *)

end



(** {2 Cursor} *)

class type cursor = object

    method get : int * int
    (** Returns the current cursor position. *)

    method at : r:int -> c:int -> bool
    (** Indicates whether the cursor is at the given coordinates. *)

    method key_press : GdkEvent.Key.t -> bool
    (** Monitors key press. *)

    method mouse_click : GdkEvent.Button.t -> bool
    (** Monitors mouse click. *)

    method set_erase : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to repaint tiles below cursor. *)

    method set_paint : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to paint the cursor. *)

    method update_cursor_pos : r:int -> c:int -> bool
    (** Updates cursor position. *)

end



(** {2 Mouse pointer} *)

class type pointer = object

    method get : (int * int) option
    (** Returns the current pointer position, if any. *)

    method at : r:int -> c:int -> bool
    (** Tells whether the pointer is at a given coordinate. *)

    method track : GdkEvent.Motion.t -> bool
    (** Tracks pointer position. *)

    method leave : GdkEvent.Crossing.t -> bool
    (** Detects pointer leaving. *)

    method set_erase : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to repaint tiles below pointer. *)

    method set_paint : (?sync:bool -> r:int -> c:int -> unit -> unit) -> unit
    (** Sets the function used to paint the pointer. *)

end



(** {2 Low-level Cairo surface drawing} *)

class type brush = object

    method edge : int
    (** Returns tile size. *)

    method x_origin : int
    (** Returns drawing origin on X axis. *)

    method y_origin : int
    (** Returns drawing origin on Y axis. *)

    method make_visible : r:int -> c:int -> unit -> bool
    (** Ensure the given tile is within the visible window.
      * @return True when drawing has to be updated. *)

    method r_range : int * int
    (** Returns the range of visible rows. *)

    method c_range : int * int
    (** Returns the range of visible columns. *)

    method backcolor : string
    (** Returns image background color. *)

    method set_backcolor : string -> unit
    (** Defines image background color. *)

    method background : ?sync:bool -> unit -> unit
    (** Draws a white background on the right image area.
      * @param sync defaults to [true]. *)

    method pixbuf : ?sync:bool -> r:int -> c:int -> GdkPixbuf.pixbuf -> unit
    (** [pixbuf ?sync ~r ~c p] draws pixbuf [p] at row [r] and column [c].
      * @param sync defaults to [false]. *)

    method empty : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draws an empty tile. *)

    method surface : ?sync:bool -> r:int -> c:int -> Cairo.Surface.t -> unit
    (** [surface ?sync ~r ~c s] draws surface [s] at row [r] and column [c].
      * @param sync defaults to [false]. *)

    method locked_tile : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Specialized method for locked tiles. *)

    method cursor : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draws the cursor.
      * @param sync defaults to [false]. *)

    method annotation : ?sync:bool -> r:int -> c:int -> AmfLevel.level -> Morelib.CSet.t -> unit
    (** Draws a tile annotation.
      * @param sync defaults to [false]. *)

    method annotation_other_layer : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draw the frame of an annotation, for tiles that gets annotated but not
      * in the active layer (to distinguish with non-annotated tiles). *)

    method prediction : ?sync:bool -> r:int -> c:int -> float list -> char -> unit
    (** Draws a tile prediction.
      * @param sync defaults to [false]. *)

    method prediction_palette : ?sync:bool -> unit -> unit
    (** Displays a full palette. *)

    method annotation_legend : ?sync:bool -> unit -> unit
    (** Displays the annotations. *)

    method show_probability : ?sync:bool -> float -> unit
    (** Displays the probability cursor. *)

    method hide_probability : ?sync:bool -> unit -> unit
    (** Hides probability. *)

    method sync : string -> unit -> unit
    (** Synchronize drawings between the back pixmap and the drawing area. *)

end



(** {2 Tile matrices} *)

class type tile_matrix = object

    method get : r:int -> c:int -> GdkPixbuf.pixbuf option
    (** Retrieves a specific tile. *)

    method iter : (r:int -> c:int -> GdkPixbuf.pixbuf -> unit) -> unit
    (** Iterates over tiles. *)

end



(** {2 Annotation manager} *)

class type annotations = object

    method get : r:int -> c:int -> unit -> AmfAnnot.annot
    (** Returns the item at the given coordinates and annotation level. *)

    method iter : (r:int -> c:int -> AmfAnnot.annot -> unit) -> unit
    (** Iterates over items at the given coordinates and annotation level. *)

    method iter_layer : char -> (r:int -> c:int -> AmfAnnot.annot -> unit) -> unit
    (** Iterates over items at the given coordinates and annotation level. *)

    method statistics : ?level:AmfLevel.level -> unit -> (char * int) list
    (** Returns the current statistics. *)
   
    method has_annot : ?level:AmfLevel.level -> r:int -> c:int -> unit -> bool
    (** Indicates whether the given tile has annotation. By default, checks the
      * current annotation layer. *)

    method dump : Zip.out_file -> unit
    (** Saves annotations. *)
    
end



(** {2 Prediction manager} *)

class type predictions = object

    method ids : AmfLevel.level -> string list
    (** Returns the list of predictions at the given annotation level. *)

    method current : string option
    (** Return the identifier of the active prediction table. *)

    method set_current : string option -> unit
    (** Define the active prediction table. *)

    method active : bool
    (** Tells whether predictions are being displayed. *)

    method count : int
    (** Returns the number of predictions in the current dataset. *)

    method next_uncertain : (int * int) option
    (** Returns the coordinates of the next most uncertain prediction. *)

    method get : r:int -> c:int -> float list option
    (** Return the probabilities at the given coordinates. *)
    
    method max_layer : r:int -> c:int -> (char * float) option
    (** Return the layer with maximum probability at the given coordinates. *)
    
    method iter : 
        [ `ALL of (r:int -> c:int -> float list -> unit)
        | `MAX of (r:int -> c:int -> char * float -> unit) ] -> unit
    (** Iterate over all predictions. *)
    
    method iter_layer : char -> (r:int -> c:int -> float -> unit) -> unit
    (** Iterate over tiles which have their top prediction on a given layer. *)
    
    method statistics : (char * int) list
    (** Statistics, currently based on the top prediction. *)
    
    method to_string : unit -> string
    (** Return the string representation of the active prediction table. *)
    
    method exists : r:int -> c:int -> bool
    (** Indicates whether the given tile has predictions. *)

    method dump : Zip.out_file -> unit
    (** Saves predictions. *)

end



(** {2 Class activation maps} *)

class type activations = object
    method active : bool
    (** Indicates whether class activation maps are to be displayed. *)
    
    method get : string -> char -> r:int -> c:int -> GdkPixbuf.pixbuf option
    (** Return the CAM associated with a given tile. *)
    
    method dump : Zip.out_file -> unit
    (** Saves activations. *)
end



(** {2 High-level tile drawing} *)

class type draw = object

    method set_update: (unit -> unit) -> unit
    (** Registers a function to update the overall view. *)

    method tile : ?sync:bool -> r:int -> c:int -> unit -> bool
    (** Draw tile image at the given coordinates. *)    

    method cursor : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draw cursor at the given coordinates. *)

    method overlay : ?sync:bool -> r:int -> c:int -> unit -> unit
    (** Draw annotation/prediction at the given coordinates. *)

end



(** {2 Interaction with the user interface} *)

class type ui = object

    method set_paint : (unit -> unit) -> unit
    (** Painting functions to update the current tile. *)

    method update_toggles : unit -> unit
    (** Update annotations at the current cursor position. *)

    method toggle : GButton.toggle_button -> char -> GdkEvent.Button.t -> bool
    (** Update annotations when a toggle button is toggled. *)

    method key_press : GdkEvent.Key.t -> bool
    (** Update annotations based on key press. *)

    method mouse_click : GdkEvent.Button.t -> bool
    (** Update annotations based on mouse click. *)

end
