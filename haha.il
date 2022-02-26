- _entry
var a int
var b int
var r int
bind out a
call gets
assg r 2
bind in a
bind in r
bind out b
call add
var c int
assg c 5
bind in c
call print
bind in b
call print
---
