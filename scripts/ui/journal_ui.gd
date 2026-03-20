extends CanvasLayer
## Full-screen UI for reading the Explorer's Journal found in the desert sinkhole.

signal journal_closed(was_first_read: bool)

var _is_first_read: bool = false
var _is_open: bool = false
var _current_page: int = 0
var _total_pages: int = 0

# Page content containers (rebuilt on page turn)
var _left_vbox: VBoxContainer
var _right_vbox: VBoxContainer

# Cached page data
var _pages: Array[Dictionary] = []

# UI nodes (created programmatically)
var background: ColorRect
var shadow: PanelContainer
var panel: PanelContainer

# Touch/swipe support for iOS
var _swipe_start: Vector2 = Vector2.ZERO
var _swipe_touch_index: int = -1
const SWIPE_THRESHOLD: float = 80.0  # Minimum swipe distance in pixels

const HUD_FONT: Font = preload("res://resources/hud_font.tres")


func _get_pages() -> Array[Dictionary]:
	var pages: Array[Dictionary] = []

	# Spread 1: Title page
	pages.append({
		"left_title": "Explorer's Journal",
		"left_text": "A Record of the Carlston Wilderness\n\n~ ~ ~\n\nProperty of M.W. Carlston",
		"right_text": "Day 1\n\nI arrived at the edge of the Carlston Wilderness this morning with little more than my boots and a good feeling. The forest here is beautiful — birch and pine standing so close together they form a kind of cathedral. Found a clear pond not far from where I set up camp. Fish rising at dusk. If I can rig a fishing rod, dinner is sorted.\n\nRabbits everywhere. Birds calling from every direction. The air smells like pine needles after rain. I've decided to map this whole place, every last corner of it. Something tells me it's worth the effort.",
		"is_title_page": true,
		"is_recipe_page": false,
	})

	# Spread 2: Day 5
	pages.append({
		"left_title": "Day 5",
		"left_text": "Getting the hang of things. River rocks and branches make surprisingly decent tools — a crude axe got me through my first tree. Twisted plant fibers into rope today and it's stronger than I expected. Splitting a log into branches is easy once you know the trick: one good whack along the grain.\n\nBuilt a workbench from logs and lashed branches. Having a proper work surface changes everything. Suddenly I can make things I couldn't before — a fishing rod, a berry pouch, even a drying rack for preserving food.",
		"right_text": "The pond near camp is a gift. I catch fish most evenings and hang them on the drying rack overnight. Berries grow thick along the forest floor. Found some herbs too — three of them mashed together make a healing salve that works remarkably well on cuts and scrapes.\n\nI'm eating better out here than I did back home. Built a lean-to shelter that keeps the rain off. This isn't just surviving — it's starting to feel like home.",
		"is_title_page": false,
		"is_recipe_page": false,
	})

	# Spread 3: Day 12
	pages.append({
		"left_title": "Day 12",
		"left_text": "Pushed north into the rocky highlands today. The forest gives way to stone and scrub grass, and the views open up wonderfully. Then I spotted it — a dark opening in the hillside, tucked between boulders. A cave entrance.\n\nLit a torch and stepped inside. I wasn't prepared for what I found. Crystals — pale blue, growing right out of the rock walls in beautiful clusters. Deeper in, veins of dark ore run through the stone. I chipped some free and it's heavy, good quality. This can be smelted into real metal.",
		"right_text": "I've found four cave entrances across the highlands so far. Each one is worth exploring — the crystals and ore inside are invaluable for better tools and equipment. A word of advice: bring plenty of torches. The caves go deep and it's easy to lose your bearings in the dark.\n\nA lantern is even better if you can make one — a couple of metal ingots and a crystal, and you've got a light source that lasts far longer than any torch. Well worth the investment before any serious spelunking.",
		"is_title_page": false,
		"is_recipe_page": false,
	})

	# Spread 4: Day 20
	pages.append({
		"left_title": "Day 20",
		"left_text": "Headed south and the world transformed. The trees fell away, the ground turned to warm sand, and suddenly I was in a desert. It rings the southern edge of the Carlston Wilderness — wide open, sun-baked, and absolutely gorgeous in its own way.\n\nThe real treasures are the oases. I've found three so far, each one a little paradise of palm trees and cool, clear water. Dove into the first pool on a whim and couldn't believe my eyes — diamonds, sitting right on the bottom, glinting in the sunlight filtering through the water.",
		"right_text": "Second oasis had diamonds too. The third is special — opals, milky and iridescent, nestled in the silt. A river flows to it from the east. I think the current carries the stones downstream and deposits them in the pool. Nature's own jewelry box.\n\nThe desert wildlife is charming. Lizards bask on every warm rock. I watched a tortoise amble past my camp without giving me so much as a glance. Cactus grows thick among the dunes — prickly, but fascinating. Everything out here has adapted beautifully to the heat.",
		"is_title_page": false,
		"is_recipe_page": false,
	})

	# Spread 5: Day 31
	pages.append({
		"left_title": "Day 31",
		"left_text": "I've been climbing the western mountains, and the views are worth every bit of effort. A grappling hook makes all the difference — rope and a couple of metal ingots, and you can reach ledges that seemed impossible from below.\n\nFrom the first peak, I could see the entire Carlston Wilderness spread out beneath me. The forest canopy rolling east. The desert glowing amber to the south. Rivers threading through the valleys. I sat up there for an hour just taking it in.",
		"right_text": "That's where the idea hit me. Looking out at all that open air, I thought — what if I could glide across it? Took me weeks to get the design right. A frame of sturdy branches, hide stretched tight over it, rope securing every joint. Simple materials, but the engineering has to be precise.\n\nThe first flight was magnificent. The wind catches you and suddenly the whole wilderness is yours to see from above. I've sketched the full plans in the back of this journal. If you can gather the materials, I promise you — it's the most extraordinary thing you'll experience out here.",
		"is_title_page": false,
		"is_recipe_page": false,
	})

	# Spread 6: Day 47
	pages.append({
		"left_title": "Day 47",
		"left_text": "Forty-seven days in the Carlston Wilderness. I've mapped every biome, explored every cave, climbed every peak, and befriended more rabbits than I can count. But the desert had one more surprise — a sinkhole, hidden in the sand, deeper than anything I'd found before.\n\nI climbed down carefully. At the bottom, water. Cool and still. I took a breath and dove in. What I found down there... well. Some discoveries are best made firsthand.",
		"right_text": "I'm leaving this journal on a pedestal at the bottom, for whoever comes next. Everything I've learned is in these pages — every place worth visiting, every recipe for every tool and structure that made this wilderness feel like home.\n\nThe Carlston Wilderness is a generous place if you're willing to explore it. Every oasis, every cave, every mountain peak has something wonderful waiting. Take your time. Build well. Climb high.\n\nHappy trails.\n\n— M.W. Carlston\n\nP.S. — If you ever want to find your way home, I marked the old ranger trail years ago. Start at the carved tree on the ridge that is due north of camp, about 430 paces. You'll know it when you see my initials. — M.W.C.",
		"is_title_page": false,
		"is_recipe_page": false,
	})

	# Spread 7: Hand Crafting recipes
	pages.append({
		"left_title": "Field Notes: Hand Crafting",
		"left_text": "These are the basics. You can make all of these with your hands and whatever you find on the ground.\n\nPrimitive Axe — 1 river rock, 1 branch\nStone Axe — 2 river rocks, 1 branch\nTorch — 2 branches\nPlant Rope — 3 branches",
		"right_text": "Split Branches — 1 wood log (yields 4)\nCampfire Kit — 4 branches, 3 river rocks\nCrafting Bench Kit — 6 wood, 4 branches\n\nThe crafting bench is the most important thing you'll build. Set it up at camp as early as you can — it unlocks everything that follows.",
		"is_title_page": false,
		"is_recipe_page": true,
	})

	# Spread 8: Getting Established recipes
	pages.append({
		"left_title": "Getting Established",
		"left_text": "With a bench and a camp, you can start building a real life out here.\n\nShelter Kit — 6 branches, 2 rope\nStorage Box — 4 wood, 1 rope\nDrying Rack Kit — 6 branches, 2 rope\nFishing Rod — 3 branches, 1 rope",
		"right_text": "Berry Pouch — 5 berries\nHealing Salve — 3 herbs\nMap — 3 birch bark, 2 berries\n\nThe map is worth making early. Birch bark peels easily from the white trees in the forest, and a couple of mashed berries make a surprisingly good ink.",
		"is_title_page": false,
		"is_recipe_page": true,
	})

	# Spread 9: Expanding Your Range recipes
	pages.append({
		"left_title": "Expanding Your Range",
		"left_text": "Once your camp is established, these will take you further into the wilderness.\n\nGarden Plot Kit — 4 wood, 2 herbs\nCanvas Tent Kit — 8 branches, 4 rope, 4 wood\nSnare Trap Kit — 2 rope, 4 branches\nMachete — 2 metal ingots, 1 branch",
		"right_text": "Grappling Hook — 3 rope, 2 metal ingots, 1 branch\nLeather Axe Wrap — 2 hide, 1 rope\nLeather Hook Wrap — 3 hide, 1 rope\nBow — 2 rope, 3 branches\nArrow Bundle (x20) — 2 feathers, 4 branches\n\nThe grappling hook opens up the highlands and the mountains. Don't leave camp without one once you've smelted enough metal.",
		"is_title_page": false,
		"is_recipe_page": true,
	})

	# Spread 10: Advanced Crafting recipes
	pages.append({
		"left_title": "Advanced Crafting",
		"left_text": "These require a well-developed camp and access to rarer materials from the caves and desert.\n\nCabin Kit — 30 wood, 20 branches, 10 river rocks, 6 rope\nSmithing Station Kit — 15 river rocks, 8 wood, 2 rope\nSmoker Kit — 10 wood, 6 river rocks, 2 rope\nWeather Vane Kit — 6 branches, 1 metal ingot",
		"right_text": "Metal Axe — 2 metal ingots, 2 branches\nLantern — 2 metal ingots, 1 crystal\nCompass and Lodestone — 2 rare ore, 1 metal ingot, 1 crystal\n\nThe compass is a marvel — it points true north, and the lodestone it comes with can be placed at camp as a beacon. You'll never lose your way home again.",
		"is_title_page": false,
		"is_recipe_page": true,
	})

	# Spread 11: Rare & Extraordinary recipes
	pages.append({
		"left_title": "Rare & Extraordinary",
		"left_text": "The finest things I crafted out here. Each one requires materials from deep in the caves or the desert oases.\n\nDiamond Axe — 2 diamonds, 1 metal ingot, 1 rope\nDiamond Arrows (x10) — 1 diamond, 5 branches, 2 feathers\nEnchanted Bow — 2 opals, 1 bow, 1 rope",
		"right_text": "Hang Glider — 4 rope, 6 branches, 2 hide\n\nThis is it — my greatest creation. The design took weeks to perfect but the materials are simple. Find a high peak, spread the wings, and run. The wind will do the rest.\n\nThe Carlston Wilderness looks different from up there. Better. Like it was made to be seen from the sky.",
		"is_title_page": false,
		"is_recipe_page": true,
	})

	return pages


