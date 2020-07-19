# Defold Grid Engine
Defold Grid Engine (DGE) 0.1.0 provides grid-based movement, interactions, and utility features to a Defold game engine project. Two examples of video game franchises that use grid-based systems are Pokémon and Fire Emblem.

Visit [my website](https://gymratgames.github.io/html/extensions.html#dge) to see an animated gif of the example project.  
An [example project](https://github.com/gymratgames/defold-grid-engine/tree/master/example) is available if you need additional help with configuration.

## Installation
To install DGE into your project, add one of the following links to your `game.project` dependencies:
  - https://github.com/gymratgames/defold-grid-engine/archive/master.zip
  - URL of a [specific release](https://github.com/gymratgames/defold-grid-engine/releases)

## Configuration
Import the DGE Lua module into your character's script like so:  
`local dge = require "dge.dge"`

The grid system itself must be initialized before registering any characters. To initialize DGE, simply call `dge.init()` like so:

```
local dge_config = {
    debug = true,
    stride = 16
}

function init(self)
    dge.init(dge_config)
end
```

1. `debug`: Allow debug information to be printed to the terminal.
2. `stride`: Size of a single grid box (if you're using a tilemap, then this is likely equivalent to your tile size.)

Make sure to call `dge.init()` before registering any characters, as characters will not be registered correctly if `dge.init()` is called after character registration.

You may now register your characters like so:

```
local character_config = {
    size = vmath.vector3(16, 32, 0),
    direction = dge.direction.down,
    speed = 3
}

function init(self)
    self.dge = dge.register(character_config)
end
```

1. `size`: Size of your character in pixels.
2. `direction`: Initial direction in which your character is looking.
3. `speed`: Movement speed in grid boxes per second.

DGE snaps your character into a grid box on registration. To do this, the bottom-center `stride x stride` square region of your character is used to properly position it onto the grid. This snapped position is important because it affects the return value of the `self.dge.reach()` function as well as other movement mechanics. In the future, this region will be modifiable and will be relevant in collision response, utility functions, and more.

You may now utilize all of DGE's features by referencing `self.dge.FUNCTION_NAME()`.

In addition to initialization and registration, you must also include updating and unregistration in your character's script:

```
function update(self, dt)
    self.dge.update(dt)
end

function final(self)
    self.dge.unregister()
end
```

## API: Properties

### dge.direction

Table for referencing character orientation.

```
dge.direction = {
    up = { value = 1, string = "up" },
    left = { value = 2, string = "left" },
    down = { value = 4, string = "down" },
    right = { value = 8, string = "right" }
}
```

1. `value`: ID value of this direction.  
2. `string`: String representation of this direction.

### dge.msg

Table for referencing messages posted to your character's `on_message()` function:

```
dge.msg = {
    move_start = hash("move_start"),
    move_end = hash("move_end"),
    move_repeat = hash("move_repeat")
}
```

1. `move_start`: Posted when the character starts moving from rest.
2. `move_end`: Posted when the character stops moving.
3. `move_repeat`: Posted when the character continues moving between grid boxes without stopping.

## API: Functions

### dge.init(config)

Initializes DGE. Must be called before registering any characters.

#### Parameters
1. `config`: Table for configuring DGE.
    1. `debug`: `bool` indicating whether to print debug information to the terminal.
    2. `stride`: `integer` denoting the size of a single grid box (if you're using a tilemap, then this is likely equivalent to your tile size.)

---

### dge.get_debug()

Checks if debug is enabled.

#### Returns

Returns a `bool`.

---

### dge.set_debug(debug)

Sets debug mode.

#### Parameters
1. `debug`: `bool` indicating whether to print debug information to the terminal.

---

### dge.to_pixel_coordinates(grid_coordinates)

Converts grid coordinates to pixel coordinates. The returned pixel coordinates point to the center of the grid box.

#### Parameters
1. `grid_coordinates`: `vector3` denoting the grid box to convert. The `z` component remains unchanged.

#### Returns

Returns a `vector3`.

---

### dge.to_grid_coordinates(pixel_coordinates)

Converts pixel coordinates to grid coordinates.

#### Parameters
1. `pixel_coordinates`: `vector3` denoting the pixel to convert. The `z` component remains unchanged.

#### Returns

Returns a `vector3`.

---

### dge.register(config)

Registers the current game object in the grid system.

#### Parameters
1. `config`: Table for setting up this character's properties.
    1. `size`: `vector3` of `integer`s specifying this character's dimensions in pixels.
    2. `direction`: Initial `dge.direction` in which your character is looking.
    3. `speed`: Movement speed in grid boxes per second.

#### Returns

Returns an instance of DGE. Use this to access all `self.dge.FUNCTION_NAME()` functions.

---

### self.dge.get_direction()

Gets the `dge.direction` in which this character is looking.

#### Returns

Returns a table. See the [`dge.direction` table](#dgedirection) for details.

---

### self.dge.get_speed()

Gets the speed of this character in grid boxes per second.

#### Returns

Returns a number.

---

### self.dge.set_speed(speed)

Sets the speed of this character in grid boxes per second.

#### Parameters
1. `speed`: Speed of this character in grid boxes per second.

---

### self.dge.get_moving()

Checks if this character is moving.

#### Returns

Returns a `bool`.

---

### self.dge.get_position()

Gets the position of this character in grid coordinates.

#### Returns

Returns a `vector3`.

---

### self.dge.reach()

Gets the position of the grid box directly in front of this character in grid coordinates.

#### Returns

Returns a `vector3`.

---

### self.dge.move_up()

Begin moving upward. Movement will continue until `self.dge.stop_up()` is called.

---

### self.dge.move_left()

Begin moving leftward. Movement will continue until `self.dge.stop_left()` is called.

---

### self.dge.move_down()

Begin moving downward. Movement will continue until `self.dge.stop_down()` is called.

---

### self.dge.move_right()

Begin moving rightward. Movement will continue until `self.dge.stop_right()` is called.

---

### self.dge.stop_up()

Stop moving upward.

---

### self.dge.stop_left()

Stop moving leftward.

---

### self.dge.stop_down()

Stop moving downward.

---

### self.dge.stop_right()

Stop moving rightward.

---

### self.dge.look_up()

Changes this character's `dge.direction` to `dge.direction.up`. This affects the return value of funtions such as `self.dge.reach()`. This is also useful for simply turning a character in some direction without actually moving.

---

### self.dge.look_left()

Changes this character's `dge.direction` to `dge.direction.left`. This affects the return value of funtions such as `self.dge.reach()`. This is also useful for simply turning a character in some direction without actually moving.

---

### self.dge.look_down()

Changes this character's `dge.direction` to `dge.direction.down`. This affects the return value of funtions such as `self.dge.reach()`. This is also useful for simply turning a character in some direction without actually moving.

---

### self.dge.look_right()

Changes this character's `dge.direction` to `dge.direction.right`. This affects the return value of funtions such as `self.dge.reach()`. This is also useful for simply turning a character in some direction without actually moving.

---

### self.dge.update(dt)

Updates all relevant properties. Must be called in this character's `update()` function.

#### Properties
1. `dt`: Change in time since last frame.

---

### self.dge.unregister()

Unregisters this character from DGE. Must be called in this character's `final()` function.
