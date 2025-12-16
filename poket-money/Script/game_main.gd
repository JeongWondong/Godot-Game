extends Node
@export var button_scene: PackedScene
@onready var list_container = $Companys_Container/Company_list_Container/Company_Container
@onready var money_label = $Money/control/panel/VBoxContainer/MoneyLabel
@onready var point_label = $Money/control/panel/VBoxContainer/PointLabel 	

const BASE_URL = "http://127.0.0.1:8080"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	## 응답이 오면 실행할 함수 연결
	#http_request.request_completed.connect(_on_request_completed)
	#
	## 실제 서버 주소로 요청 보내기(Spring 서버 주소)
	#http_request.request(BASE_URL) # 여기 부분을 변경하면 된다.
	#print("서버에 데이터 요청 중...")
	
	# print(">>> [DEBUG] 현재 스크립트 노드의 절대 경로:", self.get_path())
	
	## JavaScript Bridge가 이 노드의 'receive_assets'함수를 호출하도록 연결
	JavaScriptBridge.eval(
		"window.receive_assets = function(json_data) {" + 
		"  var game_root = document.getElementById('canvas')._godot_engine;" +
		"  if (game_root) {" +
		# 📌 경로를 다시 /root/game_main으로 지정합니다.
		"    game_root.get_node(\"/root/game_main\").call(\"receive_assets\", json_data);" + 
		"  }" +
		"}"
	)
	
	# 📌 회사 목록을 수신할 함수를 JavaScript Bridge에 등록
	JavaScriptBridge.eval(
		"window.receive_company_list = function(json_data) {" + 
		"  var game_root = document.getElementById('canvas')._godot_engine;" +
		"  if (game_root) {" +
		"    game_root.get_node(\"/root/game_main\").call(\"receive_company_list\", json_data);" + 
		"  }" +
		"}"
	)
	
	# 📌 서버 API 호출
	JavaScriptBridge.eval("getCompanyListToGodot()")
	print("서버에 회사 목록 데이터 요청 중...")
	
	
## 서버에서 응답이 왔을 때 실행되는 함수
#func _on_request_completed(result, response_code, headers, body):
	#if response_code == 200: # 성공
		## 받아온 데이터(body)를 글자 -> JSON으로 변환
		#var json_data = JSON.parse_string(body.get_string_from_utf8())
		#
		#print("서버 응답 데이터 : ", json_data)
		#
		## 기존에 만든 함수를 그대로 재사용
		#create_company_buttons(json_data)
	#else:
		#print("서버 연결 실패. 에러 코드 : ", response_code)
	
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
	pass

# 튜토리얼 화면 비활성화
func hide_tutorial() -> void:
	$Tutorial.visible = false
# 튜토리얼 화면 활성화
func _on_tutorial_button_pressed() -> void:
	$Tutorial.visible = true


# 보유 자금 X 아이콘 클릭시 화면 비활성화
func _on_money_cancel_button_pressed() -> void:
	$Money.visible = false

# 보유 자금 화면 활성화/비활성화
func _on_money_button_pressed() -> void:
	print("Money 버튼 눌림")
	$Money.visible = true
	JavaScriptBridge.eval("getMemberAssetsToGodot()")
	
func receive_assets(json_data):
	# 함수 실행 여부를 즉시 확인(브라우저 콘솔 확인)
	print(">>> [DEBUG] receive_assets 함수 실행 시작 <<<")
	
	# 1. JSON 문자열 파싱 (Godot 4.x 파싱 방식 적용)
	var result = JSON.parse_string(json_data)
	
	if result.error != OK:
		print("!!! [ERROR-GD] JSON 파싱 오류:", result.error_string)
		return
		
	var data = result.result
	
	if typeof(data) == TYPE_DICTIONARY:
		
		var property = data.get("property", 0)
		var pt = data.get("pt", 0)
		
		print(">>> [DEBUG-GD] 수신된 자산:", property)
		
		# 📌 2. CRITICAL CHECK: UI 노드 참조 확인
		if money_label == null:
			print("!!! [CRITICAL ERROR-GD] money_label 노드 참조 실패! 경로 오류.")
			# 📌 이 코드가 브라우저 콘솔에 떠야 합니다!
			print("!!! [DEBUG] money_label 예상 경로:", $Money/Money_Overlay/Money_Screen/VBoxContainer/MoneyLabel.get_path())
			return
		if point_label == null:
			print("!!! [CRITICAL ERROR-GD] point_label 노드 참조 실패! 경로 오류.")
			return
		
		# 📌 3. UI 업데이트: set_deferred 유지
		money_label.set_deferred("text", str(property))
		point_label.set_deferred("text", str(pt))
		
		# 시각적 확인 (Label이 화면에 존재한다면 빨간색으로 변해야 함)
		money_label.set_deferred("modulate", Color.RED)
		
	else:
		print("!!! [ERROR-GD] 수신된 데이터가 Dictionary 형태가 아닙니다. 타입:", typeof(data))


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
	if $News.visible:
		$News.visible = false
	else:
		$News.visible = true


# 힌트 상/중/하 선택 화면 활성화
func _on_hint_button_pressed() -> void:
	$Hint.visible = true


# 배경 클릭시 화면 비활성화
func _on_news_cancel_button_pressed() -> void:
	$News.visible = false # 뉴스 비활성화
	$Hint.visible = false # 힌트 비활성화

# 📌 DB에서 받은 회사 목록 데이터를 처리하는 새로운 함수
func receive_company_list(json_data):
	print(">>> [DEBUG-GD] 회사 목록 데이터 수신됨 <<<")
	
	# JSON 문자열 파싱
	var result = JSON.parse_string(json_data)
	
	if result.error != OK:
		print("!!! [ERROR-GD] 회사 목록 JSON 파싱 오류:", result.error_string)
		return
		
	var company_list = result.result
	
	if typeof(company_list) == TYPE_ARRAY:
		print(">>> [DEBUG-GD] 회사 목록 개수:", company_list.size())
		
		# 기존 함수를 재사용하여 버튼 생성
		create_company_buttons(company_list)
	else:
		print("!!! [ERROR-GD] 수신된 데이터가 Array 형태가 아닙니다. 서버 응답 확인 필요.")
