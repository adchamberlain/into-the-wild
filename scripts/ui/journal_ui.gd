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

const HUD_FONT: Font = preload("res://resources/hud_font.tres")


func _get_pages() -> Array[Dictionary]:
	var pages: Array[Dictionary] = []

	# Spread 1: Title page
	pages.append({
		"left_title": "Explorer's Journal",
		"left_text": "A Record of the Carlston Wilderness\n\n~ ~ ~\n\nProperty of E.W. Carlston",
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
		"right_text": "I'm leaving this journal on a pedestal at the bottom, for whoever comes next. Everything I've learned is in these pages — every place worth visiting, every recipe for every tool and structure that made this wilderness feel like home.\n\nThe Carlston Wilderness is a generous place if you're willing to explore it. Every oasis, every cave, every mountain peak has something wonderful waiting. Take your time. Build well. Climb high.\n\nHappy trails.\n\n— E.W. Carlston",
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
		"right_text": "Hang Glider — 4 rope, 6 branches, 2 hide\n\nThis is it — my greatest creation. The design took weeks to perfect but the materials are simple. Find a high peak, spread the wings, and run. The wind will do the rest.\n\nThe Carlston Wilderness looks different from up there. Better. Like it was made to be seen from the sky.\n\n~ ~ ~\n\nEnd of Journal",
		"is_title_page": false,
		"is_recipe_page": true,
	})

	return pages


func _ready() -> void:
	# Process even when tree is paused (we pause the tree while journal is open)
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80


func open_journal(is_first_read: bool) -> void:
	_is_first_read = is_first_read
	_is_open = true
	_current_page = 0
	_pages = _get_pages()
	_total_pages = _pages.size()
	_build_ui()

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
	shadow.anchor_left = 0.5
	shadow.anchor_top = 0.5
	shadow.anchor_right = 0.5
	shadow.anchor_bottom = 0.5
	var book_w: float = 860 * sf
	var book_h: float = 560 * sf
	shadow.offset_left = -book_w / 2.0 + 4 * sf
	shadow.offset_top = -book_h / 2.0 + 4 * sf
	shadow.offset_right = book_w / 2.0 + 4 * sf
	shadow.offset_bottom = book_h / 2.0 + 4 * sf
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

	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -book_w / 2.0
	panel.offset_top = -book_h / 2.0
	panel.offset_right = book_w / 2.0
	panel.offset_bottom = book_h / 2.0

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
	left_style.content_margin_left = int(30 * sf)
	left_style.content_margin_right = int(24 * sf)
	left_style.content_margin_top = int(30 * sf)
	left_style.content_margin_bottom = int(24 * sf)
	left_page.add_theme_stylebox_override("panel", left_style)
	left_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var left_vbox: VBoxContainer = VBoxContainer.new()
	left_vbox.add_theme_constant_override("separation", int(12 * sf))
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
	right_style.content_margin_left = int(24 * sf)
	right_style.content_margin_right = int(30 * sf)
	right_style.content_margin_top = int(30 * sf)
	right_style.content_margin_bottom = int(24 * sf)
	right_page.add_theme_stylebox_override("panel", right_style)
	right_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var right_vbox: VBoxContainer = VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", int(12 * sf))
	right_page.add_child(right_vbox)
	_right_vbox = right_vbox

	hbox.add_child(right_page)

	add_child(panel)

	# Populate the first page
	_populate_page()


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
	var body_font_size: int = 22
	if page.is_recipe_page:
		body_font_size = 20
	elif page.is_title_page:
		body_font_size = 24

	# --- Left page content ---
	if page.is_title_page:
		# Title label
		var title_label: Label = Label.new()
		title_label.text = page.left_title
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_override("font", font)
		title_label.add_theme_font_size_override("font_size", int(40 * sf))
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
		left_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_left_vbox.add_child(left_body)

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
	if input_mgr and input_mgr.has_method("is_using_controller") and input_mgr.is_using_controller():
		hint_label.text = "D-Pad: turn pages  |  X: close"
	else:
		hint_label.text = "Arrows: turn pages  |  ESC / B: close"

	_right_vbox.add_child(hint_label)


func _input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if not _is_open:
		return

	# Page turning — d-pad left/right or arrow keys
	if event.is_action_pressed("ui_left"):
		if _current_page > 0:
			_current_page -= 1
			_populate_page()
		var vp: Viewport = get_viewport()
		if vp:
			vp.set_input_as_handled()
		return

	if event.is_action_pressed("ui_right"):
		if _current_page < _total_pages - 1:
			_current_page += 1
			_populate_page()
		var vp: Viewport = get_viewport()
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
		var vp: Viewport = get_viewport()
		if vp:
			vp.set_input_as_handled()


func _close_journal() -> void:
	if not _is_open:
		return
	_is_open = false

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
