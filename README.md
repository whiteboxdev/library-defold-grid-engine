# Defold Grid Engine
Defold Grid Engine (DGE) 0.2.0 provides grid-based movement, interactions, and utility features to a Defold game engine project. Two examples of video game franchises that use grid-based systems are Pokémon and Fire Emblem.

Visit [my website](https://gymratgames.github.io/html/extensions.html#dge) to see an animated gif of the example project.  
An [example project](https://github.com/gymratgames/defold-grid-engine/tree/master/example) is available if you need additional help with configuration.

## Installation
To install DGE into your project, add one of the following links to your `game.project` dependencies:
  - https://github.com/gymratgames/defold-grid-engine/archive/master.zip
  - URL of a [specific release](https://github.com/gymratgames/defold-grid-engine/releases)

## Configuration
Import the DGE Lua module into your character's script:
`local dge = require "dge.dge"`

The grid system itself must be initialized before registering any characters. To initialize DGE, call `dge.init()` followed by `dge.set_collision()`. Make sure to call `dge.init()` before registering any characters:

```
local dge_config = {
    debug = true,
    stride = 16
}

local collision = {
    { 2, 2, 2, 2, 2 },
    { 2, 1, 1, 1, 2 },
    { 2, 1, 1, 1, 2 },
    { 2, 1, 1, 1, 2 },
    { 2, 2, 2, 2, 2 }
}

function init(self)
    dge.init(dge_config)
    dge.set_collision(collision)
end
```

1. `debug`: Allow debug information to be printed to the terminal.
2. `stride`: Size of a single grid box (if you're using a tilemap, then this is likely equivalent to your tile size.)

The `dge.set_collision()` function assigns a collision map to the grid. Collision maps consist of a table of lists of `integer`s, where each `integer` corresponds to a collision tag key. All tag keys can be found in the [`dge.tag` table](#dgetag). DGE will post a `dge.msg.collide_passable` or `dge.msg.collide_impassable` message to your character's `on_message()` function when your character collides with any grid box. Custom tags may be inserted into the `dge.tag` table if you wish to detect additional collision cases. See all [tag-related functions](#dgegettagname) for details.

You may now register your characters:

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

1. `value`: Identification value of this direction.  
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

### dge.tag

Table for referencing collision tags. Each key (index of tag) corresponds to the integer used in your collision map, which was passed to `dge.set_collision()` when you initialized DGE. Custom tags may be inserted if you wish to detect additional collision cases. See all [tag-related functions](#dgegettagname) for details.

```
dge.tag = {
    { name = hash("passable"), passable = true },
    { name = hash("impassable"), passable = false }
}
```

1. `name`: Hash of a string representation of this tag.
2. `passable`: `bool` indicating whether characters may pass through grid boxes assigned to this tag.

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

### dge.get_collision()

Gets the collision map passed to `dge.set_collision()`.

#### Returns

Returns a table of lists of `integer`s in the following format:

```
{
    { <tag_key>, ... },
    ...
}
```

---

### dge.set_collision(collision)

Sets the collision map.

#### Parameters
1. `collision`: Table of lists of `integer`s in the following format:

```
{
    { <tag_key>, ... },
    ...
}
```

---

### dge.get_tag(name)

Gets tag information.

#### Parameters
1. `name`: Hash of a string representation of a tag.

#### Returns

Returns a table in the following format:

```
{
    key = <tag_key>,
    value = { name = hash("<tag_name>"), passable = <bool> }
}
```

---

### dge.set_tag(name, passable)

Sets an existing tag's `passable` flag.

#### Parameters
1. `name`: Hash of a string representation of a tag.
2. `passable`: `bool` indicating whether characters may pass through grid boxes assigned to this tag.

---

### dge.add_tag(name, passable)

Adds a tag to the `dge.tag` table.

#### Parameters
1. `name`: Hash of a string representation of a tag.
2. `passable`: `bool` indicating whether characters may pass through grid boxes assigned to this tag.

#### Returns

Returns the key `integer` of the added tag. This key may be used in a collision map passed to `dge.set_collision()`.

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

### self.dge.set_direction(direction)

Sets the `dge.direction` in which this character is looking. This affects the return value of funtions such as `self.dge.reach()`. This is also useful for simply turning a character in some direction without actually moving--hence its previous name `self.dge.look_DIRECTION()`.

#### Parameters
1. `direction`: Table referenced from the [`dge.direction` table](#dgedirection).

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

### self.dge.set_position(grid_coordinates)

Sets the position of this character in grid coordinates.

#### Parameters
1. `grid_coordinates`: `vector3` denoting the grid box to convert.

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

### self.dge.update(dt)

Updates all relevant properties. Must be called in this character's `update()` function.

#### Properties
1. `dt`: Change in time since last frame.

---

### self.dge.unregister()

Unregisters this character from DGE. Must be called in this character's `final()` function.
