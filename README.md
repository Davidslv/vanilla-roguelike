# Vanilla Roguelike

This is a work in progress [roguelike game](https://en.wikipedia.org/wiki/Roguelike) written in Ruby, it is inspired by the original 1980's [rogue game](https://en.wikipedia.org/wiki/Rogue_(video_game)).

Most likely it will take me forever to write it... oh well!

### The objective

Your objective is to move your character (`@`) through the mazes, find your way to the stairs (`%`) so that you can find the next maze.

## Install dependencies

This project uses ruby 2.7.2 (see .ruby-version).
I use rbenv to install different ruby versions, you may need to install [homebrew](https://brew.sh).

In case you need to install everything you can simply do:

```bash
$ ./install.sh
```

Otherwise you can proceed with the following:

```bash
$ brew bundle

$ rbenv install
$ gem install bundler
$ bundle install
```

## Examples

See the [examples folder](https://github.com/Davidslv/vanilla/tree/master/examples) with examples of the different algorithms.

## Demo

If you would like to watch a small demo.


```ruby
$ pry -r ./play.rb
pry(main)> Vanilla::Demo.run

```


https://user-images.githubusercontent.com/136777/124296344-c3dff380-db51-11eb-9490-21968571608d.mov


## Play

There is an executable `vanilla.rb` file.

```bash
$ ./bin/vanilla.rb
```

Or you can use the `play.rb` file with, but that's mostly used as a playground.

```ruby
$ pry -r ./play.rb
pry(main)> Vanilla.run

```

### Controls

Use your keyboard keys H J K L, or use the arrow keys.

- H - moves left
- J - moves down
- K - moves up
- L - moves right
- q - quits the game (may require multiple presses if you have been using the arrows to move the character)

## Playground

```ruby
$ pry -r ./play.rb
pry(main)> Vanilla.play(rows: 10, columns: 10)

```


## Algorithms

The following are some of the known procedural [maze generation algorithms](https://en.wikipedia.org/wiki/Maze_generation_algorithm).
If you looking to understand more about different [generation algorithms](https://en.wikipedia.org/wiki/Talk%3AMaze_generation_algorithm), then I recommend you to read [Jamis Buck](https://medium.com/@jamis) [blog](http://weblog.jamisbuck.org/2011/2/7/maze-generation-algorithm-recap) and his book [Mazes for Programmers](https://pragprog.com/titles/jbmaze/mazes-for-programmers/).

### Binary Tree

For each cell in the grid, it randomly creates a passage either north or east.

Features a strong diagonal texture, tending toward the north-east corner of the grid.
Passages run the length of the northern row and the eastern column.

This is the algorithm used by default.

- [Video explanation](https://www.youtube.com/watch?v=oSWTXtMglKE)
- [Wikipedia](https://en.wikipedia.org/wiki/Binary_space_partitioning)

### Aldous Broder

Starts in a random cell, moves randomly from cell to cell.
It creates a passage when finds an unvisited cell.

Starts quickly, although it can take a while to finish.
This is considered unbiased, meaning it should generate mazes completely randomly.

- [Kansas State University written explanation](https://people.cs.ksu.edu//~ashley78/wiki.ashleycoleman.me/index.php/Aldous-Broder_Algorithm.html)


```ruby
$ pry -r ./play.rb
Vanilla.play(rows: 10, columns: 15, algorithm: Vanilla::Algorithms::AldousBroder)
```

### Recursive Backtracker

Starts at a random cell, moves randomly, avoids previously visited cells.
When there are no more possible moves, it backtracks to the most recently visited cell and continues.
It finishes when it tries to backtrack to where it started.

- [Video explanation](https://youtu.be/elMXlO28Q1U?t=9)
- [Another video](https://www.youtube.com/watch?v=gBC_Fd8EE8A)
- [Wikipedia](https://en.wikipedia.org/wiki/Backtracking)
- [Kansas State University written explanation](https://people.cs.ksu.edu//~ashley78/wiki.ashleycoleman.me/index.php/Recursive_Backtracker.html)

```ruby
$ pry -r ./play.rb
Vanilla.play(rows: 10, columns: 15, algorithm: Vanilla::Algorithms::RecursiveBacktracker)
```

### Recursive Division

It works by dividing the grid into two subgrids, adding a wall between them and a single passage linking them.
The algorithm is then repeated on each side, recursively, until the passages are the desired size.

Tends to be of a boxy or rectangular texture.

- [Kansas State University written explanation](https://people.cs.ksu.edu//~ashley78/wiki.ashleycoleman.me/index.php/Recursive_Division.html)

```ruby
$ pry -r ./play.rb
Vanilla.play(rows: 10, columns: 15, algorithm: Vanilla::Algorithms::RecursiveDivision)
```

### Dijkstra's algorithm

This is an algorithm for finding the shortest path between two given nodes in a graph.

- [Wikipedia](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm)

### Contributing

If you are interested in contributing, please do.

## Documentation

I'm using [Yard](https://rubydoc.info/gems/yard/0.9.26/file/README.md) to create documentation.

**Creates HTML documentation**

```bash
$ yard doc
```

**Starts web server**

Open your browser and go to http://localhost:8808/

```bash
$ yard server
```

### License

Vanilla is under the MIT License.

## Features

- **Procedural Maze Generation**: Creates unique playable maps for each level
- **Entity-Component-System (ECS)**: Modern architecture for game entities
- **Command Pattern**: For handling user input
- **Event System**: Decoupled communication between systems with persistent event logging
- **Monster AI**: Creatures that hunt the player through the maze
