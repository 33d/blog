---
layout: post
title: 2022 Advent of Code
slug: 2022-advent-of-code
---

I'm having a go at the [2022 Advent of Code](https://adventofcode.com/2022/). Here's how I solved the problems - the ones I could be bothered solving anyway.

# [01](https://adventofcode.com/2022/day/1)

Use this awk script to convert the data to a CSV, one row per elf:

```
/[0-9]/ { printf "%d,", $0 }
/^$/ { print "" }
```

Load the result into a spreadsheet application, sum the rows, and sort the totals to get the answers.

# [02](https://adventofcode.com/2022/day/2)

The score depends only on the second character (X, Y or Z), and whether you win, lose or draw.  I went for Python this time.

```
import sys
import functools

player_score = { 'X': 1, 'Y': 2, 'Z': 3 }
win_scores = {
  'X': { 'A': 3, 'B': 0, 'C': 6 },
  'Y': { 'A': 6, 'B': 3, 'C': 0 },
  'Z': { 'A': 0, 'B': 6, 'C': 3 },  
}

print (functools.reduce(
  lambda score, line: score + player_score[line[2]] + win_scores[line[2]][line[0]],
  (l for l in sys.stdin if len(l) >= 3),
  0
))
```

Part two is a little simpler, you can precalculate each result:

```
import sys
import functools

scores = {
  'A': { 'X': 0 + 3, 'Y': 3 + 1, 'Z': 6 + 2 },
  'B': { 'X': 0 + 1, 'Y': 3 + 2, 'Z': 6 + 3 },
  'C': { 'X': 0 + 2, 'Y': 3 + 3, 'Z': 6 + 1 },
}

print (functools.reduce(
  lambda score, line: score + scores[line[0]][line[2]],
  (l for l in sys.stdin if len(l) >= 3),
  0
))
```

# [03](https://adventofcode.com/2022/day/3)

Get the first half of the string, look for the first character in the second half in the first half

```
import sys
import functools

# the score of each item; a = 1
scores = list(' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')

def score(line):
    half = len(line) // 2
    first_half = line[0:half]
    try:
        common = next(l for l in line[half:] if l in first_half)
        return scores.index(common)
    except StopIteration:
        # no item in common
        return 0

print(functools.reduce(
    lambda s, line: s + score(line.strip()),
    sys.stdin,
    0
))
```

Part 2:

```
import sys
import functools
import itertools

# the score of each item; a = 1
scores = list(' abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')

def score(lines):
    rest = lines[1:]
    common = next(c for c in lines[0] if all(c in l for l in rest))
    return scores.index(common)

print(functools.reduce(
    lambda s, lines: s + score([l.strip() for l in lines]),
    # take groups of 3 until the result is empty
    iter(lambda: list(itertools.islice(sys.stdin, 3)), []),
    0
))
```

# [04](https://adventofcode.com/2022/day/4)

```
import sys
import re

line_re = re.compile(r'(\d+)-(\d+),(\d+)-(\d+)')

def within(line):
    n = [int(n) for n in line_re.match(line).group(1, 2, 3, 4)]
    return n[0] >= n[2] and n[1] <= n[3] or \
           n[2] >= n[0] and n[3] <= n[1]

print(sum(
    within(line) and 1 or 0 for line in sys.stdin
))
```

Part 2 is the same, with the return value:

```
    return n[0] <= n[3] and n[1] >= n[2] or \
           n[1] <= n[2] and n[0] >= n[3]
```

# [05](https://adventofcode.com/2022/day/5)

The stacks are represented by lists. The initial state is loaded into the start of each list, then manipulated at the end of the lists.

```
import sys
import re

move_re = re.compile('move (\d*) from (\d*) to (\d*)')

stack_count = 9
stacks = [[] for n in range(stack_count)]

for line in sys.stdin:
    if len(line) < 36:
        break
    for n in range(stack_count):
        char = line[n * 4 + 1]
        if char != ' ':
            stacks[n].insert(0, char)

for line in sys.stdin:
    match = move_re.match(line)
    if not match:
        continue
    number, src, to = (int(n) for n in move_re.match(line).group(1, 2, 3))
    transferred = stacks[src-1][-number:]
    transferred.reverse()
    del stacks[src-1][-number:]
    stacks[to-1].extend(transferred)

print("".join(s[-1] for s in stacks))
```

