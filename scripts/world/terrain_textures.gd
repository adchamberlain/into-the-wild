extends RefCounted
class_name TerrainTextures
## Generates 16x16 pixelated textures for terrain at runtime.
## Provides a Minecraft-like aesthetic with procedural pixel variation.

# Texture atlas containing all terrain textures
static var texture_atlas: ImageTexture
static var atlas_generated: bool = false

# Atlas layout (16x16 pixels each, 4 textures in 2x2 grid = 32x32 atlas)
# [grass_top] [grass_side]
# [dirt     ] [stone     ]
const ATLAS_SIZE: int = 32
const TEXTURE_SIZE: int = 16

# UV offsets for each texture type (in 0-1 range)
const UV_GRASS_TOP: Vector2 = Vector2(0.0, 0.0)
const UV_GRASS_SIDE: Vector2 = Vector2(0.5, 0.0)
const UV_DIRT: Vector2 = Vector2(0.0, 0.5)
const UV_STONE: Vector2 = Vector2(0.5, 0.5)

# UV size for one texture in the atlas
const UV_SIZE: float = 0.5


static func get_texture_atlas() -> ImageTexture:
	if not atlas_generated:
		_generate_atlas()
	return texture_atlas


static func _generate_atlas() -> void:
	# Create atlas image
	var atlas_img: Image = Image.create(ATLAS_SIZE, ATLAS_SIZE, false, Image.FORMAT_RGB8)

	# Generate each texture and copy to atlas
	_generate_grass_top(atlas_img, 0, 0)
	_generate_grass_side(atlas_img, TEXTURE_SIZE, 0)
	_generate_dirt(atlas_img, 0, TEXTURE_SIZE)
	_generate_stone(atlas_img, TEXTURE_SIZE, TEXTURE_SIZE)

	# Create texture with nearest-neighbor filtering for pixelated look
	texture_atlas = ImageTexture.create_from_image(atlas_img)

	atlas_generated = true


static func _generate_grass_top(img: Image, offset_x: int, offset_y: int) -> void:
	## Neutral grey with subtle variation - vertex colors provide actual color
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345  # Fixed seed for consistency

	for y in TEXTURE_SIZE:
		for x in TEXTURE_SIZE:
			# Base neutral grey that won't tint vertex colors much
			var base_val: float = 0.85
			var noise_val: float = rng.randf_range(-0.08, 0.08)
			# Occasional darker spots for detail
			if rng.randf() < 0.1:
				noise_val = rng.randf_range(-0.15, 0.0)
			var val: float = clamp(base_val + noise_val, 0.65, 0.95)
			var pixel: Color = Color(val, val, val)
			img.set_pixel(offset_x + x, offset_y + y, pixel)


static func _generate_grass_side(img: Image, offset_x: int, offset_y: int) -> void:
	## Neutral texture - lighter at top (grass), darker below (dirt)
	## Vertex colors provide actual green/brown tints
	var grass_rows: int = 4
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 23456

	for y in TEXTURE_SIZE:
		for x in TEXTURE_SIZE:
			var noise_val: float = rng.randf_range(-0.06, 0.06)
			var val: float

			if y < grass_rows:
				# Grass section at top - lighter grey
				val = clamp(0.85 + noise_val, 0.70, 0.95)
			elif y == grass_rows:
				# Transition row - ragged edge
				if rng.randf() < 0.5:
					val = clamp(0.85 + noise_val, 0.70, 0.95)
				else:
					val = clamp(0.75 + noise_val, 0.60, 0.85)
			else:
				# Dirt section below - slightly darker grey
				val = clamp(0.75 + noise_val, 0.60, 0.85)

			var pixel: Color = Color(val, val, val)
			img.set_pixel(offset_x + x, offset_y + y, pixel)


static func _generate_dirt(img: Image, offset_x: int, offset_y: int) -> void:
	## Neutral grey with subtle variation - vertex colors provide brown tint
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 34567

	for y in TEXTURE_SIZE:
		for x in TEXTURE_SIZE:
			var noise_val: float = rng.randf_range(-0.06, 0.06)
			# Occasional darker spots (like pebbles/roots)
			if rng.randf() < 0.08:
				noise_val = rng.randf_range(-0.12, -0.04)
			var val: float = clamp(0.75 + noise_val, 0.55, 0.85)
			var pixel: Color = Color(val, val, val)
			img.set_pixel(offset_x + x, offset_y + y, pixel)


static func _generate_stone(img: Image, offset_x: int, offset_y: int) -> void:
	## Neutral grey with crack patterns - vertex colors provide stone tint
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 45678

	for y in TEXTURE_SIZE:
		for x in TEXTURE_SIZE:
			var noise_val: float = rng.randf_range(-0.05, 0.05)

			# Create crack patterns
			var is_crack: bool = false
			# Horizontal cracks
			if (y == 4 or y == 10) and rng.randf() < 0.7:
				is_crack = true
			# Vertical cracks
			if (x == 5 or x == 11) and rng.randf() < 0.5:
				is_crack = true
			# Random darker spots
			if rng.randf() < 0.05:
				is_crack = true

			var val: float
			if is_crack:
				val = clamp(0.60 + noise_val, 0.45, 0.70)
			else:
				val = clamp(0.80 + noise_val, 0.70, 0.90)
			var pixel: Color = Color(val, val, val)
			img.set_pixel(offset_x + x, offset_y + y, pixel)


## Get UV coordinates for a top face (grass_top texture).
## Returns array of 4 Vector2 UVs for the 4 corners.
static func get_top_face_uvs() -> Array[Vector2]:
	return [
		UV_GRASS_TOP,                                          # v0 - top-left of texture
		Vector2(UV_GRASS_TOP.x + UV_SIZE, UV_GRASS_TOP.y),     # v1 - top-right
		UV_GRASS_TOP + Vector2(UV_SIZE, UV_SIZE),              # v2 - bottom-right
		Vector2(UV_GRASS_TOP.x, UV_GRASS_TOP.y + UV_SIZE)      # v3 - bottom-left
	]


## Get UV coordinates for a side face (grass_side or dirt texture).
## tall_face: if true, uses grass_side (grass strip at top), else dirt only
static func get_side_face_uvs(tall_face: bool) -> Array[Vector2]:
	var base_uv: Vector2 = UV_GRASS_SIDE if tall_face else UV_DIRT
	return [
		base_uv,                                    # top-left
		Vector2(base_uv.x + UV_SIZE, base_uv.y),   # top-right
		base_uv + Vector2(UV_SIZE, UV_SIZE),       # bottom-right
		Vector2(base_uv.x, base_uv.y + UV_SIZE)    # bottom-left
	]


## Get UV coordinates for stone texture (for ROCKY regions).
static func get_stone_uvs() -> Array[Vector2]:
	return [
		UV_STONE,
		Vector2(UV_STONE.x + UV_SIZE, UV_STONE.y),
		UV_STONE + Vector2(UV_SIZE, UV_SIZE),
		Vector2(UV_STONE.x, UV_STONE.y + UV_SIZE)
	]
