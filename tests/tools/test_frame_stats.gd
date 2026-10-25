extends GdUnitTestSuite
## Fase 32: o resumo dos quadros do benchmark (percentis e lows) numa lista conhecida.


func test_summary_of_a_known_list() -> void:
	# 990 quadros de 10 ms, 9 de 20 ms e um de 100 ms
	var frames := PackedFloat64Array()
	for index: int in 990:
		frames.append(10.0)
	for index: int in 9:
		frames.append(20.0)
	frames.append(100.0)
	frames.reverse()
	var stats := FrameStats.summary(frames)
	assert_int(stats.count).is_equal(1000)
	assert_float(stats.average_ms).is_equal_approx(10.18, 0.001)
	assert_float(stats.p50_ms).is_equal(10.0)
	assert_float(stats.p95_ms).is_equal(10.0)
	assert_float(stats.p99_ms).is_equal(10.0)
	assert_float(stats.worst_ms).is_equal(100.0)
	# 1% = os 10 mais lentos: 9 × 20 + 100 = 280 ms, média 28 ms = 35,7 FPS; 0,1% = o de 100 ms = 10 FPS
	assert_float(stats.low_1_fps).is_equal_approx(1000.0 / 28.0, 0.01)
	assert_float(stats.low_01_fps).is_equal_approx(10.0, 0.001)


func test_summary_does_not_sort_the_caller_list() -> void:
	var frames := PackedFloat64Array([30.0, 10.0, 20.0])
	FrameStats.summary(frames)
	assert_array(Array(frames)).is_equal([30.0, 10.0, 20.0])


func test_short_and_empty_lists() -> void:
	assert_int(FrameStats.summary(PackedFloat64Array()).count).is_equal(0)
	var one := FrameStats.summary(PackedFloat64Array([16.0]))
	assert_float(one.p99_ms).is_equal(16.0)
	assert_float(one.low_01_fps).is_equal_approx(62.5, 0.001)
