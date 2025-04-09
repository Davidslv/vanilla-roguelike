# Chapter 2: Setting Up the Environment

Now that we’ve covered the basics of game development and the Entity-Component-System (ECS) pattern, it’s time to get our hands dirty. In this chapter, we’ll set up our development environment, choose our tools, and build a simple "Hello, World" game loop that demonstrates input, state, and rendering. We’ll also establish a project structure to keep our code organized and testable. By the end, you’ll have a running skeleton project ready for the roguelike we’ll develop throughout the book.

## Choosing a Language and Tools

Game development offers a dizzying array of language and tool options. You could go with C++ and a high-performance engine like Unreal for AAA titles, Python with Pygame for quick prototyping, or even JavaScript for browser-based games. Each has its strengths, but for this book, we’re sticking with Ruby and the terminal.

**Why Ruby?** As a senior Ruby developer, I love its expressiveness, flexibility, and developer-friendly syntax. Ruby might not be the first language that comes to mind for games—it’s not as fast as C++ or as game-engine-integrated as C# with Unity—but it’s perfect for learning ECS and building a text-based roguelike. Plus, Ruby’s dynamic nature lets us experiment quickly, and its community gems (like RSpec for testing) make development a breeze.

**Why the terminal?** Simplicity. Rendering to the terminal with characters (e.g., `@` for the player, `#` for walls) keeps us focused on game logic rather than graphics libraries. It’s also lightweight and portable—no need for external dependencies beyond Ruby itself. Later, you can adapt what you learn to graphical libraries like Ruby2D or Gosu if you’d like.

## Prerequisites

To follow along, you’ll need:

* **Ruby:** Version 3.0 or higher recommended. Install it via [ruby-lang.org](https://www.ruby-lang.org/) or a version manager like `rbenv` or `rvm`.
* **A Terminal:** Any will do—macOS Terminal, Windows Command Prompt/PowerShell, or a Linux shell.
* **Bundler:** For managing gems. Install with `gem install bundler`.
* **RSpec:** For testing. We’ll add it to our project shortly.

Let’s dive in!

## Writing a “Hello, World” Game Loop

Every game needs a loop: take input, update the state, and render the result. Let’s create a minimal example to see this in action. Our "Hello, World" game will:

* Display a player (`@`) at a starting position.
* Let the player move left or right with arrow keys (simulated with `a` and `d` for simplicity).
* Exit when the player presses `q`.

Here’s the code. Save it as `game.rb` in a new directory called `roguelike`:

```ruby
# game.rb
class Game
  def initialize
    @player_x = 5  # Starting position
    @running = true
  end

  def run
    while @running
      render
      handle_input
      update
    end
    puts "Goodbye!"
  end

  private

  def render
    system("clear") || system("cls")  # Clear terminal (Linux/macOS or Windows)
    puts " " * @player_x + "@"        # Render player as '@' at its x-position
  end

  def handle_input
    print "Move (a/d) or quit (q): "
    input = gets.chomp.downcase
    case input
    when "a" then @player_x -= 1 unless @player_x <= 0  # Move left
    when "d" then @player_x += 1                        # Move right
    when "q" then @running = false                      # Quit
    end
  end

  def update
    # For now, nothing to update beyond input handling
  end
end

Game.new.run if __FILE__ == $0
```

Run it with `ruby game.rb`. You’ll see an `@` on the screen, and you can move it left or right with `a` and `d`, or quit with `q`. This is our skeleton: it has input (keyboard commands), state (the player’s x position), and rendering (printing to the terminal). It’s simple, but it’s a game!

### Breaking It Down

* **Initialization:** Sets up the player’s starting position and a flag to control the loop.
* **Run Loop:** Repeats until `@running` is `false`, calling `render`, `handle_input`, and `update` each frame.
* **Render:** Clears the screen and draws the player using spaces and an `@`.
* **Handle Input:** Reads a line from the user and adjusts the state.
* **Update:** Empty for now, but later we’ll use it for game logic like collisions.

This isn’t ECS yet—that comes in Chapter 3—but it’s a foundation we’ll build on.

### Basic Project Structure

A well-organized project is key to staying sane as your game grows. Let’s set up a structure that supports our roguelike and includes RSpec for testing. Here’s the directory layout:

```
roguelike/
├── Gemfile           # Manages Ruby dependencies
├── game.rb          # Main game entry point
├── lib/             # Game logic
│   └── (empty for now)
├── spec/            # RSpec tests
│   └── game_spec.rb # Tests for Game class
└── README.md        # Project overview
```

### Step-by-Step Setup

```
mkdir roguelike
cd roguelike
```

```
# Gemfile
source "https://rubygems.org"

gem "rspec", "~> 3.12"  # For testing
```

```
bundle install
```


```
⚠️ This section needs improvement
```


### Outcome

By the end of this chapter, you’ve:

* Chosen Ruby and the terminal as your tools.
* Written and run a basic "Hello, World" game loop.
* Set up a project structure with RSpec for testing.
* Created a skeleton project ready for ECS implementation.

Run `ruby game.rb` to see your game in action, and `bundle exec rspec` to confirm the tests pass. In Chapter 3, we’ll refactor this into an ECS architecture, introducing entities, components, and systems to make our roguelike come alive. Let’s keep building!