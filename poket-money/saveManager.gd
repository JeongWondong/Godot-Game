extends Node

# 저장될 파일 경로 (user:// 는 Godot의 안전한 저장 공간을 의미합니다)
const SAVE_PATH = "user://game_settings.cfg"

# "튜토리얼 봤음" 상태를 파일에 저장하는 함수
func set_tutorial_completed(value: bool):
	var config = ConfigFile.new()
	# "game" 섹션에 "tutorial_completed" 라는 키로 값을 저장
	config.set_value("game", "tutorial_completed", value)
	config.save(SAVE_PATH)

# "튜토리얼 봤음" 상태를 파일에서 불러오는 함수
func has_completed_tutorial() -> bool:
	var config = ConfigFile.new()
	
	# 파일을 불러오기 시도
	var err = config.load(SAVE_PATH)
	
	# 파일이 없거나(최초 실행) 로드에 실패하면
	if err != OK:
		return false # 튜토리얼을 본 적이 없는 것임 (false)
	
	# 파일이 있다면, 저장된 값을 반환 (혹시 키가 없으면 기본값 false)
	return config.get_value("game", "tutorial_completed", false)
