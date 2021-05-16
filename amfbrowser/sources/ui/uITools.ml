(* AMFinder - ui/uITools.ml
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

module type PARAMS = sig
    val packing : GObj.widget -> unit
    val border_width : int
    val tooltips : GData.tooltips
end


module type S = sig
    val toolbar : GButton.toolbar
    val snap : GButton.tool_button
    val export : GButton.tool_button
end


module Make (P : PARAMS) : S = struct

    let toolbar = GButton.toolbar
        ~orientation:`VERTICAL
        ~style:`ICONS
        ~width:92 ~height:155
        ~packing:P.packing ()

    let packing = toolbar#insert

    let _ = UIHelper.separator packing
    let _ = UIHelper.label packing "<b><small>Toolbox</small></b>"

    let snap = UIHelper.custom_tool_button ~packing `SNAPSHOT 24 "Snap"   
    let export = UIHelper.custom_tool_button ~packing `EXPORT 24 "Export"
end
