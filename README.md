# Defold Grid Engine
Defold Grid Engine (DGE) 0.4.0 provides grid-based movement, interactions, and utility features to a Defold game engine project. Two examples of video game franchises that use grid-based systems are Pokémon and Fire Emblem.

Visit [my website](https://gymratgames.github.io/html/extensions.html#dge) to see an animated gif of the example project.  
An [example project](https://github.com/gymratgames/defold-grid-engine/tree/master/example) is available if you need additional help with configuration.

Please click the "Star" button on GitHub if you find this asset to be useful!  
If you wish to support me and the work I do, please consider becoming one of my [patrons](https://www.patreon.com/klaytonkowalski).

![alt text](https://github.com/gymratgames/defold-grid-engine/blob/master/assets/thumbnail.png?raw=true)

## Installation
To install DGE into your project, add one of the following links to your `game.project` dependencies:
  - https://github.com/gymratgames/defold-grid-engine/archive/master.zip
  - URL of a [specific release](https://github.com/gymratgames/defold-grid-engine/releases)

## Configuration
Import the DGE Lua module into your character's script:
`local dge = require "dge.dge"`

The grid system itself must be initialized before registering any characters. To initialize DGE, call `dge.init()` along with a `config` table:

```
local dge_config = {
    debug = true,
    stride = 16
}

local collision_map = {
    { 2, 2, 2, 2, 2 },
    { 2, 1, 1, 1, 2 },
    { 2, 1, 1, 1, 2 },
    { 2, 1, 1, 1, 2 },
    { 2, 2, 2, 2, 2 }
}

function init(self)
    dge.init(dge_config)
    dge.set_collision_map(collision_map)
end
```

1. `debug`: Allow debug information to be printed to the terminal.
2. `stride`: Size of a single grid box (probably equivalent to your tile size).

The `dge.set_collision_map()` function assigns a collision map to the grid. Collision maps consist of a two-dimensional array of integers, each of which corresponds to a collision tag. All tags can be found in the `dge.tag` [table](#dgetag). Custom tags may be inserted into the `dge.tag` table if you wish to detect additional collision cases. See all [tag-related functions](#dgeget_tagname) for details. **Note** that a collision map is not required if you are not interested in adding collisions to your game.

DGE will post a `dge.msg.collide_passable` or `dge.msg.collide_impassable` message to your character's `on_message()` function when your character collides with any grid box. If you did not specify a collision map, then `dge.msg.collide_none` will be posted instead. **Note** that if the bottom-left of your tilemap is not loaded at the origin of the game world, you should call `dge.set_collision_map_offset()` function, which allows you to shift your collision map to match up with the world position of your tilemap.

You may also insert user-defined data at any grid position into the `extra` table using `dge.set_extra()`. This may be useful for adding semantics to your tiles, such as specifying warp information to a door tile. See all [extra-related functions](#dgeget_extragx-gy) for details.

Configuration is now complete. Next step is to register your characters:

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
3. `speed`: Movement speed in grid boxes per second. If `speed = 0`, then movement is instant.

DGE snaps your character into a grid box on registration. To do this, the bottom-center <stride> x <stride> square region of your character is used to properly position it onto the grid.

You may now utilize all character-specific functions by referencing `self.dge.FUNCTION_NAME()`.

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

Table for referencing character orientation:

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
    move_repeat = hash("move_repeat"),
    collide_none = hash("collide_none"),
    collide_passable = hash("collide_passable"),
    collide_impassable = hash("collide_impassable")
}
```

1. `move_start`: Posted when your character starts moving from rest.
2. `move_end`: Posted when your character stops moving.
3. `move_repeat`: Posted when your character continues moving between grid boxes without stopping.
4. `collide_none`: Posted when your character collides with any grid box which lies outside of the supplied collision map. The `message.extra` field contains the user-defined data at this grid position or `nil`.
5. `collide_passable`: Posted when your character collides with any passable grid box. The `message.name` field contains the tag's hashed `name` string. The `message.extra` field contains the user-defined data at this grid position or `nil`.
6. `collide_impassable`: Posted when your character collides with any impassable grid box. The `message.name` field contains the tag's hashed `name` string. The `message.extra` field contains the user-defined data at this grid position or `nil`.

### dge.tag

Table for referencing collision tags. Each key (index of tag) corresponds to the integer used in your collision map, which was passed to `dge.set_collision()` when you initialized DGE. Custom tags may be inserted if you wish to detect additional collision cases. See all [tag-related functions](#dgeget_tagname) for details.

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

### dge.is_debug_enabled()

Checks if debug is enabled.

#### Returns

Returns a `bool`.

---

### dge.set_debug(flag)

Sets debug mode.

#### Parameters
1. `flag`: `bool` indicating whether to print debug information to the terminal.

---

### dge.get_collision_map()

Gets the collision map passed to `dge.set_collision_map()`.

#### Returns

Returns a table of lists of integers in the following format:

```
{
    { <tag_key>, ... },
    ...
}
```

---

### dge.set_collision_map(collision_map)

Sets the collision map.

#### Parameters
1. `collision_map`: Table of lists of integers in the following format:

```
{
    { <tag_key>, ... },
    ...
}
```

---

### dge.set_collision_map_offset(gx, gy)

Sets the collision map offset. If the bottom-left of your tilemap is not loaded at the origin of the game world, then this function will allow you to shift your collision map to match up with the world position of your tilemap.

#### Parameters
1. `gx`: Number of grid boxes to shift horizontally.
2. `gy`: Number of grid boxes to shift vertically.

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

Returns the key integer of the added tag. This key may be used in a collision map passed to `dge.set_collision_map()`.

---

### dge.get_extra(gx, gy)

Gets extra data.

#### Parameters
1. `gx`: X-coordinate of grid box.
2. `gy`: Y-coordinate of grid box.

#### Returns

Returns user-defined data.

---

### dge.set_extra(extra, gx, gy)

Sets extra data.

#### Parameters
1. `extra`: User-defined data.
2. `gx`: X-coordinate of grid box.
3. `gy`: Y-coordinate of grid box.

---

### dge.clear_extra()

Clears all extra data.

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

### dge.is_within_collision_map_bounds(gx, gy)

Checks if the grid coordinates <gx, gy> lie inside the collision map bounds.

#### Parameters
1. `gx`: X-coordinate of grid box.
2. `gy`: Y-coordinate of grid box.

#### Returns

Returns three values:
1. `bool` result.
2. Number denoting the x-index in the collision map array of `gx`. This number may be equivalent to `gx`, however it will be different if your collision map has been shifted using the `dge.set_collision_map_offset()` function.
3. Number denoting the y-index in the collision map array of `gy`. This number may be equivalent to the inverse of `gy`, however it will be different if your collision map has been shifted using the `dge.set_collision_map_offset()` function.

The numerical return values are unlikely to be useful, however they still exist due to being used internally.

---

### dge.register(config)

Registers the current game object in the grid system.

#### Parameters
1. `config`: Table for setting up this character's properties.
    1. `size`: `vector3` of integers specifying this character's dimensions in pixels.
    2. `direction`: Initial `dge.direction` in which your character is looking.
    3. `speed`: Movement speed in grid boxes per second. If `speed = 0`, then movement is instant.

#### Returns

Returns an instance of DGE. Use this to access all `self.dge.FUNCTION_NAME()` functions.

---

### self.dge.get_direction()

Gets the `dge.direction` in which this character is looking.

#### Returns

Returns a table. See the `dge.direction` [table](#dgedirection) for details.

---

### self.dge.set_direction(direction)

Sets the `dge.direction` in which this character is looking. This affects the return value of funtions such as `self.dge.reach()`. This is also useful for simply turning a character in some direction without actually moving.

#### Parameters
1. `direction`: Table referenced from the `dge.direction` [table](#dgedirection).

---

### self.dge.get_speed()

Gets the speed of this character in grid boxes per second.

#### Returns

Returns a number.

---

### self.dge.set_speed(speed)

Sets the speed of this character in grid boxes per second.

#### Parameters
1. `speed`: Speed of this character in grid boxes per second. If `speed = 0`, then movement is instant.

---

### self.dge.is_moving()

Checks if this character is moving.

#### Returns

Returns a `bool`.

---

### self.dge.set_movement_gate(gate)

Toggles this character's movement ability.

#### Parameters
1. `gate`: `bool` indicating whether to allow movement.

---

### self.dge.add_lerp_callback(callback, volatile)

Adds a lerp callback, which triggers upon each complete character movement.

#### Parameters
1. `callback`: Callback function.
2. `volatile`: `bool` indicating whether to remove this callback after being triggered once.

---

### self.dge.remove_lerp_callback(callback, volatile)

Removes a lerp callback, which triggers upon each complete character movement. Does nothing if the specified callback does not exist.

#### Parameters
1. `callback`: Callback function.
2. `volatile`: `bool` indicating whether to remove this callback after being triggered once.

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
