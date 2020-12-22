(* AMFinder - amfColor.ml
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

open Scanf

type red = float
type blue = float
type green = float
type alpha = float

let opacity = float 0xB0 /. 255.0

let rgb_from_name = function
    | "cyan"    -> "#00FFFF" 
    | "white"   -> "#FFFFFF"
    | "yellow"  -> "#FFFF00"
    | "magenta" -> "#FF00FF"
    | other     -> other

let rgba_from_name x = 
    let res = rgb_from_name x in
    if res = x then res else (* was a name *) res ^ "FF"

let normalize n = max 0.0 (min 1.0 (float n /. 255.0))

let parse_rgb s =
    sscanf (rgb_from_name s) "#%02x%02x%02x"
        (fun r g b -> normalize r, normalize g, normalize b)

let parse_rgba s =
    sscanf (rgba_from_name s) "#%02x%02x%02x%02x" 
        (fun r g b a -> normalize r, normalize g, normalize b, normalize a)