func _ready() -> void:
	# Process even when tree is paused (we pause the tree while journal is open)
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	add_to_group("journal_ui")


func open_journal(is_first_read: bool) -> void:
	_is_first_read = is_first_read
	_is_open = true
	_current_page = 0
	_pages = _get_pages()
	_total_pages = _pages.size()
	_build_ui()
	SFXManager.play_sfx("menu_open")

	if OS.get_name() == "iOS":
		_apply_mobile_menu_style()

	# Pause the game tree
	get_tree().paused = true


func _build_ui() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	if vp_size == Vector2.ZERO:
		vp_size = Vector2(1920, 1080)
	var sf: float = vp_size.y / 1080.0

	var parchment_color: Color = Color(0.88, 0.82, 0.68)
	var leather_color: Color = Color(0.38, 0.24, 0.10)
	var spine_color: Color = Color(0.28, 0.16, 0.06)

	# Full-screen dark overlay
	background = ColorRect.new()
	background.color = Color(0.0, 0.0, 0.0, 0.75)
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Drop shadow behind book
	shadow = PanelContainer.new()
	var shadow_style: StyleBoxFlat = StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.0, 0.0, 0.0, 0.4)
	shadow_style.corner_radius_top_left = int(14 * sf)
	shadow_style.corner_radius_top_right = int(14 * sf)
	shadow_style.corner_radius_bottom_left = int(14 * sf)
	shadow_style.corner_radius_bottom_right = int(14 * sf)
	shadow.add_theme_stylebox_override("panel", shadow_style)
	shadow.anchor_left = 0.06
	shadow.anchor_top = 0.06
	shadow.anchor_right = 0.94
	shadow.anchor_bottom = 0.94
	shadow.offset_left = 4 * sf
	shadow.offset_top = 4 * sf
	shadow.offset_right = 4 * sf
	shadow.offset_bottom = 4 * sf
	add_child(shadow)

	# Leather cover panel (the book itself)
	panel = PanelContainer.new()
	var cover_style: StyleBoxFlat = StyleBoxFlat.new()
	cover_style.bg_color = leather_color
	cover_style.corner_radius_top_left = int(12 * sf)
	cover_style.corner_radius_top_right = int(12 * sf)
	cover_style.corner_radius_bottom_left = int(12 * sf)
	cover_style.corner_radius_bottom_right = int(12 * sf)
	cover_style.content_margin_left = int(10 * sf)
	cover_style.content_margin_right = int(10 * sf)
	cover_style.content_margin_top = int(10 * sf)
	cover_style.content_margin_bottom = int(10 * sf)
	panel.add_theme_stylebox_override("panel", cover_style)

	panel.anchor_left = 0.06
	panel.anchor_top = 0.06
	panel.anchor_right = 0.94
	panel.anchor_bottom = 0.94
	panel.offset_left = 0
	panel.offset_top = 0
	panel.offset_right = 0
	panel.offset_bottom = 0

	# HBox: left page | spine | right page
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(hbox)

	# --- Left page ---
	var left_page: PanelContainer = PanelContainer.new()
	var left_style: StyleBoxFlat = StyleBoxFlat.new()
	left_style.bg_color = parchment_color
	left_style.corner_radius_top_left = int(6 * sf)
	left_style.corner_radius_bottom_left = int(6 * sf)
	left_style.content_margin_left = int(24 * sf)
	left_style.content_margin_right = int(20 * sf)
	left_style.content_margin_top = int(20 * sf)
	left_style.content_margin_bottom = int(16 * sf)
	left_page.add_theme_stylebox_override("panel", left_style)
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_page.clip_contents = true

	var left_vbox: VBoxContainer = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", int(8 * sf))
	left_page.add_child(left_vbox)
	_left_vbox = left_vbox

	hbox.add_child(left_page)

	# --- Spine ---
	var spine_panel: PanelContainer = PanelContainer.new()
	var spine_style: StyleBoxFlat = StyleBoxFlat.new()
	spine_style.bg_color = spine_color
	spine_panel.add_theme_stylebox_override("panel", spine_style)
	spine_panel.custom_minimum_size = Vector2(20 * sf, 0)
	# Empty content to hold the minimum width
	var spine_spacer: Control = Control.new()
	spine_panel.add_child(spine_spacer)
	hbox.add_child(spine_panel)

	# --- Right page ---
	var right_page: PanelContainer = PanelContainer.new()
	var right_style: StyleBoxFlat = StyleBoxFlat.new()
	right_style.bg_color = parchment_color
	right_style.corner_radius_top_right = int(6 * sf)
	right_style.corner_radius_bottom_right = int(6 * sf)
	right_style.content_margin_left = int(20 * sf)
	right_style.content_margin_right = int(24 * sf)
	right_style.content_margin_top = int(20 * sf)
	right_style.content_margin_bottom = int(16 * sf)
	right_page.add_theme_stylebox_override("panel", right_style)
	right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_page.clip_contents = true

	var right_vbox: VBoxContainer = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", int(8 * sf))
	right_page.add_child(right_vbox)
	_right_vbox = right_vbox

	hbox.add_child(right_page)

	add_child(panel)

	# Populate the first page
	_populate_page()


