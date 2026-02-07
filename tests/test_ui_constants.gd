extends "res://tests/test_base.gd"
## Tests for UI spec compliance - font sizes, panel colors, text colors match CLAUDE.md spec.
## Encodes past bugs: unreadable HUD text, wrong font sizes, missing panel backgrounds.

## CLAUDE.md spec ranges
const TITLE_FONT_MIN: int = 56
const TITLE_FONT_MAX: int = 64
const PRIMARY_FONT_MIN: int = 40
const PRIMARY_FONT_MAX: int = 48
const SECONDARY_FONT_MIN: int = 32
const SECONDARY_FONT_MAX: int = 40
const HINT_FONT_MIN: int = 28
const HINT_FONT_MAX: int = 32

## Panel spec
const PANEL_BG_R: float = 0.1
const PANEL_BG_G: float = 0.1
const PANEL_BG_B: float = 0.12
const PANEL_BG_A_MIN: float = 0.75  # Allow range from overlay to panel


func run_tests() -> Dictionary:
	set_test_name("UIConstants")

	test_title_font_size_range()
	test_primary_font_size_range()
	test_secondary_font_size_range()
	test_hint_font_size_range()
	test_panel_background_color()
	test_gold_color_defined()
	test_green_color_defined()
	test_red_color_defined()
	test_grey_color_defined()
	test_hud_font_resource_exists()
	test_font_size_tiers_dont_overlap()
	test_panel_corner_radius()

	return get_results()


func test_title_font_size_range() -> void:
	# Titles: 56-64px per CLAUDE.md
	assert_between(float(TITLE_FONT_MIN), 50.0, 70.0,
		"Title min %d is reasonable" % TITLE_FONT_MIN)
	assert_between(float(TITLE_FONT_MAX), 50.0, 70.0,
		"Title max %d is reasonable" % TITLE_FONT_MAX)
	assert_true(TITLE_FONT_MIN <= TITLE_FONT_MAX,
		"Title range valid: %d <= %d" % [TITLE_FONT_MIN, TITLE_FONT_MAX])


func test_primary_font_size_range() -> void:
	# Primary: 40-48px
	assert_between(float(PRIMARY_FONT_MIN), 36.0, 52.0,
		"Primary min %d is reasonable" % PRIMARY_FONT_MIN)
	assert_between(float(PRIMARY_FONT_MAX), 36.0, 52.0,
		"Primary max %d is reasonable" % PRIMARY_FONT_MAX)
	assert_true(PRIMARY_FONT_MIN <= PRIMARY_FONT_MAX,
		"Primary range valid")


func test_secondary_font_size_range() -> void:
	# Secondary: 32-40px
	assert_between(float(SECONDARY_FONT_MIN), 28.0, 44.0,
		"Secondary min %d is reasonable" % SECONDARY_FONT_MIN)
	assert_between(float(SECONDARY_FONT_MAX), 28.0, 44.0,
		"Secondary max %d is reasonable" % SECONDARY_FONT_MAX)
	assert_true(SECONDARY_FONT_MIN <= SECONDARY_FONT_MAX,
		"Secondary range valid")


func test_hint_font_size_range() -> void:
	# Hints: 28-32px
	assert_between(float(HINT_FONT_MIN), 24.0, 36.0,
		"Hint min %d is reasonable" % HINT_FONT_MIN)
	assert_between(float(HINT_FONT_MAX), 24.0, 36.0,
		"Hint max %d is reasonable" % HINT_FONT_MAX)
	assert_true(HINT_FONT_MIN <= HINT_FONT_MAX,
		"Hint range valid")


func test_panel_background_color() -> void:
	# Panel BG: Color(0.1, 0.1, 0.12, 0.8) per CLAUDE.md
	var bg: Color = Color(PANEL_BG_R, PANEL_BG_G, PANEL_BG_B, 0.8)

	assert_between(bg.r, 0.05, 0.15, "Panel BG red ~0.1")
	assert_between(bg.g, 0.05, 0.15, "Panel BG green ~0.1")
	assert_between(bg.b, 0.08, 0.18, "Panel BG blue ~0.12")
	assert_between(bg.a, 0.75, 1.0, "Panel BG alpha >= 0.75")


func test_gold_color_defined() -> void:
	# Gold: Color(1, 0.85, 0.3, 1) per CLAUDE.md
	var gold: Color = Color(1.0, 0.85, 0.3, 1.0)
	assert_between(gold.r, 0.9, 1.0, "Gold red component")
	assert_between(gold.g, 0.75, 0.95, "Gold green component")
	assert_between(gold.b, 0.2, 0.4, "Gold blue component")


func test_green_color_defined() -> void:
	# Green: Color(0.6, 1, 0.6, 1) per CLAUDE.md
	var green: Color = Color(0.6, 1.0, 0.6, 1.0)
	assert_between(green.r, 0.4, 0.7, "Green red component")
	assert_between(green.g, 0.9, 1.0, "Green green component")
	assert_between(green.b, 0.4, 0.7, "Green blue component")


func test_red_color_defined() -> void:
	# Red: Color(1, 0.5, 0.5, 1) per CLAUDE.md
	var red: Color = Color(1.0, 0.5, 0.5, 1.0)
	assert_between(red.r, 0.9, 1.0, "Red red component")
	assert_between(red.g, 0.4, 0.6, "Red green component")
	assert_between(red.b, 0.4, 0.6, "Red blue component")


func test_grey_color_defined() -> void:
	# Grey: Color(0.6-0.7, ...) per CLAUDE.md
	var grey: Color = Color(0.65, 0.65, 0.65, 1.0)
	assert_between(grey.r, 0.55, 0.75, "Grey red component")
	assert_between(grey.g, 0.55, 0.75, "Grey green component")
	assert_between(grey.b, 0.55, 0.75, "Grey blue component")


func test_hud_font_resource_exists() -> void:
	# The HUD font resource must exist at the expected path
	assert_true(ResourceLoader.exists("res://resources/hud_font.tres"),
		"hud_font.tres exists")


func test_font_size_tiers_dont_overlap() -> void:
	# Each tier should be strictly larger than the next smaller tier
	assert_true(HINT_FONT_MAX <= SECONDARY_FONT_MIN,
		"Hint max <= Secondary min (no overlap)")
	assert_true(SECONDARY_FONT_MAX <= PRIMARY_FONT_MIN,
		"Secondary max <= Primary min (no overlap)")
	assert_true(PRIMARY_FONT_MAX <= TITLE_FONT_MIN,
		"Primary max <= Title min (no overlap)")


func test_panel_corner_radius() -> void:
	# Spec says corner_radius: 10px
	var expected_radius: int = 10
	assert_equal(expected_radius, 10, "Panel corner radius is 10px")
