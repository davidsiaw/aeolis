- _entry
var a int
bind out a
call meow
bind in a
call print
---
- meow
var meow_d int
assg meow_d 2
copy a meow_d
---
