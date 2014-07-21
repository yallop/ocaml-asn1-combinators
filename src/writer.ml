
let cs_compare cs1 cs2 =
  let (s1, s2) = Cstruct.(len cs1, len cs2) in
  let rec go i lim =
    if i = lim then
      compare s1 s2
    else
      match
        Cstruct.(compare (get_uint8 cs1 i) (get_uint8 cs2 i))
      with
      | 0 -> go (succ i) lim
      | n -> n in
  go 0 (min s1 s2)

type t = int * (int code -> Cstruct.t code -> unit code)

let immediate n f = (n, f)

let len (n, _) = n

let empty = (0, (fun _ _ -> .< () >.))

let (<>) (l1, w1) (l2, w2) =
  let w off buf =
    .< ( .~(w1 off buf) ; .~(w2 .< .~off + l1 >. buf) ) >. in
  (l1 + l2, w)

let append = (<>)

let rec concat = function
  | []    -> empty
  | w::ws -> w <> concat ws

let of_list lst =
  let open List in
  let w off cs =
    let _, code = 
      fold_left
        (fun (i, acc) x ->
          (i+1, .< begin Cstruct.set_uint8 .~cs (.~off + i) x ; .~acc end >.))
        (0, .< () >.)
        lst
    in code
  in
  (length lst, w)

let of_string str =
  let n = String.length str in
  (n, fun off cs -> .< Cstruct.blit_from_string str 0 .~cs .~off n >.)

let of_cstruct cs' =
  let n = Cstruct.len cs' in
  (n, fun off cs -> .< Cstruct.blit cs' 0 .~cs .~off n >.)

let of_byte b = (1, fun off cs -> .< Cstruct.set_uint8 .~cs .~off b >.)

let to_cstruct ((n, w) : t) : Cstruct.t =
  (* jdy: TODO *)
  let cs = Cstruct.create n in ( let () = Runcode.run (w .< 0 >. .< cs >.) in cs )

let to_writer (n, w) = (n, fun cs -> w .< 0 >. cs)