For part two, remove the `reverse` line (which I did first, because I didn't read the instructions properly!)

# [06](https://adventofcode.com/2022/day/6)

Almost a one liner:

```
import sys

data = sys.stdin.read()
count = 4
print(next(n for n in range(count, len(data)) if len(set(data[n-count:n])) == count))
```

Change count to 14 for the second step.

# [07](https://adventofcode.com/2022/day/7)

```
import sys

root = {}
dir = root

for line in sys.stdin:
    if line.startswith("$ cd "):
        name = line[5:-1] # chop off the newline
        if name == '/':
            dir = root
        else:
            dir = dir[name]
    elif not line.startswith("$"):
        size, name = line.split(maxsplit=1)
        name = name[:-1] # chop off the newline
        if size == "dir":
            dir.setdefault(name, {"..": dir})
        else:
            dir[name] = int(size)

def sizes(dir, all=[]):
    total = 0
    for name, val in dir.items():
        if name == '..':
            continue
        if type(val) == dict:
            total += sizes(val, all)[-1]
        else:
            total += val
    all.append(total)
    return all

print(sum(s for s in sizes(root) if s <= 100000))
```

For part 2, change the final `print` to

```
allsizes = sizes(root)
used = allsizes[-1]
required = 30000000 - (70000000 - used)
print(min(s for s in sizes(root) if s >= required))
```

# [08](https://adventofcode.com/2022/day/8)

Create iterators extending from each side of the grid.  Store the coordinates of seen trees in a set.

```
import sys

grid = []

for line in sys.stdin:
  grid.append([int(n) for n in line if n.isdigit()])
  
visible = set()

def look(iter):
    highest = -1
    for coord, value in iter:
        if value > highest:
            visible.add(coord)
            highest = value

for y, line in enumerate(grid):
    look(((x, y), line[x]) for x in range(len(line) - 1))
    look(((x, y), line[x]) for x in range(len(line) - 1, 0, -1))

for x in range(len(grid[0]) - 1):
    look(((x, y), grid[y][x]) for y in range(len(grid) - 1))
    look(((x, y), grid[y][x]) for y in range(len(grid) - 1, 0, -1))

print(len(visible))
```

# [09](https://adventofcode.com/2022/day/9)

```
import sys

visited = set((0,0))

head = (0, 0)
tail = (0, 0)

dirs = {
  'U': lambda x: (x[0], x[1] - 1),
  'D': lambda x: (x[0], x[1] + 1),
  'L': lambda x: (x[0] - 1, x[1]),
  'R': lambda x: (x[0] + 1, x[1]),
}

signum = lambda x: x < 0 and -1 or x > 0 and 1 or 0

for line in sys.stdin:
  direction, count = line.split()
  dir_fn = dirs[direction]
  
  for n in range(int(count)):
    head = dir_fn(head)
    dx = head[0] - tail[0]
    dy = head[1] - tail[1]
    if abs(dx) > 1 or abs(dy) > 1:
      tail = (tail[0]+signum(dx), tail[1]+signum(dy))
      visited.add(tail)

print(len(visited))
```

Apparently this is wrong. I took a guess and subtracted one, and that was right. It looks like I got the constructor call for `visited` wrong.

The second part involves extending it to a rope of 10 elements:

```
import sys

visited = set()
visited.add((0,0))

rope = [(0, 0)] * 10

dirs = {
  'U': lambda x: (x[0], x[1] - 1),
  'D': lambda x: (x[0], x[1] + 1),
  'L': lambda x: (x[0] - 1, x[1]),
  'R': lambda x: (x[0] + 1, x[1]),
}

signum = lambda x: x < 0 and -1 or x > 0 and 1 or 0

for line in sys.stdin:
  direction, count = line.split()
  dir_fn = dirs[direction]
  
  for n in range(int(count)):
    rope[0] = dir_fn(rope[0])
    for n in range(0,9):
      a = rope[n]
      b = rope[n+1]
      dx = a[0] - b[0]
      dy = a[1] - b[1]
      if abs(dx) > 1 or abs(dy) > 1:
        rope[n+1] = (b[0]+signum(dx), b[1]+signum(dy))
    visited.add(rope[-1])

print(len(visited))
```

# [10](https://adventofcode.com/2022/day/10)

```
import sys
import unittest

def run(lines):
  x = 1
  for line in lines:
    if line.startswith("noop"):
      yield x
    elif line.startswith("addx "):
      x = x + int(line[5:])
      yield x
      yield x

class TestExecution(unittest.TestCase):
  def test_example(self):
    self.assertEqual([1, 4, 4, -1, -1], list(run(['noop', 'addx 3', 'addx -5'])))

unittest.main(exit=False)

# Subtract two from the index for the delay, one more because
# it's 1 indexed
print(sum(x * (c+3) for c, x in enumerate(run(sys.stdin)) if c in range(17, 221, 40)))
```

For the second part, change the last line to:

```
out = itertools.chain([1, 1], run(sys.stdin))
for y in range(6):
  for x in range(40):
    val = next(out)
    print((x >= val-1 and x <= val+1) and '#' or '.', end='')
  print()
```

# [11](https://adventofcode.com/2022/day/11)

This one was tough - there are plenty of chances to misread the problem and type the wrong data.

```
import sys

class Monkey:
  def __init__(self, num, items, op, divisor, testtrue, testfalse):
    self.num = num
    self.items = items
    self.op = op
    self.divisor = divisor
    self.testtrue = testtrue
    self.testfalse = testfalse
    self.inspections = 0

  def inspect(self, monkeys):
    items = self.items
    self.items = []
    self.inspections = self.inspections + len(items)
    for i in items:
      w = self.op(i) // 3
      if (w % self.divisor) == 0:
        monkeys[self.testtrue].items.append(w)
      else:
        monkeys[self.testfalse].items.append(w)

monkeys = [
  Monkey(0, [83, 97, 95, 67], lambda x: x * 19, 17, 2, 7),
  Monkey(1, [71, 70, 79, 88, 56, 70], lambda x: x + 2, 19, 7, 0),
  Monkey(2, [98, 51, 51, 63, 80, 85, 84, 95], lambda x: x + 7, 7, 4, 3),
  Monkey(3, [77, 90, 82, 80, 79], lambda x: x + 1, 11, 6, 4),
  Monkey(4, [68], lambda x: x * 5, 13, 6, 5),
  Monkey(5, [60, 94], lambda x: x + 5, 3, 1, 0),
  Monkey(6, [81, 51, 85], lambda x: x * x, 5, 5, 1),
  Monkey(7, [98, 81, 63, 65, 84, 71, 84], lambda x: x + 3, 2, 2, 3),
]

for x in range(20):
  for monkey in monkeys:
    monkey.inspect(monkeys)
inspections = [m.inspections for m in monkeys]
inspections.sort()
print(inspections[-1] * inspections[-2])
```

Using this approach for part two doesnt work - the numbers get too big.

# [12](https://adventofcode.com/2022/day/12)

Looks interesting, it's essentially a maze solving algorithm.

The algorithm would be something like:

* Let "Set" be a class containing a coordinate and a direction.
* Let there be a list of Setps.
* The directions are, in sequence, up, right, down and left.
* You can't go further if you hit an edge, hit a space too high, or a space in the list of steps.
* While you can continue to move up:
  * Add the next step up to the list of steps
* Go the next direction, then continue the above step
* If you can't move, remove one Step from the list of Steps, then continue testing the directions.
* Continue until the end is reached.

After working on this for a while, it was taking a really long time to run, so I added the places visited but rejected to another list, and didn't visit them again.  There was another problem: it can't account for a shorter way between two visited points.  Instead, work from the end to the start, and for each point, store the minimum steps required to reach it from the end.  Where a new minimum is set, re-evaluate all paths from that point, but there's no point visiting any spaces with a lower score. Thinking about these rules, instead of keeping a list of steps visited, when setting a new minimum, add that space to a list of spaces to be evaluated, and continue until this list is empty.
 
```
import sys

movements = [
  lambda pos: (pos[0], pos[1] - 1), # up
  lambda pos: (pos[0] + 1, pos[1]), # right
  lambda pos: (pos[0], pos[1] + 1), # down
  lambda pos: (pos[0] - 1, pos[1]), # left
]  

class Terrain:
    def __init__(self, data):
        self.data = data
        self.width = len(self.data[0])
        self.height = len(self.data)
        self.size = self.width * self.height

    def __getitem__(self, pos):
        return self.data[pos[1]][pos[0]]

    def __setitem__(self, pos, val):
        self.data[pos[1]][pos[0]] = val

terrain = Terrain([
    [(1000 if c == 'S' else 26 if c == 'E' else ord(c) - ord('a')) for c in line[:-1]]
        for line in sys.stdin
])
scores = Terrain([
  [None] * terrain.width for i in range(terrain.height)
])

# I can't be bothered extracting these from the input
start = (0, 20)
end = (137, 20)

scores[end] = 0
to_evaluate = [end]

while len(to_evaluate):
    curr = to_evaluate.pop()
    score = scores[curr]
    for movement in movements:
        next = movement(curr)
        if next[0] < 0 or next[0] >= terrain.width \
                or next[1] < 0 or next[1] >= terrain.height:
            continue
        nextScore = scores[next]
        if terrain[curr] > terrain[next] + 1:
            # The step is too high
            continue
        if nextScore == None or nextScore > score + 1:
            scores[next] = score + 1
            to_evaluate.append(next)

print(scores[start])
``` 

For part two, as this loop runs, keep track of the lowest score where the elevation is the lowest.

# [16](https://adventofcode.com/2022/day/16)

This feels similar to day 12.  Let class Valve have a flow rate, and a list of tunnels.  Walk the graph as in the map in day 12 until the 30 minutes have passed, then backtrack and continue.

