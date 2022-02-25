- _entry
call dostuff
---
- dostuff
var a int
var b int
var c int
assg a 1
assg b 2
bind in a
bind in b
bind out c
call add
var d int
var e int
assg d 3
bind in c
bind in d
bind out e
call add
bind in e
call print
---
