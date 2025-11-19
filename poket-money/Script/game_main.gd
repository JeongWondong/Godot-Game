extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# 튜토리얼 화면에서 OK 버튼을 눌렀을 때 튜토리얼 화면 비활성화 직접 연결
	$Tutorial/Tutorial_Overlay/Panel/Button.pressed.connect(hide_tutorial)


# 튜토리얼 화면 비활성화
func hide_tutorial() -> void:
	$Tutorial.visible = false

# 튜토리얼 화면 활성화
func _on_tutorial_button_pressed() -> void:
	$Tutorial.visible = true


# 보유 자금 화면 비활성화
func _on_money_cancel_button_pressed() -> void:
	$Money_Screen.visible = false

# 보유 자금 화면 활성화
func _on_money_button_pressed() -> void:
	$Money_Screen.visible = true


# Setting 화면 활성화
func _on_setting_button_pressed() -> void:
	$Setting_Menu.visible = true

# Setting 화면 비활성화
func _on_setting_cancel_pressed() -> void:
	$Setting_Menu.visible = false

# 저장 후 나가기 (저장하는 코드 작성 필요)
func _on_save_and_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
