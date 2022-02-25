- _entry
var a int
assg a 1
bind in a
call meow
---
- meow
var meow_e int
copy meow_e a
bind in meow_e
call print
---
