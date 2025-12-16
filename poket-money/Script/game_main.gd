extends Node
@export var button_scene: PackedScene
@onready var list_container = $Companys_Container/Company_list_Container/Company_Container
@onready var money_label = $Money/control/panel/VBoxContainer/MoneyLabel
@onready var point_label = $Money/control/panel/VBoxContainer/PointLabel 
@onready var time = $time

@onready var trade_popup = $buysell
@onready var company_dropdown = $buysell/Panel/CompanyOption
@onready var amount_input = $buysell/Panel/AmountInput
@onready var popup_buy_btn = $buysell/Panel/BuyButton
@onready var popup_sell_btn = $buysell/Panel/SellButton
@onready var popup_cancel_btn = $buysell/Panel/CancelButton

var cached_company_list = []

const BASE_URL = "http://127.0.0.1:8080"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	
	# 처음에는 팝업 숨기기
	trade_popup.visible = false
	
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
	
	
# 목록을 생성하는 함수
func create_company_buttons(company_list):
	# 📌 [디버깅] list_container 노드 유효성 및 경로 확인
	if list_container == null:
		print("!!! [CRITICAL ERROR-GD] list_container 노드 참조 실패. 경로를 다시 확인하세요.")
		return
		
	# 1. 기존 자식 노드 제거
	for child in list_container.get_children():
		child.queue_free()
	
	# 2. 버튼 생성 및 추가
	for data in company_list:
		# 버튼 인스턴스(실체) 생성
		var btn = button_scene.instantiate()
		
		if btn is Control:
		# 📌 필수: 최소 크기를 설정하여 공간을 확보합니다.
			btn.custom_minimum_size = Vector2(0, 70) 
			btn.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
		
		list_container.add_child(btn)
		
		# 2. 버튼 생성 및 추가
	for data in company_list:
		var btn = button_scene.instantiate()
		
		if btn is Control:
			# VBoxContainer 내에서 전체 너비를 채우도록 설정 (필수)
			btn.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
			
			# 📌 버튼의 최소 높이를 지정하여 겹치지 않게 합니다.
			# 이 값이 0이면 VBoxContainer가 공간을 확보하지 못해 버튼이 겹칩니다.
			btn.custom_minimum_size = Vector2(0, 70) # 70픽셀 (이전보다 키움)
		
		list_container.add_child(btn)
		btn.setup(data)
		btn.company_selected.connect(_on_company_selected)
		
	# 📌 3. 레이아웃 강제 갱신: call_deferred를 사용하여 안전하게 갱신 요청 (핵심)
	# 버튼 추가 작업이 모두 끝난 후, 다음 프레임에 정렬을 요청합니다.
	list_container.call_deferred("queue_sort")
	
	# 📌 4. 부모에게도 갱신을 요청 (전체 UI가 리사이즈되도록)
	if list_container.get_parent() is Control:
		list_container.get_parent().call_deferred("queue_sort")
		
	print(">>> [DEBUG-GD] 버튼 " + str(company_list.size()) + "개 추가 및 UI 갱신 요청 완료.")
	print(">>> [DEBUG-GD] VBoxContainer 위치 (X, Y): ", list_container.global_position)
	print(">>> [DEBUG-GD] VBoxContainer 크기 (W, H): ", list_container.size)


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
		
		cached_company_list = company_list 
		create_company_buttons(company_list) # 기존 버튼 생성 로직
		
		# 기존 함수를 재사용하여 버튼 생성
		create_company_buttons(company_list)
	else:
		print("!!! [ERROR-GD] 수신된 데이터가 Array 형태가 아닙니다. 서버 응답 확인 필요.")

	
func _on_magam_button_pressed() -> void:
	print("Next Turn 버튼 눌림. 서버에 다음 턴 요청 중...")
	
	# JavaScript 함수 호출 (main.html에 정의할 함수)
	JavaScriptBridge.eval("goToNextTurn()")


func _on_trade_pressed() -> void:
	$buysell.visible = true
	amount_input.text = ""
	
	#드롭다운 초기화 및 데이터 채우기
	company_dropdown.clear()
	
	var index = 0
	for company in cached_company_list:
		# 회사 이름 표시 (DB 필드명: coName 확인 필요)
		var co_name = company.get("coName", "Unknown")
		var co_id = company.get("id", -1) # id 필드 확인 필요
		
		company_dropdown.add_item(co_name, index)
		
		# ★ 핵심: 드롭다운 아이템의 '메타데이터'에 회사 ID를 숨겨둠
		company_dropdown.set_item_metadata(index, co_id)
		index += 1

# [매수] 버튼 클릭 시
func _on_buy_button_pressed() -> void:
	_process_trade("BUY")

# [매도] 버튼 클릭 시
func _on_sell_button_pressed() -> void:
	_process_trade("SELL")

# [취소] 버튼 클릭 시
func _on_cancel_button_pressed() -> void:
	trade_popup.visible = false

# 실제 거래 요청을 처리하는 공통 함수
func _process_trade(type: String):
	# 1. 드롭다운에서 선택된 회사 ID 가져오기
	var selected_idx = company_dropdown.get_selected_id()
	if selected_idx == -1:
		print("회사가 선택되지 않았습니다.")
		return
		
	var company_id = company_dropdown.get_item_metadata(selected_idx)
	
	# 2. 입력된 금액 가져오기
	var amount_str = amount_input.text
	if not amount_str.is_valid_int():
		print("유효하지 않은 금액입니다.")
		return
	var amount = int(amount_str)
	
	if amount <= 0:
		print("0원 이상 입력해야 합니다.")
		return

	print("거래 요청: ", type, " 회사ID: ", company_id, " 금액: ", amount)
	
	# 3. 자바스크립트 함수 호출 (서버로 전송)
	# main.html에 sendTradeRequest 함수가 정의되어 있어야 함
	JavaScriptBridge.eval("sendTradeRequest('%s', %d, %d)" % [type, company_id, amount])
	
	# 4. 팝업 닫기
	trade_popup.visible = false