## Build a line-drawing illustration for the given page index.
## Returns null for pages with no illustration (recipe pages).
func _build_illustration(page_index: int, sf: float) -> Control:
	var ink: Color = Color(0.35, 0.25, 0.12, 0.55)
	var w: float = 3.0 * sf
	var container: Control = Control.new()
	var h: float = 90 * sf  # original design height
	var draw_scale: float = 1.8
	container.custom_minimum_size = Vector2(0, h * draw_scale)
	container.size_flags_horizontal = Control.SIZE_FILL
	container.clip_contents = true

	# All Line2D children go into a scaled Node2D for bigger, centered drawings
	var drawing: Node2D = Node2D.new()
	drawing.scale = Vector2(draw_scale, draw_scale)
	container.add_child(drawing)

	# Center the drawing when the container gets its final width
	var design_cx: float = 145.0 * sf
	container.resized.connect(func() -> void:
		drawing.position.x = container.size.x / 2.0 - design_cx * draw_scale
		drawing.position.y = (container.size.y - h * draw_scale) / 2.0
	)

	if page_index == 0:
		# Compass rose
		var cx: float = 140 * sf
		var cy: float = h * 0.5
		var r: float = 30 * sf
		# Outer circle
		var circle: Line2D = Line2D.new()
		circle.width = w
		circle.default_color = ink
		for i: int in range(33):
			var a: float = i * TAU / 32.0
			circle.add_point(Vector2(cx + cos(a) * r, cy + sin(a) * r))
		drawing.add_child(circle)
		# Cardinal lines
		var pts: Array[Vector2] = [
			Vector2(cx, cy - r * 1.3), Vector2(cx, cy - r * 0.4),  # N
			Vector2(cx, cy + r * 0.4), Vector2(cx, cy + r * 1.3),  # S
			Vector2(cx - r * 1.3, cy), Vector2(cx - r * 0.4, cy),  # W
			Vector2(cx + r * 0.4, cy), Vector2(cx + r * 1.3, cy),  # E
		]
		for i: int in range(0, pts.size(), 2):
			var line: Line2D = Line2D.new()
			line.width = w
			line.default_color = ink
			line.add_point(pts[i])
			line.add_point(pts[i + 1])
			drawing.add_child(line)
		# N/S/E/W diamond points
		var diamond: Line2D = Line2D.new()
		diamond.width = w * 0.8
		diamond.default_color = ink
		diamond.add_point(Vector2(cx, cy - r * 0.4))
		diamond.add_point(Vector2(cx + r * 0.4, cy))
		diamond.add_point(Vector2(cx, cy + r * 0.4))
		diamond.add_point(Vector2(cx - r * 0.4, cy))
		diamond.add_point(Vector2(cx, cy - r * 0.4))
		drawing.add_child(diamond)

	elif page_index == 1:
		# Forest with trees and pond
		var ground: Line2D = Line2D.new()
		ground.width = w
		ground.default_color = ink
		ground.add_point(Vector2(10 * sf, h - 5 * sf))
		ground.add_point(Vector2(280 * sf, h - 5 * sf))
		drawing.add_child(ground)
		# Trees (triangles on trunks)
		var tree_positions: Array[float] = [40, 80, 130, 200, 250]
		var tree_heights: Array[float] = [55, 65, 50, 60, 45]
		for i: int in range(tree_positions.size()):
			var tx: float = tree_positions[i] * sf
			var th: float = tree_heights[i] * sf
			var base_y: float = h - 5 * sf
			# Trunk
			var trunk: Line2D = Line2D.new()
			trunk.width = w
			trunk.default_color = ink
			trunk.add_point(Vector2(tx, base_y))
			trunk.add_point(Vector2(tx, base_y - th * 0.35))
			drawing.add_child(trunk)
			# Canopy triangle
			var canopy: Line2D = Line2D.new()
			canopy.width = w
			canopy.default_color = ink
			canopy.add_point(Vector2(tx - 15 * sf, base_y - th * 0.3))
			canopy.add_point(Vector2(tx, base_y - th))
			canopy.add_point(Vector2(tx + 15 * sf, base_y - th * 0.3))
			canopy.add_point(Vector2(tx - 15 * sf, base_y - th * 0.3))
			drawing.add_child(canopy)
		# Pond (oval)
		var pond: Line2D = Line2D.new()
		pond.width = w
		pond.default_color = ink
		var pcx: float = 165 * sf
		var pcy: float = h - 8 * sf
		for i: int in range(25):
			var a: float = i * TAU / 24.0
			pond.add_point(Vector2(pcx + cos(a) * 25 * sf, pcy + sin(a) * 8 * sf))
		drawing.add_child(pond)

	elif page_index == 2:
		# Cave entrance with crystals
		var base_y: float = h - 5 * sf
		# Ground
		var ground: Line2D = Line2D.new()
		ground.width = w
		ground.default_color = ink
		ground.add_point(Vector2(10 * sf, base_y))
		ground.add_point(Vector2(90 * sf, base_y))
		drawing.add_child(ground)
		var ground2: Line2D = Line2D.new()
		ground2.width = w
		ground2.default_color = ink
		ground2.add_point(Vector2(200 * sf, base_y))
		ground2.add_point(Vector2(280 * sf, base_y))
		drawing.add_child(ground2)
		# Cave arch
		var arch: Line2D = Line2D.new()
		arch.width = w * 1.2
		arch.default_color = ink
		for i: int in range(21):
			var a: float = PI + i * PI / 20.0
			arch.add_point(Vector2(145 * sf + cos(a) * 55 * sf, base_y + sin(a) * 65 * sf))
		drawing.add_child(arch)
		# Crystals inside cave
		var crystal_positions: Array[Vector2] = [
			Vector2(120, 30), Vector2(135, 25), Vector2(155, 22),
			Vector2(170, 28), Vector2(145, 40),
		]
		for cp: Vector2 in crystal_positions:
			var crystal: Line2D = Line2D.new()
			crystal.width = w * 0.8
			crystal.default_color = ink
			crystal.add_point(Vector2(cp.x * sf, (cp.y + 12) * sf))
			crystal.add_point(Vector2((cp.x - 3) * sf, cp.y * sf))
			crystal.add_point(Vector2((cp.x + 3) * sf, cp.y * sf))
			crystal.add_point(Vector2(cp.x * sf, (cp.y + 12) * sf))
			drawing.add_child(crystal)
		# Stalactites
		for sx: float in [110, 130, 160, 180]:
			var stal: Line2D = Line2D.new()
			stal.width = w * 0.6
			stal.default_color = ink
			var top_y: float = base_y - 60 * sf + abs(sx - 145) * 0.3 * sf
			stal.add_point(Vector2(sx * sf, top_y))
			stal.add_point(Vector2(sx * sf, top_y + 10 * sf))
			drawing.add_child(stal)

	elif page_index == 3:
		# Desert with palm trees and oasis
		var base_y: float = h - 5 * sf
		# Wavy sand dunes
		var dunes: Line2D = Line2D.new()
		dunes.width = w
		dunes.default_color = ink
		for i: int in range(29):
			var x: float = (10 + i * 10) * sf
			var y: float = base_y - sin(i * 0.6) * 8 * sf
			dunes.add_point(Vector2(x, y))
		drawing.add_child(dunes)
		# Palm trees
		for px: float in [60, 180]:
			# Curved trunk
			var trunk: Line2D = Line2D.new()
			trunk.width = w
			trunk.default_color = ink
			for i: int in range(9):
				var t: float = i / 8.0
				var tx: float = px * sf + sin(t * 0.8) * 10 * sf
				var ty: float = base_y - t * 55 * sf
				trunk.add_point(Vector2(tx, ty))
			drawing.add_child(trunk)
			# Fronds (3 drooping lines from top)
			var top_x: float = px * sf + sin(0.8) * 10 * sf
			var top_y: float = base_y - 55 * sf
			for angle_offset: float in [-0.8, 0.0, 0.8]:
				var frond: Line2D = Line2D.new()
				frond.width = w * 0.8
				frond.default_color = ink
				frond.add_point(Vector2(top_x, top_y))
				frond.add_point(Vector2(top_x + cos(angle_offset) * 25 * sf, top_y + 8 * sf))
				frond.add_point(Vector2(top_x + cos(angle_offset) * 30 * sf, top_y + 18 * sf))
				drawing.add_child(frond)
		# Oasis pool
		var oasis: Line2D = Line2D.new()
		oasis.width = w
		oasis.default_color = ink
		var ocx: float = 120 * sf
		var ocy: float = base_y - 3 * sf
		for i: int in range(25):
			var a: float = i * TAU / 24.0
			oasis.add_point(Vector2(ocx + cos(a) * 30 * sf, ocy + sin(a) * 10 * sf))
		drawing.add_child(oasis)
		# Sun
		var sun: Line2D = Line2D.new()
		sun.width = w
		sun.default_color = ink
		var scx: float = 240 * sf
		var scy: float = 18 * sf
		var sr: float = 12 * sf
		for i: int in range(17):
			var a: float = i * TAU / 16.0
			sun.add_point(Vector2(scx + cos(a) * sr, scy + sin(a) * sr))
		drawing.add_child(sun)
		# Sun rays
		for i: int in range(8):
			var a: float = i * TAU / 8.0
			var ray: Line2D = Line2D.new()
			ray.width = w * 0.6
			ray.default_color = ink
			ray.add_point(Vector2(scx + cos(a) * sr * 1.3, scy + sin(a) * sr * 1.3))
			ray.add_point(Vector2(scx + cos(a) * sr * 1.8, scy + sin(a) * sr * 1.8))
			drawing.add_child(ray)

	elif page_index == 4:
		# Mountain peaks with hang glider
		var base_y: float = h - 5 * sf
		# Ground
		var ground: Line2D = Line2D.new()
		ground.width = w
		ground.default_color = ink
		ground.add_point(Vector2(10 * sf, base_y))
		ground.add_point(Vector2(280 * sf, base_y))
		drawing.add_child(ground)
		# Mountain range
		var mountains: Line2D = Line2D.new()
		mountains.width = w
		mountains.default_color = ink
		mountains.add_point(Vector2(10 * sf, base_y))
		mountains.add_point(Vector2(50 * sf, base_y - 50 * sf))
		mountains.add_point(Vector2(80 * sf, base_y - 30 * sf))
		mountains.add_point(Vector2(120 * sf, base_y - 70 * sf))
		mountains.add_point(Vector2(150 * sf, base_y - 45 * sf))
		mountains.add_point(Vector2(190 * sf, base_y - 60 * sf))
		mountains.add_point(Vector2(230 * sf, base_y - 35 * sf))
		mountains.add_point(Vector2(280 * sf, base_y))
		drawing.add_child(mountains)
		# Snow caps (small V marks on peaks)
		for peak: Vector2 in [Vector2(120, -70), Vector2(190, -60), Vector2(50, -50)]:
			var cap: Line2D = Line2D.new()
			cap.width = w * 0.7
			cap.default_color = ink
			var peak_x: float = peak.x * sf
			var peak_y: float = base_y + peak.y * sf
			cap.add_point(Vector2(peak_x - 8 * sf, peak_y + 10 * sf))
			cap.add_point(Vector2(peak_x, peak_y))
			cap.add_point(Vector2(peak_x + 8 * sf, peak_y + 10 * sf))
			drawing.add_child(cap)
		# Hang glider
		var gx: float = 210 * sf
		var gy: float = 15 * sf
		var glider: Line2D = Line2D.new()
		glider.width = w
		glider.default_color = ink
		glider.add_point(Vector2(gx - 20 * sf, gy + 5 * sf))
		glider.add_point(Vector2(gx, gy))
		glider.add_point(Vector2(gx + 20 * sf, gy + 5 * sf))
		drawing.add_child(glider)
		# Pilot hanging below
		var pilot: Line2D = Line2D.new()
		pilot.width = w * 0.8
		pilot.default_color = ink
		pilot.add_point(Vector2(gx, gy))
		pilot.add_point(Vector2(gx, gy + 12 * sf))
		drawing.add_child(pilot)

	elif page_index == 5:
		# Book on pedestal in water (sinkhole)
		var base_y: float = h - 5 * sf
		# Water surface ripples
		for ry: float in [base_y - 35 * sf, base_y - 30 * sf, base_y - 25 * sf]:
			var ripple: Line2D = Line2D.new()
			ripple.width = w * 0.6
			ripple.default_color = ink
			for i: int in range(21):
				var x: float = (60 + i * 9) * sf
				var y: float = ry + sin(i * 0.8 + ry * 0.01) * 2 * sf
				ripple.add_point(Vector2(x, y))
			drawing.add_child(ripple)
		# Pedestal
		var pedestal: Line2D = Line2D.new()
		pedestal.width = w
		pedestal.default_color = ink
		pedestal.add_point(Vector2(125 * sf, base_y))
		pedestal.add_point(Vector2(125 * sf, base_y - 20 * sf))
		pedestal.add_point(Vector2(165 * sf, base_y - 20 * sf))
		pedestal.add_point(Vector2(165 * sf, base_y))
		pedestal.add_point(Vector2(120 * sf, base_y))
		pedestal.add_point(Vector2(170 * sf, base_y))
		drawing.add_child(pedestal)
		# Book on top
		var book: Line2D = Line2D.new()
		book.width = w
		book.default_color = ink
		book.add_point(Vector2(130 * sf, base_y - 20 * sf))
		book.add_point(Vector2(130 * sf, base_y - 30 * sf))
		book.add_point(Vector2(145 * sf, base_y - 32 * sf))
		book.add_point(Vector2(160 * sf, base_y - 30 * sf))
		book.add_point(Vector2(160 * sf, base_y - 20 * sf))
		drawing.add_child(book)
		# Book spine
		var spine: Line2D = Line2D.new()
		spine.width = w * 0.6
		spine.default_color = ink
		spine.add_point(Vector2(145 * sf, base_y - 32 * sf))
		spine.add_point(Vector2(145 * sf, base_y - 20 * sf))
		drawing.add_child(spine)
		# Glow lines radiating from book
		for i: int in range(5):
			var a: float = -PI * 0.8 + i * PI * 0.6 / 4.0
			var glow: Line2D = Line2D.new()
			glow.width = w * 0.5
			glow.default_color = Color(ink.r, ink.g, ink.b, 0.35)
			glow.add_point(Vector2(145 * sf + cos(a) * 18 * sf, (base_y - 26 * sf) + sin(a) * 18 * sf))
			glow.add_point(Vector2(145 * sf + cos(a) * 28 * sf, (base_y - 26 * sf) + sin(a) * 28 * sf))
			drawing.add_child(glow)

	else:
		# No illustration for recipe pages
		return null

	return container


