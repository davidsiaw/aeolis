def parsefuncall(t)
  fnname = t[0...t.index("(")]
  params = t[t.index("(")+1...t.index(")")].split(',')

  return fnname, params
end

def funccall(asm, fnname, params, out)
  params.each do |param|
    asm << "bind in #{param}"
  end
  asm << "bind out #{out}" if out
  asm << "call #{fnname}"
end

content = File.read(ARGV[0])
lines = content.split("\n")

asm = []

asm << '- _entry'

lines.each do |line|
  toks = line.split(' ')
  if line.start_with?('int')
    asm << "var #{toks[1]} int"

  elsif toks[1] == ":="
    if toks[2].include?("(")
      fnname, params = parsefuncall(toks[2])
      funccall(asm, fnname, params, toks[0])
    else
      asm << "assg #{toks[0]} #{toks[2]}"
    end
  elsif toks[0].include?("(")
    fnname, params = parsefuncall(toks[0])
    funccall(asm, fnname, params, nil)
  else
    raise 'syntax error'
  end
end

asm << '---'

puts asm
