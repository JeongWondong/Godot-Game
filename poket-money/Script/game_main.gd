extends Node
@export var button_scene: PackedScene
@onready var list_container = $Companys_Container/Company_list_Container/Company_Container

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var db_data = [
		{"id": 1, "name": "삼성전자", "price": 700000},
		{"id": 2, "name": "SK하이닉스", "price": 1200000},
		{"id": 3, "name": "네이버", "price": 200000},
	]
	create_company_buttons(db_data)
	
# 목록을 생성하는 함수
func create_company_buttons(company_list):
	for child in list_container.get_children():
		child.queue_free()
		
	# 데이터 개수만큼 반복해서 버튼 생성
	for data in company_list:
		# 버튼 인스턴스(실체) 생성
		var btn = button_scene.instantiate()
		
		# 컨테이너 자식으로 추가
		list_container.add_child(btn)
		
		# 버튼에 데이터 주입
		btn.setup(data)
		
		# 버튼 클릭 신호 연결
		# 버튼이 클릭되면 메인 스크립트의 _on_company_selected 함수가 실행되게 연결
		btn.company_selected.connect(_on_company_selected)
		
# 특정 회사가 클릭되었을 때 실행될 함수
func _on_company_selected(data):
	print("선택된 회사: ", data["name"])
	# 여기에 오른쪽 그래프 화면을 갱신하는 코드를 넣는다.
	# 예시) update_graph(data["id"])

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

# 보유 자금 화면 활성화/비활성화
func _on_money_button_pressed() -> void:
	if $Money_Screen.visible:
		$Money_Screen.visible = false
	else:
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


# 뉴스 화면 활성화/비활성화
func _on_news_button_pressed() -> void:
	if $News_Container.visible:
		$News_Container.visible = false
	else:
		$News_Container.visible = true


# 배경 화면 클릭시 핍업 비활성화
func _on_screen_off_button_pressed() -> void:
	$News_Container.visible = false
	$Money_Screen.visible = false
	$Setting_Menu.visible = false