func _populate_page() -> void:
	if not is_instance_valid(_left_vbox) or not is_instance_valid(_right_vbox):
		return

	# Clear existing content from both pages (free() for synchronous removal)
	for child: Node in _left_vbox.get_children():
		child.free()
	for child: Node in _right_vbox.get_children():
		child.free()

	var page: Dictionary = _pages[_current_page]
	var font: Font = HUD_FONT
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	if vp_size == Vector2.ZERO:
		vp_size = Vector2(1920, 1080)
	var sf: float = vp_size.y / 1080.0

	var ink_color: Color = Color(0.18, 0.12, 0.06)
	var hint_color: Color = Color(0.45, 0.32, 0.15, 0.5)

	# Determine font size based on page type
	var body_font_size: int = 26
	if page.is_recipe_page:
		body_font_size = 22
	elif page.is_title_page:
		body_font_size = 28

	# --- Left page content ---
	if page.is_title_page:
		# Title label
		var title_label: Label = Label.new()
		title_label.text = page.left_title
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_override("font", font)
		title_label.add_theme_font_size_override("font_size", int(42 * sf))
		title_label.add_theme_color_override("font_color", Color(0.30, 0.18, 0.06))
		_left_vbox.add_child(title_label)

		# Horizontal rule
		var rule: ColorRect = ColorRect.new()
		rule.color = Color(0.45, 0.32, 0.15, 0.6)
		rule.custom_minimum_size = Vector2(0, 2 * sf)
		_left_vbox.add_child(rule)

		# Body text
		var left_body: Label = Label.new()
		left_body.text = page.left_text
		left_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		left_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left_body.add_theme_font_override("font", font)
		left_body.add_theme_font_size_override("font_size", int(body_font_size * sf))
		left_body.add_theme_color_override("font_color", Color(0.45, 0.32, 0.15, 0.7))
		_left_vbox.add_child(left_body)

		# Illustration
		var illustration: Control = _build_illustration(_current_page, sf)
		if illustration:
			_left_vbox.add_child(illustration)

	elif page.is_recipe_page:
		# Header label
		var header_label: Label = Label.new()
		header_label.text = page.left_title
		header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header_label.add_theme_font_override("font", font)
		header_label.add_theme_font_size_override("font_size", int(32 * sf))
		header_label.add_theme_color_override("font_color", Color(0.30, 0.18, 0.06))
		_left_vbox.add_child(header_label)

		# Horizontal rule
		var rule: ColorRect = ColorRect.new()
		rule.color = Color(0.45, 0.32, 0.15, 0.6)
		rule.custom_minimum_size = Vector2(0, 2 * sf)
		_left_vbox.add_child(rule)

		# Body text
		var left_body: Label = Label.new()
		left_body.text = page.left_text
		left_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left_body.add_theme_font_override("font", font)
		left_body.add_theme_font_size_override("font_size", int(body_font_size * sf))
		left_body.add_theme_color_override("font_color", ink_color)
		left_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_left_vbox.add_child(left_body)

	else:
		# Diary page — header label (e.g. "Day 5")
		var header_label: Label = Label.new()
		header_label.text = page.left_title
		header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header_label.add_theme_font_override("font", font)
		header_label.add_theme_font_size_override("font_size", int(32 * sf))
		header_label.add_theme_color_override("font_color", ink_color)
		_left_vbox.add_child(header_label)

		# Horizontal rule
		var rule: ColorRect = ColorRect.new()
		rule.color = Color(0.45, 0.32, 0.15, 0.6)
		rule.custom_minimum_size = Vector2(0, 2 * sf)
		_left_vbox.add_child(rule)

		# Body text
		var left_body: Label = Label.new()
		left_body.text = page.left_text
		left_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left_body.add_theme_font_override("font", font)
		left_body.add_theme_font_size_override("font_size", int(body_font_size * sf))
		left_body.add_theme_color_override("font_color", ink_color)
		left_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_left_vbox.add_child(left_body)

	# --- Right page content ---
	var right_body: Label = Label.new()
	right_body.text = page.right_text
	right_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_body.add_theme_font_override("font", font)
	right_body.add_theme_font_size_override("font_size", int(body_font_size * sf))
	right_body.add_theme_color_override("font_color", ink_color)
	right_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_vbox.add_child(right_body)

	# Illustration on right page (diary pages only, not title or recipe)
	if not page.is_title_page and not page.is_recipe_page:
		var right_illus: Control = _build_illustration(_current_page, sf)
		if right_illus:
			_right_vbox.add_child(right_illus)

	# --- Navigation bar at bottom of right page ---
	var nav_hbox: HBoxContainer = HBoxContainer.new()
	nav_hbox.add_theme_constant_override("separation", 0)

	# Prev label
	if _current_page > 0:
		var prev_label: Label = Label.new()
		prev_label.text = "< Prev"
		prev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		prev_label.add_theme_font_override("font", font)
		prev_label.add_theme_font_size_override("font_size", int(20 * sf))
		prev_label.add_theme_color_override("font_color", hint_color)
		prev_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav_hbox.add_child(prev_label)
	else:
		# Empty spacer to keep center label centered
		var spacer: Control = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav_hbox.add_child(spacer)

	# Page number label
	var page_label: Label = Label.new()
	page_label.text = "Page %d of %d" % [_current_page + 1, _total_pages]
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.add_theme_font_override("font", font)
	page_label.add_theme_font_size_override("font_size", int(20 * sf))
	page_label.add_theme_color_override("font_color", hint_color)
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_hbox.add_child(page_label)

	# Next label
	if _current_page < _total_pages - 1:
		var next_label: Label = Label.new()
		next_label.text = "Next >"
		next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		next_label.add_theme_font_override("font", font)
		next_label.add_theme_font_size_override("font_size", int(20 * sf))
		next_label.add_theme_color_override("font_color", hint_color)
		next_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav_hbox.add_child(next_label)
	else:
		# Empty spacer to keep center label centered
		var spacer: Control = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav_hbox.add_child(spacer)

	_right_vbox.add_child(nav_hbox)

	# Input hint label below nav
	var hint_label: Label = Label.new()
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label.add_theme_font_override("font", font)
	hint_label.add_theme_font_size_override("font_size", int(20 * sf))
	hint_label.add_theme_color_override("font_color", hint_color)

	var input_mgr: Node = get_node_or_null("/root/InputManager")
	if OS.get_name() == "iOS":
		hint_label.text = "Swipe or tap arrows to turn pages  |  ✕ to close"
	elif input_mgr and input_mgr.has_method("is_using_controller") and input_mgr.is_using_controller():
		hint_label.text = "D-Pad: turn pages  |  X: close"
	else:
		hint_label.text = "Arrows: turn pages  |  ESC / B: close"

	_right_vbox.add_child(hint_label)


