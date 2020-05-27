# Defold Grid Engine
Defold Grid Engine (DGE) provides grid-based movement, interactions, and utility features to a Defold game engine project. Two examples of video game franchises that use grid-based systems are Pokémon and Fire Emblem. If your game uses tilemaps and you're looking to benefit from all of the perks that a grid-based system ensures, then DGE is for you.

Visit [my website](https://gymratgames.github.io/html/extensions.html#dge) to see an animated gif of the example project.

## Installation
To install DGE into your project, add one of the following to your game.project dependencies:
  - https://github.com/gymratgames/defold-grid-engine/archive/master.zip
  - URL of a [specific release](https://github.com/gymratgames/defold-grid-engine/releases)

## Configuration
To begin, import the DGE Lua module into your character's script like so:  
`local dge = require "dge.dge"`

The grid system itself must be initialized before registering any characters. To initialize DGE, simply call `dge.init()` like so:

```
local dge_config = {
    debug = true,
    stride = 16,
    ordinal = false
}

function init(self)
    dge.init(dge_config)
end
```

1. `debug`: Allow debug information to be printed to the terminal.
2. `stride`: Size of a single grid box (if you're using a tilemap, then this is equivalent to your tile size.)
3. `ordinal`: Allow diagonal movement.

It is recommended that you initialize DGE in a script separate from your character script. This way, you do not accidentally redundantly initialize more than once. Moreover, characters will not be registered correctly if `dge.init()` is called *after* character registration.

Now that the system is initialized, register your character like so:

```
local character_config = {
    speed = 3
}

function init(self)
    self.dge = dge.register(character_config)
end
```

1. `speed`: Character movement speed in tiles per second.

You may now utilize all of DGE's features by referencing `self.dge.FUNCTION_NAME()`. See the [API](#dge-api-user-functions) section for more details.

In addition to initialization and registration, you must also include updating and unregistration in your character's script:

```
function update(self, dt)
    self.dge.update(dt)
end

function final(self)
    self.dge.unregister()
end
```

You're ready to use DGE! Note that DGE only needs to be initialized once, however initalizing more than once will not cause any errors. Also note that any characters not registered in the system may be freely controlled by the programmer--DGE does not conflict with any external character logic.

## DGE API: User Functions

### dge.register(config)

Registers the current game object in the grid system.

#### Parameters
1. `config`: Configuration table for setting up this character's properties.
    1. `speed`: Movement speed in tiles per second.

#### Returns

Returns an instance of DGE. Use this to access all `self.dge.FUNCTION_NAME()` functions.

### dge.toggle_debug()

Toggles debug mode. False by default. System feedback will be printed to the terminal.

### dge.get_stride()

Gets the system's stride. Stride refers to the size of a single grid box (if you're using a tilemap, then this is equivalent to your tile size.)

#### Returns

Returns a number.

### dge.set_stride(stride)

Sets the system's stride. Stride refers to the size of a single grid box (if you're using a tilemap, then this is equivalent to your tile size.)

#### Parameters
1. `stride`: Number denoting the stride value.

### dge.get_ordinal()

Checks ordinality. If true, then game objects may move diagonally.

#### Returns

Returns `true` or `false`.

### dge.set_ordinal(ordinal)

Sets ordinality. If true, then game objects may move diagonally.

#### Parameters
1. `ordinal`: `true` or `false`.

### dge.to_pixel_coordinates(grid_coordinates)

Converts pixel coordinates to grid coordinates.

#### Parameters
1. `grid_coordinates`: `vector3` of `integer`s. The `z` component is ignored.

#### Returns

Returns a `vector3` of `integer`s. The `z` component remains unchanged.

### self.dge.get_speed()

Gets movement speed in tiles per second.

#### Returns

Returns a number.

### self.dge.set_speed(speed)

Sets movement speed in tiles per second.

#### Parameters
1. `speed`: Number denoting movement speed in tiles per second.

### self.dge.is_moving()

Checks if the game object is currently moving.

#### Returns

Returns `true` or `false`.

### self.dge.get_direction()

Gets the direction in which the game object is currently facing.

#### Returns

Returns an `integer` conforming to the following table:

```
direction = {
	u  = 1,
	l  = 2,
	d  = 4,
	r  = 8,
	ul = 3,
	dl = 6,
	dr = 12,
	ur = 9
}
```

**Note**: You may reference the above table in your scripts like so: `dge.direction.DIRECTION_KEY`.

### self.dge.reach()

Allows for interaction with the tile directly in front of the game object.

#### Returns

Returns a `vector3` of `integer`s where `x` and `y` are grid coordinates of the tile directly in front of the game object. The `z` component is equal to the game object's `go.get_position().z` value. **Note**: Returns `nil` if the game object is currently moving.

### self.dge.move_up()

Move upward. This command will continue until `self.dge.stop_up()` is called.

### self.dge.move_left()

Move leftward. This command will continue until `self.dge.stop_left()` is called.

### self.dge.move_down()

Move downward. This command will continue until `self.dge.stop_down()` is called.

### self.dge.move_right()

Move rightward. This command will continue until `self.stop_right()` is called

### self.dge.stop_up()

Stop moving upward.

### self.dge.stop_left()

Stop moving leftward.

### self.dge.stop_down()

Stop moving downward.

### self.dge.stop_right()

Stop moving righward.

### self.dge.update(dt)

Updates all relevant properties including world position, input states, etc. Should be called every frame.

#### Parameters
1. `dt`: Seconds since last frame.

### self.dge.unregister()

Unregisters the current game object from the system. Should be called in `function final(self)`.

## Example

A minimalistic [example project](https://github.com/gymratgames/defold-grid-engine/tree/master/example) is available if you need additional help with configuration.

Visit [my website](https://gymratgames.github.io/html/extensions.html#dge) to see an animated gif of the example project.