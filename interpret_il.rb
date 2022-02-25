# frozen_string_literal: true

# Asynchronous
# Execution
# Order
# Language
# Interpretation
# System

# string classes
class String
  def camelize
    self.split('-').map do |word|
      word.capitalize
    end.join
  end
end

# machine state
class MachineState
  attr_reader :dict, :queue, :bindlist

  def initialize(lines)
    @dict = {}
    @queue = []
    @bindlist = []
    @lines = lines
    @funclist = {}
    @jointhreads = []
    register_funcs!
  end

  def waiting
    return false if @jointhreads.count.zero?

    true
  end

  def next_executable_index
    queue.each_with_index do |fn, i|
      list = fn[:bindlist]
      callable = true
      list.each do |bindvar|
        varname = bindvar[:name]
        if !dict.key?(varname)
          raise "no such var #{varname}"
        end

        varinfo = dict[varname]
        callable = false if varinfo[:bound]


        if bindvar[:direction] == :in &&
           !varinfo[:ready]
          callable = false
        end

        break unless callable
      end

      return i if callable
    end
  end

  def pop_next_executable
    idx = next_executable_index
    returnable = nil
    new_queue = []
    queue.each_with_index do |fn, i|
      if i == idx
        returnable = fn
      else
        new_queue << fn
      end
    end

    @queue = new_queue

    returnable
  end

  def register_funcs!
    current_def = nil
    current_block = []
    @lines.each do |line|
      toks = line.split(' ')
      if toks[0] == '-'
        raise 'already in func' unless current_def.nil?

        current_def = toks[1]
      elsif toks[0] == '---'
        raise 'not in func' if current_def.nil?

        @dict[current_def] = {
          type: {
            form: :function
          },
          lines: current_block
        }
        @funclist[current_def] = @dict[current_def]
        current_def = nil
        current_block = []
      else
        raise 'not in func' if current_def.nil?

        current_block << line
      end
    end
  end

  def run(function_name)
    fn = @dict[function_name]
    raise "no such fun #{function_name}" if fn.nil? || fn[:type][:form] != :function

    fn[:lines].each do |line|
      c = Command.new(line)
      c.run(self)
    end
  end
end

module Commands
  # variable command
  class Var
    def initialize(state, name, type)
      @state = state
      @name = name
      @type = type
    end

    def run
      raise "#{@name} already defined" if @state.dict.key?(@name)

      @state.dict[@name] = {
        type: {
          form: :variable,
          type: @type
        },
        ready: false,
        bound: false,
        value: nil
      }
    end
  end

  # assignment command
  class Assg
    def initialize(state, name, value)
      @state = state
      @name = name
      @value = value
    end

    def run
      @state.dict[@name][:value] = @value
      @state.dict[@name][:ready] = true
    end
  end

  # binding command
  class Bind
    def initialize(state, direction, name)
      @state = state
      @direction = direction
      @name = name
    end

    def run
      @state.bindlist << {
        name: @name,
        direction: @direction.to_sym
      }
    end
  end

  # function call (queue func)
  class Call
    def initialize(state, name)
      @state = state
      @name = name
    end

    def run
      @state.queue << {
        function_name: @name,
        bindlist: @state.bindlist.dup
      }
      @state.bindlist.clear
    end
  end

  # copy operation
  class Copy
    def initialize(state, dst, src)
      @state = state
      @dst = dst
      @src = src
    end

    def run
      @state.dict[@dst][:value] = @state.dict[@src][:value]
      @state.dict[@dst][:ready] = @state.dict[@src][:ready]
    end
  end

  class Del
    def initialize(state, varname)
      @state = state
      @varname = varname
    end

    def run
      @state.dict.delete(@varname)
    end
  end
end

# command runner
class Command
  def initialize(line)
    @line = line
  end

  def tokens
    @tokens ||= @line.split(' ').compact
  end

  def cmd
    Commands.const_get(tokens[0].camelize)
  end

  def args
    tokens[1..-1]
  end

  def run(state)
    cmd.new(state, *args).run
  end
end

module Intrinsics
  class Add
    def initialize(state, executable)
      @state = state
      @executable = executable
    end

    def run
      a = @state.dict[@executable[:bindlist][0][:name]][:value]
      b = @state.dict[@executable[:bindlist][1][:name]][:value]
      c = a.to_i + b.to_i
      @state.dict[@executable[:bindlist][2][:name]][:value] = c
      @state.dict[@executable[:bindlist][2][:name]][:ready] = true
    end
  end

  class Print
    def initialize(state, executable)
      @state = state
      @executable = executable
    end

    def run
      p @state.dict[@executable[:bindlist][0][:name]][:value]
    end
  end
end

# executes funcs
class Executor
  def initialize(state, executable)
    @state = state
    @executable = executable
  end

  def execute
    name = @executable[:function_name].camelize
    if Intrinsics.const_defined?(name)
      int = Intrinsics.const_get(name)
      int.new(@state, @executable).run
    else
      @state.run(@executable[:function_name])
    end
  end
end

src = File.read(ARGV[0])
lines = src.split("\n")

state = MachineState.new(lines)

state.run('_entry')

loop do
  executable = state.pop_next_executable
  if executable.nil? && !state.waiting
    raise "no next with #{state.queue.count}"
  end

  executor = Executor.new(state, executable)
  executor.execute
  break if state.queue.count.zero?
end
