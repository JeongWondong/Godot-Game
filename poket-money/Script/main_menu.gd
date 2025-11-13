extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	# 메인메뉴에서 게임 화면으로 이동
	get_tree().change_scene_to_file("res://Scenes/game_main.tscn")


func _on_exit_button_pressed() -> void:
	if OS.get_name() == "Web":
		# 웹 브라우저인 경우, '뒤로 가기'를 실행 (페이지 나가기)
		JavaScriptBridge.eval("history.back();")
	else:
		# 웹이 아닌 데스크톱(Windows, macOS) 환경인 경우
		get_tree().quit()
