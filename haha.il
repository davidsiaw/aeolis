- _entry
var a int
var b int
var c int
assg a 2
assg b 10
bind in a
bind in b
bind out c
call add
bind in c
call print
---
