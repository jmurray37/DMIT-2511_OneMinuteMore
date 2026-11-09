
extends Control

signal dialogue_finished

@export var characters_per_second: float = 35.0
@export var preview_intro_on_start: bool = true

@onready var dialogue_text: Label = $DialogueText
@onready var speaker_name: Label = $NameplateBorder/NameplateInterior/SpeakerName

@onready var gold_frame: ColorRect = $GoldFrame
@onready var dialogue_background: ColorRect = $DialogueBackground
@onready var frame_hourglass: TextureRect = $FrameHourglass
@onready var nameplate_border: ColorRect = $NameplateBorder

var dialogue_lines: Array[Dictionary] = []
var current_line: int = 0

var is_active: bool = false
var is_typing: bool = false
var revealed_characters: float = 0.0

var original_gold_position: Vector2
var original_gold_size: Vector2

var original_background_position: Vector2
var original_background_size: Vector2

var original_hourglass_position: Vector2
var original_nameplate_position: Vector2

var original_text_position: Vector2
var original_text_size: Vector2


func _ready() -> void:
	# Remember the original layout.
	original_gold_position = gold_frame.position
	original_gold_size = gold_frame.size

	original_background_position = dialogue_background.position
	original_background_size = dialogue_background.size

	original_hourglass_position = frame_hourglass.position
	original_nameplate_position = nameplate_border.position

	original_text_position = dialogue_text.position
	original_text_size = dialogue_text.size

	visible = false

	if preview_intro_on_start:
		var test_lines: Array[Dictionary] = [
			{
				"speaker": "You",
				"text": "Damn... this place creeps me out!"
			},
			{
				"speaker": "You",
				"text": "But... I can't turn back now. I can feel the curse closing in."
			},
			{
				"speaker": "You",
				"text": "This is a longer test of our new dialogue box. The frame should expand upward to make room for additional lines of dialogue, while keeping the bottom edge in the same place. The hourglass and nameplate should move upward with it."
			}
		]

		start_dialogue(test_lines)


func _process(delta: float) -> void:
	if not is_active or not is_typing:
		return

	revealed_characters += delta * characters_per_second

	var total: int = dialogue_text.get_total_character_count()

	dialogue_text.visible_characters = int(revealed_characters)

	if revealed_characters >= total:
		dialogue_text.visible_characters = -1
		is_typing = false


func _input(event: InputEvent) -> void:
	if not is_active:
		return

	var advance: bool = event.is_action_pressed("ui_accept")

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			advance = true

	if not advance:
		return

	get_viewport().set_input_as_handled()

	if is_typing:
		dialogue_text.visible_characters = -1
		is_typing = false
		return

	current_line += 1

	if current_line >= dialogue_lines.size():
		end_dialogue()
	else:
		show_current_line()


func start_dialogue(lines: Array[Dictionary]) -> void:
	if lines.is_empty():
		return

	dialogue_lines = lines
	current_line = 0
	is_active = true
	visible = true

	show_current_line()


func show_current_line() -> void:
	var line: Dictionary = dialogue_lines[current_line]

	var speaker: String = str(line.get("speaker", ""))
	var message: String = str(line.get("text", ""))

	speaker_name.text = speaker
	dialogue_text.text = message

	var speaker_color: Color = get_speaker_color(speaker)

	speaker_name.add_theme_color_override(
		"font_color",
		speaker_color
	)

	dialogue_text.add_theme_color_override(
		"font_color",
		speaker_color
	)

	# Resize the artwork to fit the full line.
	resize_dialogue_box()

	dialogue_text.visible_characters = 0
	revealed_characters = 0.0
	is_typing = true


func resize_dialogue_box() -> void:
	var line_count: int = dialogue_text.get_line_count()
	var line_height: float = float(dialogue_text.get_line_height())

	# Account for the Label's own scale.
	var text_scale: float = absf(dialogue_text.scale.y)

	if text_scale <= 0.0:
		return

	# Estimate the visual height of the wrapped text.
	var required_height: float = (
		float(line_count) * (line_height + 3.0) * text_scale
	)

	var original_height: float = original_text_size.y * text_scale

	var extra_height: float = maxf(
		0.0,
		ceilf(required_height - original_height)
	)

	# Extend the frame upward, keeping its bottom fixed.
	gold_frame.position = original_gold_position + Vector2(
		0.0, -extra_height
	)
	gold_frame.size = original_gold_size + Vector2(
		0.0, extra_height
	)

	dialogue_background.position = (
		original_background_position
		+ Vector2(0.0, -extra_height)
	)
	dialogue_background.size = (
		original_background_size
		+ Vector2(0.0, extra_height)
	)

	# Decorations remain attached to the upper border.
	frame_hourglass.position = (
		original_hourglass_position
		+ Vector2(0.0, -extra_height)
	)

	nameplate_border.position = (
		original_nameplate_position
		+ Vector2(0.0, -extra_height)
	)

	# Move the text upward and give it more vertical room.
	dialogue_text.position = (
		original_text_position
		+ Vector2(0.0, -extra_height)
	)

	dialogue_text.size = Vector2(
		original_text_size.x,
		original_text_size.y + extra_height / text_scale
	)


func get_speaker_color(speaker: String) -> Color:
	match speaker:
		"You":
			return Color("#72BDEB")

		"Narrator":
			return Color("#C1BB68")

		"God of Time":
			return Color("#BA8FDD")

		_:
			return Color.WHITE


func end_dialogue() -> void:
	is_active = false
	is_typing = false
	visible = false

	dialogue_finished.emit()