func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if not _is_open:
		return

	# Journal consumes ALL input while open — prevents other menus from responding
	var vp: Viewport = get_viewport()

	# Touch/swipe page turning for iOS
	if event is InputEventScreenTouch:
		if event.pressed:
			_swipe_start = event.position
			_swipe_touch_index = event.index
		else:
			if event.index == _swipe_touch_index and _swipe_start != Vector2.ZERO:
				var swipe_delta: float = event.position.x - _swipe_start.x
				if swipe_delta < -SWIPE_THRESHOLD:
					# Swipe left → next page
					if _current_page < _total_pages - 1:
						_current_page += 1
						_populate_page()
						SFXManager.play_sfx("select")
						_update_mobile_nav_visibility()
				elif swipe_delta > SWIPE_THRESHOLD:
					# Swipe right → previous page
					if _current_page > 0:
						_current_page -= 1
						_populate_page()
						SFXManager.play_sfx("select")
						_update_mobile_nav_visibility()
				else:
					# Short tap — check proportional screen zones for close/nav.
					# We use raw event.position (no coordinate transform) and test
					# against zones computed from BOTH viewport size and window size,
					# because iOS touch events may be in either coordinate space
					# depending on Godot version and device. This avoids the
					# get_global_rect() mismatch that made the close button unreachable.
					_handle_mobile_button_tap(event.position)
			_swipe_start = Vector2.ZERO
			_swipe_touch_index = -1
		if vp:
			vp.set_input_as_handled()
		return

	if event is InputEventScreenDrag:
		# Consume drag events to prevent camera movement while journal is open
		if vp:
			vp.set_input_as_handled()
		return

	# Page turning — d-pad left/right, ui_left/ui_right, or keyboard arrow keys
	var turn_left: bool = event.is_action_pressed("ui_left")
	var turn_right: bool = event.is_action_pressed("ui_right")
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.physical_keycode == KEY_LEFT:
			turn_left = true
		elif event.physical_keycode == KEY_RIGHT:
			turn_right = true

	if turn_left:
		if _current_page > 0:
			_current_page -= 1
			_populate_page()
			SFXManager.play_sfx("select")
		if vp:
			vp.set_input_as_handled()
		return

	if turn_right:
		if _current_page < _total_pages - 1:
			_current_page += 1
			_populate_page()
			SFXManager.play_sfx("select")
		if vp:
			vp.set_input_as_handled()
		return

	# Close on ESC, ui_cancel, or B key
	var close: bool = false
	if event.is_action_pressed("pause"):
		close = true
	elif event.is_action_pressed("ui_cancel"):
		close = true
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.physical_keycode == KEY_B:
			close = true

	if close:
		_close_journal()
		if vp:
			vp.set_input_as_handled()
		return

	# Consume all other input events while journal is open
	if vp:
		vp.set_input_as_handled()


