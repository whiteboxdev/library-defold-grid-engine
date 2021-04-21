# Defold Grid Engine
Defold Grid Engine (dgrid) 0.4.2 provides grid-based movement, interactions, and utility features to a Defold game engine project.

An [example project](https://github.com/klaytonkowalski/defold-grid-engine/tree/master/example) is available if you need additional help with configuration.  
Visit my [Giphy](https://media.giphy.com/media/YFnSgIm0DdVJmTmN3N/giphy.gif) to see an animated gif of the example project.

Please click the "Star" button on GitHub if you find this asset to be useful!

![alt text](https://github.com/klaytonkowalski/defold-grid-engine/blob/master/assets/thumbnail.png?raw=true)

## Installation
To install dgrid into your project, add one of the following links to your `game.project` dependencies:
  - https://github.com/klaytonkowalski/defold-grid-engine/archive/master.zip
  - URL of a [specific release](https://github.com/klaytonkowalski/defold-grid-engine/releases)

## Configuration
Import the dgrid Lua module into your character's script:
`local dgrid = require "dgrid.dgrid"`

The grid system itself must be initialized before registering any characters:

```
local grid_box_size = 16

local collision_map = {
    { 2, 2, 2, 2, 2 },
    { 2, 1, 1, 1, 2 },
    { 2, 1, 1, 1, 2 },
    { 2, 1, 1, 1, 2 },
    { 2, 2, 2, 2, 2 }
}

local property_map = {
    ["31"] = { bonus_points = 1000 },
    ["55"] = { bonus_points = 2000 }
}

function init(self)
    dgrid.set_stride(grid_box_size)
    dgrid.set_collision_map(collision_map)
    dgrid.set_property_map(property_map)
end
```

The `dgrid.set_stride()` function sets the size of each grid box. In the example above, each grid box is set to 16 pixels.

The `dgrid.set_collision_map()` function assigns a collision map to the grid. Collision maps consist of a two-dimensional array of integers, each of which corresponds to a collision tag. All tags can be found in the `dgrid.tag` [table](#dgridtag). Custom tags may be inserted into the `dgrid.tag` table if you wish to detect additional collision cases. dgrid will post a `dgrid.msg.collide_passable` or `dgrid.msg.collide_impassable` message to your character's `on_message()` function when your character collides with any grid box. If you did not specify a collision map, then `dgrid.msg.collide_none` will be posted instead.

The `dgrid.set_property_map()` function assigns a property map to the grid. Property maps consist of a table of custom data. The purpose of this map is to assign semantics to your grid boxes. Keys correspond to the x and y coordinates of the targetted grid box, while values correspond to the custom data. When a character collides with a grid box that contains custom data, the data is attached to the `dgrid.msg.collide` messages as the `message.property` field. In the example above, colliding with the grid box at coordinates <3, 1> will send a `message.property` value of `{ bonus_points = 1000 }`.

If the bottom-left of your tilemap is not located at the origin of the game world, you should call the `dgrid.set_map_offset()` function, which allows you to shift your collision and property maps to match up with the world position of your tilemap.

Configuration is complete. Next step is to register your characters:

```
local config = {
    size = vmath.vector3(16, 32, 0),
    direction = dgrid.direction.down,
    speed = 3
}

function init(self)
    self.dgrid = dgrid.register(config)
end
```

1. `size`: Size of your character in pixels.
2. `direction`: Initial direction in which your character is looking.
3. `speed`: Movement speed in grid boxes per second. If `speed = 0`, then movement is instant.

dgrid snaps your character into a grid box on registration. To do this, the bottom-center `stride x stride` square region of your character is used to properly position it onto the grid.

Finally, make sure to call `self.dgrid.update()` and `self.dgrid.unregister()` in your character's script:

```
function update(self, dt)
    self.dgrid.update(dt)
end

function final(self)
    self.dgrid.unregister()
end
```

## API: Properties

### dgrid.direction

Table for referencing character orientation:

```
dgrid.direction = {
	up = { value = 1, string = "up", offset = vmath.vector3(0, 1, 0) },
	left = { value = 2, string = "left", offset = vmath.vector3(-1, 0, 0) },
	down = { value = 3, string = "down", offset = vmath.vector3(0, -1, 0) },
	right = { value = 4, string = "right", offset = vmath.vector3(1, 0, 0) }
}
```

1. `value`: Identification value of this direction.  
2. `string`: Name of this direction.  
3. `offset`: Coordinate offset of this direction.

### dgrid.msg

Table for referencing messages posted to your character's `on_message()` function:

```
dgrid.msg = {
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
4. `collide_none`: Posted when your character collides with any grid box which lies outside of the supplied collision map. The `message.property` field contains the user-defined data at this grid position.
5. `collide_passable`: Posted when your character collides with any passable grid box. The `message.name` field contains the tag's hashed `name` string. The `message.property` field contains the user-defined data at this grid position.
6. `collide_impassable`: Posted when your character collides with any impassable grid box. The `message.name` field contains the tag's hashed `name` string. The `message.property` field contains the user-defined data at this grid position.

### dgrid.tag

Table for referencing collision tags. Each key (index of tag) corresponds to an integer used in your collision map. Custom tags may be inserted if you wish to detect additional collision cases.

```
dgrid.tag = {
    { name = hash("passable"), passable = true },
    { name = hash("impassable"), passable = false }
}
```

1. `name`: Hashed name of this tag.
2. `passable`: `bool` indicating whether characters may pass through grid boxes assigned to this tag.

## API: Functions

### dgrid.get_stride()

Gets the size of each grid box in pixels.

#### Returns

Returns a number.

---

### dgrid.get_collision_map()

Gets the collision map.

#### Returns

Returns a table of lists of integers in the following format:

```
{
    { <tag>, ... },
    ...
}
```

---

### dgrid.get_property_map()

Gets the property map.

#### Returns

Returns a table of custom data. Keys correspond to the x and y coordinates of the targetted grid box, while values correspond to the custom data:

```
{
    ["xy"] = { ... },
    ...
}
```

---

### dgrid.get_map_offset()

Gets the collision and property map offset.

#### Returns

Returns a `vector3`.

---

### dgrid.get_tag(name)

Gets tag information.

#### Parameters
1. `name`: Hashed name of a tag.

#### Returns

Returns a table in the following format:

```
{
    key = <tag>,
    value = { name = hash("<tag_name>"), passable = <bool> }
}
```

---

### dgrid.to_pixel_position(grid_position)

Converts grid coordinates to pixel coordinates. The returned pixel coordinates point to the center of the grid box.

#### Parameters
1. `grid_position`: `vector3` denoting the grid box to convert. The `z` component remains unchanged.

#### Returns

Returns a `vector3`.

---

### dgrid.to_grid_position(pixel_position)

Converts pixel coordinates to grid coordinates.

#### Parameters
1. `pixel_position`: `vector3` denoting the pixel to convert. The `z` component remains unchanged.

#### Returns

Returns a `vector3`.

---

### dgrid.to_map_position(grid_position)

Converts grid coordinates to map coordinates. Map coordinates take into account the `map_offset`.

#### Parameters
1. `grid_position`: `vector3` denoting the grid box to convert. The `z` component remains unchanged.

#### Returns

Returns a `vector3`.

---

### dgrid.set_stride(stride)

Sets the size of each grid box in pixels.

#### Parameters
1. `stride`: Size of each grid box in pixels.

---

### dgrid.set_collision_map(collision_map)

Sets the collision map.

#### Parameters
1. `collision_map`: Table of lists of integers in the following format:

```
{
    { <tag>, ... },
    ...
}
```

---

### dgrid.set_property_map(property_map)

Sets the property map.

#### Parameters
1. `property_map`: Table of custom data. Keys correspond to the x and y coordinates of the targetted grid box, while values correspond to the custom data:

```
{
    ["xy"] = { ... },
    ...
}
```

---

### dgrid.set_map_offset(offset)

Sets the collision and property map offset. If the bottom-left of your tilemap is not loaded at the origin of the game world, then this function will allow you to shift your collision property maps to match up with the world position of your tilemap.

#### Parameters
1. `offset`: `vector3` denoting number of grid boxes to shift.

---

### dgrid.set_tag(name, passable)

Sets an existing tag's `passable` flag.

#### Parameters
1. `name`: Hashed name of tag.
2. `passable`: `bool` indicating whether characters may pass through grid boxes assigned to this tag.

---

### dgrid.add_tag(name, passable)

Adds a tag to the `dgrid.tag` table.

#### Parameters
1. `name`: Hashed name of tag.
2. `passable`: `bool` indicating whether characters may pass through grid boxes assigned to this tag.

#### Returns

Returns the tag's integer value which may be used when constructing your collision map.

---

### dgrid.register(config)

Registers the current game object in the grid system.

#### Parameters
1. `config`: Table for setting up this character's properties.
    1. `size`: `vector3` of integers specifying this character's dimensions in pixels.
    2. `direction`: Initial `dgrid.direction` in which your character is looking.
    3. `speed`: Movement speed in grid boxes per second. If `speed = 0`, then movement is instant.

#### Returns

Returns an instance of dgrid.

---

### self.dgrid.get_size()

Gets the size of this character in pixels.

#### Returns

Returns a number.

---

### self.dgrid.get_direction()

Gets the `dgrid.direction` in which this character is looking.

#### Returns

Returns an entry of the `dgrid.direction` [table](#dgriddirection).

---

### self.dgrid.get_speed()

Gets the speed of this character in grid boxes per second.

#### Returns

Returns a number.

---

### self.dgrid.is_moving()

Checks if this character is moving.

#### Returns

Returns a `bool`.

---

### self.dgrid.is_forcing_movement()

Checks if this character is able to move through impassable grid boxes specified by the collision map.

#### Returns

Returns a `bool`.

---

### self.dgrid.get_grid_position()

Gets the grid coordinates of this character.

#### Returns

Returns a `vector3`.

---

### self.dgrid.get_map_position()

Gets the map coordinates of this character. Map coordinates take into account the `map_offset`.

#### Returns

Returns a `vector3`.

---

### self.dgrid.reach()

Gets the position of the grid box directly in front of this character in grid coordinates.

#### Returns

Returns a `vector3`.

---

### self.dgrid.set_direction(direction)

Sets the `dgrid.direction` in which this character is looking. This affects the return value of funtions such as `self.dgrid.reach()`. This is also useful for simply turning a character in some direction without actually moving.

#### Parameters
1. `direction`: Entry in the `dgrid.direction` [table](#dgriddirection).

---

### self.dgrid.set_speed(speed)

Sets the speed of this character in grid boxes per second.

#### Parameters
1. `speed`: Speed of this character in grid boxes per second. If `speed = 0`, then movement is instant.

---

### self.dgrid.force_movement(flag)

Allows this character to move through impassable grid boxes as specified by the collision map.

#### Parameters
1. `flag`: `bool` indicating whether to force movement.

---

### self.dgrid.add_lerp_callback(callback, volatile)

Adds a lerp callback, which triggers upon each complete character movement.

#### Parameters
1. `callback`: Callback function.
2. `volatile`: `bool` indicating whether to remove this callback after being triggered once.

---

### self.dgrid.remove_lerp_callback(callback, volatile)

Removes a lerp callback, which triggers upon each complete character movement. Does nothing if the specified callback does not exist.

#### Parameters
1. `callback`: Callback function.
2. `volatile`: `bool` indicating whether to remove this callback after being triggered once.

---

### self.dgrid.set_grid_position(grid_position)

Sets the position of this character in grid coordinates.

#### Parameters
1. `grid_position`: `vector3` denoting the grid box to warp to.

---

### self.dgrid.move(direction)

Begin moving in some direction. Movement will continue until `self.dgrid.stop()` is called.

#### Parameters
1. `direction`: Entry in the `dgrid.direction` [table](#dgriddirection).

---

### self.dgrid.stop(direction)

Stop moving in some direction.

#### Parameters
1. `direction`: Entry in the `dgrid.direction` [table](#dgriddirection). Omit this argument if you wish to stop movement in all directions instead of just one.

---

### self.dgrid.update(dt)

Updates all relevant properties. Must be called in this character's `update()` function.

#### Properties
1. `dt`: Change in time since last frame.

---

### self.dgrid.unregister()

Unregisters this character from dgrid. Must be called in this character's `final()` function.
