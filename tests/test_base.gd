extends RefCounted
class_name TestBase
## Lightweight test framework for headless regression testing.

var _test_name: String = ""
var _passed: int = 0
var _failed: int = 0
var _errors: Array[String] = []


func run_tests() -> Dictionary:
	## Override in subclasses. Call test methods and return results.
	return get_results()


func set_test_name(name: String) -> void:
	_test_name = name


func get_results() -> Dictionary:
	return {"name": _test_name, "passed": _passed, "failed": _failed, "errors": _errors}


func assert_true(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		var err: String = "  FAIL: %s" % message
		_errors.append(err)
		print(err)


func assert_false(condition: bool, message: String) -> void:
	assert_true(not condition, message)


func assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		var err: String = "  FAIL: %s (expected %s, got %s)" % [message, str(expected), str(actual)]
		_errors.append(err)
		print(err)


func assert_not_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		_passed += 1
	else:
		_failed += 1
		var err: String = "  FAIL: %s (should not equal %s)" % [message, str(expected)]
		_errors.append(err)
		print(err)


func assert_not_null(value: Variant, message: String) -> void:
	assert_true(value != null, message)


func assert_greater(actual: float, threshold: float, message: String) -> void:
	if actual > threshold:
		_passed += 1
	else:
		_failed += 1
		var err: String = "  FAIL: %s (expected > %s, got %s)" % [message, str(threshold), str(actual)]
		_errors.append(err)
		print(err)


func assert_less(actual: float, threshold: float, message: String) -> void:
	if actual < threshold:
		_passed += 1
	else:
		_failed += 1
		var err: String = "  FAIL: %s (expected < %s, got %s)" % [message, str(threshold), str(actual)]
		_errors.append(err)
		print(err)


func assert_between(actual: float, low: float, high: float, message: String) -> void:
	if actual >= low and actual <= high:
		_passed += 1
	else:
		_failed += 1
		var err: String = "  FAIL: %s (expected %s-%s, got %s)" % [message, str(low), str(high), str(actual)]
		_errors.append(err)
		print(err)