func _apply_mobile_menu_style() -> void:
	if not is_instance_valid(panel):
		return

	# Enforce minimum button sizes for touch BEFORE adding close button
	_enforce_min_button_size(panel, 44)

	# Remove old mobile buttons if they exist (journal rebuilds UI each open)
	for btn_name: String in ["MobileCloseButton", "MobilePrevButton", "MobileNextButton"]:
		var old_btn: Button = get_node_or_null(btn_name) as Button
		if old_btn:
			old_btn.queue_free()

	# Close button (top-right)
	var close_btn: Button = Button.new()
	close_btn.name = "MobileCloseButton"
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 32)
	close_btn.custom_minimum_size = Vector2(48, 48)
	close_btn.pressed.connect(_close_journal)
	add_child(close_btn)

	# Previous page arrow button (left side)
	var prev_btn: Button = Button.new()
	prev_btn.name = "MobilePrevButton"
	prev_btn.text = "<"
	prev_btn.add_theme_font_size_override("font_size", 36)
	prev_btn.custom_minimum_size = Vector2(56, 56)
	prev_btn.pressed.connect(_mobile_prev_page)
	add_child(prev_btn)

	# Next page arrow button (right side)
	var next_btn: Button = Button.new()
	next_btn.name = "MobileNextButton"
	next_btn.text = ">"
	next_btn.add_theme_font_size_override("font_size", 36)
	next_btn.custom_minimum_size = Vector2(56, 56)
	next_btn.pressed.connect(_mobile_next_page)
	add_child(next_btn)

	call_deferred("_position_mobile_buttons")


