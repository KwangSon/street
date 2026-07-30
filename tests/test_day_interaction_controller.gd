extends GutTest

const DayInteractionControllerScript: Script = preload(
	"res://srcs/day/day_interaction_controller.gd"
)
const DayInteractableStubScript: Script = preload(
	"res://tests/fixtures/day_interactable_stub.gd"
)
const DayPlayerScript: Script = preload(
	"res://srcs/day/day_player.gd"
)


func test_overlapping_targets_use_priority_before_distance() -> void:
	var fixture: Dictionary = await _create_fixture()
	var controller: DayInteractionController = fixture["controller"]
	var low_target: Variant = _add_target(
		fixture["root"],
		Vector2(1.0, 0.0),
		DayInteractionController.PRIORITY_COIN
	)
	var high_target: Variant = _add_target(
		fixture["root"],
		Vector2(50.0, 0.0),
		DayInteractionController.PRIORITY_DROP_OFF
	)
	controller.register_interactable(low_target)
	controller.register_interactable(high_target)

	controller._physics_process(0.0)

	assert_eq(controller.get_current_target(), high_target)
	assert_true(high_target.highlighted)
	assert_false(low_target.highlighted)
	assert_eq(high_target.enter_count, 1)


func test_equal_priority_uses_nearest_target() -> void:
	var fixture: Dictionary = await _create_fixture()
	var controller: DayInteractionController = fixture["controller"]
	var far_target: Variant = _add_target(
		fixture["root"],
		Vector2(70.0, 0.0),
		DayInteractionController.PRIORITY_COMPLETED_ITEM
	)
	var near_target: Variant = _add_target(
		fixture["root"],
		Vector2(20.0, 0.0),
		DayInteractionController.PRIORITY_COMPLETED_ITEM
	)
	controller.register_interactable(far_target)
	controller.register_interactable(near_target)

	controller._physics_process(0.0)

	assert_eq(controller.get_current_target(), near_target)


func _create_fixture() -> Dictionary:
	var fixture_root: Node2D = Node2D.new()
	add_child_autofree(fixture_root)

	var player: DayPlayer = DayPlayerScript.new()
	player.position = Vector2.ZERO
	fixture_root.add_child(player)

	var controller: DayInteractionController = (
		DayInteractionControllerScript.new()
	)
	controller.configure(player)
	fixture_root.add_child(controller)
	await wait_process_frames(1)
	return {
		"root": fixture_root,
		"controller": controller,
	}


func _add_target(
	parent: Node,
	target_position: Vector2,
	priority: int
) -> Variant:
	var target: Variant = DayInteractableStubScript.new()
	target.position = target_position
	target.interaction_priority = priority
	parent.add_child(target)
	return target
