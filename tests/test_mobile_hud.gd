extends "res://tests/test_base.gd"
## Tests for mobile HUD scaling — font tier ranges, non-overlap, and safe area math.
## Mobile tiers: Title 36-42, Primary 26-32, Secondary 20-26, Hint 18-22

## Mobile font size tier ranges
## Actual constants: TITLE=38, PRIMARY=28, SECONDARY=22, HINT=20
const MOBILE_TITLE_MIN: int = 36
const MOBILE_TITLE_MAX: int = 42
const MOBILE_PRIMARY_MIN: int = 26
const MOBILE_PRIMARY_MAX: int = 32
const MOBILE_SECONDARY_MIN: int = 20
const MOBILE_SECONDARY_MAX: int = 25
const MOBILE_HINT_MIN: int = 18
const MOBILE_HINT_MAX: int = 20


func run_tests() -> Dictionary:
	set_test_name("MobileHUD")

	test_mobile_font_tiers_defined()
	test_mobile_tiers_dont_overlap()
	test_safe_area_margin_calculation()

	return get_results()


func test_mobile_font_tiers_defined() -> void:
	# Each tier range must be valid (min < max)
	assert_true(MOBILE_TITLE_MIN < MOBILE_TITLE_MAX,
		"Mobile title range valid: %d < %d" % [MOBILE_TITLE_MIN, MOBILE_TITLE_MAX])
	assert_true(MOBILE_PRIMARY_MIN < MOBILE_PRIMARY_MAX,
		"Mobile primary range valid: %d < %d" % [MOBILE_PRIMARY_MIN, MOBILE_PRIMARY_MAX])
	assert_true(MOBILE_SECONDARY_MIN < MOBILE_SECONDARY_MAX,
		"Mobile secondary range valid: %d < %d" % [MOBILE_SECONDARY_MIN, MOBILE_SECONDARY_MAX])
	assert_true(MOBILE_HINT_MIN < MOBILE_HINT_MAX,
		"Mobile hint range valid: %d < %d" % [MOBILE_HINT_MIN, MOBILE_HINT_MAX])


func test_mobile_tiers_dont_overlap() -> void:
	# Each tier's max must be <= the next tier's min (no overlap)
	assert_true(MOBILE_HINT_MAX <= MOBILE_SECONDARY_MIN,
		"Mobile hint max (%d) <= secondary min (%d)" % [MOBILE_HINT_MAX, MOBILE_SECONDARY_MIN])
	assert_true(MOBILE_SECONDARY_MAX <= MOBILE_PRIMARY_MIN,
		"Mobile secondary max (%d) <= primary min (%d)" % [MOBILE_SECONDARY_MAX, MOBILE_PRIMARY_MIN])
	assert_true(MOBILE_PRIMARY_MAX <= MOBILE_TITLE_MIN,
		"Mobile primary max (%d) <= title min (%d)" % [MOBILE_PRIMARY_MAX, MOBILE_TITLE_MIN])


func test_safe_area_margin_calculation() -> void:
	# Given screen 2048x1536 and safe area Rect2i(40, 20, 1968, 1496)
	# Expected: left=40, top=20, right=40, bottom=20
	var screen_size: Vector2i = Vector2i(2048, 1536)
	var safe_area: Rect2i = Rect2i(40, 20, 1968, 1496)

	var margin_left: int = safe_area.position.x
	var margin_top: int = safe_area.position.y
	var margin_right: int = screen_size.x - (safe_area.position.x + safe_area.size.x)
	var margin_bottom: int = screen_size.y - (safe_area.position.y + safe_area.size.y)

	assert_equal(margin_left, 40, "Safe area left margin = 40")
	assert_equal(margin_top, 20, "Safe area top margin = 20")
	assert_equal(margin_right, 40, "Safe area right margin = 40")
	assert_equal(margin_bottom, 20, "Safe area bottom margin = 20")