func _position_mobile_buttons() -> void:
	if not is_instance_valid(panel):
		return
	var rect: Rect2 = panel.get_global_rect()

	# Close button — top-right corner of the book
	var close_btn: Button = get_node_or_null("MobileCloseButton") as Button
	if close_btn:
		close_btn.anchor_left = 0.0
		close_btn.anchor_right = 0.0
		close_btn.anchor_top = 0.0
		close_btn.anchor_bottom = 0.0
		close_btn.offset_left = rect.position.x + rect.size.x - 56
		close_btn.offset_top = rect.position.y + 8
		close_btn.offset_right = rect.position.x + rect.size.x - 8
		close_btn.offset_bottom = rect.position.y + 56

	# Prev arrow — vertically centered on left edge of book
	var prev_btn: Button = get_node_or_null("MobilePrevButton") as Button
	if prev_btn:
		var cy: float = rect.position.y + rect.size.y / 2.0
		prev_btn.anchor_left = 0.0
		prev_btn.anchor_right = 0.0
		prev_btn.anchor_top = 0.0
		prev_btn.anchor_bottom = 0.0
		prev_btn.offset_left = rect.position.x - 64
		prev_btn.offset_top = cy - 28
		prev_btn.offset_right = rect.position.x - 8
		prev_btn.offset_bottom = cy + 28
		prev_btn.visible = _current_page > 0

	# Next arrow — vertically centered on right edge of book
	var next_btn: Button = get_node_or_null("MobileNextButton") as Button
	if next_btn:
		var cy: float = rect.position.y + rect.size.y / 2.0
		next_btn.anchor_left = 0.0
		next_btn.anchor_right = 0.0
		next_btn.anchor_top = 0.0
		next_btn.anchor_bottom = 0.0
		next_btn.offset_left = rect.position.x + rect.size.x + 8
		next_btn.offset_top = cy - 28
		next_btn.offset_right = rect.position.x + rect.size.x + 64
		next_btn.offset_bottom = cy + 28
		next_btn.visible = _current_page < _total_pages - 1


