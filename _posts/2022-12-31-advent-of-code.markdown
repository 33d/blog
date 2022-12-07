---
layout: post
title: 2022 Advent of Code
slug: 2022-advent-of-code
---

I'm having a go at the [2022 Advent of Code](https://adventofcode.com/2022/). Here's how I solved the problems - the ones I could be bothered solving anyway.

= [01](https://adventofcode.com/2022/day/1) =

Use this awk script to convert the data to a CSV, one row per elf:

```
/[0-9]/ { printf "%d,", $0 }
/^$/ { print "" }
```

Load the result into a spreadsheet application, sum the rows, and sort the totals to get the answers.

= [02](https://adventofcode.com/2022/day/2) =

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

= [03](https://adventofcode.com/2022/day/3) =

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

= [04](https://adventofcode.com/2022/day/4) =

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

= [05](https://adventofcode.com/2022/day/5) =

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

= [06](https://adventofcode.com/2022/day/6) =

Almost a one liner:

```
import sys

data = sys.stdin.read()
count = 4
print(next(n for n in range(count, len(data)) if len(set(data[n-count:n])) == count))
```

Change count to 14 for the second step.

= [07](https://adventofcode.com/2022/day/7) =

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