func _mobile_prev_page() -> void:
	if _current_page > 0:
		_current_page -= 1
		_populate_page()
		SFXManager.play_sfx("select")
		_update_mobile_nav_visibility()


func _mobile_next_page() -> void:
	if _current_page < _total_pages - 1:
		_current_page += 1
		_populate_page()
		SFXManager.play_sfx("select")
		_update_mobile_nav_visibility()


func _update_mobile_nav_visibility() -> void:
	var prev_btn: Button = get_node_or_null("MobilePrevButton") as Button
	if prev_btn:
		prev_btn.visible = _current_page > 0
	var next_btn: Button = get_node_or_null("MobileNextButton") as Button
	if next_btn:
		next_btn.visible = _current_page < _total_pages - 1


static func _enforce_min_button_size(node: Node, min_size: int) -> void:
	for child: Node in node.get_children():
		if child is Button:
			if child.custom_minimum_size.x < min_size:
				child.custom_minimum_size.x = min_size
			if child.custom_minimum_size.y < min_size:
				child.custom_minimum_size.y = min_size
		_enforce_min_button_size(child, min_size)


func _handle_mobile_button_tap(pos: Vector2) -> void:
	# On iOS, touch event coordinates may be in viewport space (1920x1080 with
	# canvas_items stretch) OR window/screen space (device native resolution).
	# Using get_global_rect() fails when the spaces don't match. Instead, we
	# compute hit zones from the known panel anchor positions (0.06 - 0.94) and
	# test against BOTH viewport size and window size. One of them will match
	# whatever coordinate space the touch event uses.
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var win_size: Vector2 = Vector2(DisplayServer.window_get_size())

	var sizes: Array[Vector2] = [vp_size]
	if not vp_size.is_equal_approx(win_size):
		sizes.append(win_size)

	for ref: Vector2 in sizes:
		var book_right: float = ref.x * 0.94
		var book_top: float = ref.y * 0.06

		# Close zone: top-right 80x80 area of the book panel
		if pos.x > book_right - 80.0 and pos.y < book_top + 80.0 and pos.x < ref.x and pos.y > 0.0:
			_close_journal()
			return

		# Tap outside book panel: close
		var book_left: float = ref.x * 0.06
		var book_bottom: float = ref.y * 0.94
		if pos.x < book_left or pos.x > book_right or pos.y < book_top or pos.y > book_bottom:
			_close_journal()
			return


func _close_journal() -> void:
	if not _is_open:
		return
	SFXManager.play_sfx("menu_close")
	_is_open = false

	# Hide mobile buttons
	for btn_name: String in ["MobileCloseButton", "MobilePrevButton", "MobileNextButton"]:
		var mobile_btn: Button = get_node_or_null(btn_name) as Button
		if mobile_btn:
			mobile_btn.queue_free()

	# Free the built UI nodes so re-opening doesn't stack duplicates
	if is_instance_valid(background):
		background.free()
		background = null
	if is_instance_valid(shadow):
		shadow.free()
		shadow = null
	if is_instance_valid(panel):
		panel.free()
		panel = null
	_left_vbox = null
	_right_vbox = null

	# Unpause the game tree
	get_tree().paused = false

	journal_closed.emit(_is_first_read)
