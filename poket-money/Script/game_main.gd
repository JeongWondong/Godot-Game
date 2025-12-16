extends Node

@export var button_scene: PackedScene

# 📌 메인 UI 노드
@onready var list_container = $Companys_Container/Company_list_Container/Company_Container
@onready var money_label = $Money/control/panel/VBoxContainer/MoneyLabel
@onready var point_label = $Money/control/panel/VBoxContainer/PointLabel 
@onready var time = $time

# 📌 팝업 노드
@onready var trade_popup = $buysell
@onready var company_dropdown = $buysell/Panel/CompanyOption
@onready var amount_input = $buysell/Panel/AmountInput
@onready var popup_buy_btn = $buysell/Panel/BuyButton
@onready var popup_sell_btn = $buysell/Panel/SellButton
@onready var popup_cancel_btn = $buysell/Panel/CancelButton

var cached_company_list = []

# 📌 자바스크립트 콜백 참조 변수 (메모리 해제 방지용)
var _js_company_list_callback = null
var _js_assets_callback = null

func _ready() -> void:
	trade_popup.visible = false
	
	# 1. 팝업 버튼 연결
	if not popup_buy_btn.pressed.is_connected(_on_buy_button_pressed):
		popup_buy_btn.pressed.connect(_on_buy_button_pressed)
	if not popup_sell_btn.pressed.is_connected(_on_sell_button_pressed):
		popup_sell_btn.pressed.connect(_on_sell_button_pressed)
	if not popup_cancel_btn.pressed.is_connected(_on_cancel_button_pressed):
		popup_cancel_btn.pressed.connect(_on_cancel_button_pressed)

	# 📌 [핵심 해결책] JavaScriptBridge Callback 방식 사용
	# 경로를 찾을 필요 없이 Godot 함수를 직접 자바스크립트 변수에 할당합니다.
	
	# 2-1. 회사 목록 수신용 콜백 생성
	_js_company_list_callback = JavaScriptBridge.create_callback(_on_js_receive_company_list)
	var window = JavaScriptBridge.get_interface("window")
	# 기존 window.receive_company_list 함수를 내 콜백으로 덮어씌움
	window.receive_company_list = _js_company_list_callback
	
	# 2-2. 자산(Assets) 수신용 콜백 생성
	_js_assets_callback = JavaScriptBridge.create_callback(_on_js_receive_assets)
	window.receive_assets = _js_assets_callback
	
	print(">>> [DEBUG] JS 함수 강제 덮어쓰기 완료 (Callback 방식)")
	
	# 3. 데이터 요청
	JavaScriptBridge.eval("getCompanyListToGodot()")
	JavaScriptBridge.eval("getMemberAssetsToGodot()")

# 📌 [콜백 함수 1] 자바스크립트가 회사 목록을 보내면 이 함수가 바로 실행됨
func _on_js_receive_company_list(args):
	# args[0]에 자바스크립트가 보낸 데이터가 들어있음
	print(">>> [DEBUG] Godot 콜백 함수 실행됨! 데이터 수신 성공")
	
	var json_data = args[0] # JS 객체 또는 JSON 문자열
	var company_list = []
	
	# JS 객체(Array)로 바로 들어오는 경우 (Godot 4 자동 변환)
	if typeof(json_data) == TYPE_ARRAY:
		company_list = json_data
	# JSON 문자열로 들어오는 경우
	elif typeof(json_data) == TYPE_STRING:
		var parsed = JSON.parse_string(json_data)
		if typeof(parsed) == TYPE_ARRAY:
			company_list = parsed
		elif typeof(parsed) == TYPE_DICTIONARY and parsed.has("result"):
			company_list = parsed.result
			
	# 데이터 처리
	if company_list.size() > 0:
		cached_company_list = company_list
		create_company_buttons(company_list)
		if trade_popup.visible:
			_refresh_dropdown()
		print(">>> [성공] 회사 목록 로드 완료. 개수: ", company_list.size())
	else:
		print("!!! [오류] 데이터 형식을 알 수 없음: ", json_data)

# 📌 [콜백 함수 2] 자산 정보 수신
func _on_js_receive_assets(args):
	var data = args[0]
	# 문자열이면 파싱, 아니면 바로 사용
	if typeof(data) == TYPE_STRING:
		var parsed = JSON.parse_string(data)
		if parsed: data = parsed
		
	if typeof(data) == TYPE_DICTIONARY:
		var money = data.get("property", 0)
		var point = data.get("pt", 0)
		if money_label: money_label.text = str(money) + " 원"
		if point_label: point_label.text = str(point) + " P"

# 📌 버튼 생성
func create_company_buttons(company_list):
	if list_container == null: return
	for child in list_container.get_children(): child.queue_free()
	
	for data in company_list:
		var btn = button_scene.instantiate()
		list_container.add_child(btn)
		
		# 버튼 텍스트 설정
		if btn is Button:
			btn.text = data.get("coName", data.get("name", "이름없음"))
		if btn.has_method("setup"):
			btn.setup(data)
			
		if btn is Control:
			btn.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
			btn.custom_minimum_size = Vector2(0, 60)
			
	list_container.call_deferred("queue_sort")

# 📌 드롭다운 갱신
func _refresh_dropdown():
	company_dropdown.clear()
	if cached_company_list.size() == 0:
		company_dropdown.add_item("로딩 중...")
		company_dropdown.set_item_metadata(0, null)
		return
	var index = 0
	for company in cached_company_list:
		var co_name = company.get("coName", company.get("name", "Unknown"))
		var co_id = company.get("coNum", company.get("id", null))
		company_dropdown.add_item(co_name, index)
		company_dropdown.set_item_metadata(index, co_id)
		index += 1

# 팝업 및 거래 로직
func _on_trade_pressed() -> void:
	$buysell.visible = true
	amount_input.text = ""
	_refresh_dropdown()

func _process_trade(type: String):
	if company_dropdown.get_selected_id() == -1: return
	var idx = company_dropdown.get_selected_id()
	var co_id = company_dropdown.get_item_metadata(idx)
	var amount = int(amount_input.text)
	
	if co_id == null: return
	
	# 서버 전송
	JavaScriptBridge.eval("sendTradeRequest('%s', %d, %d)" % [type, int(co_id), amount])
	trade_popup.visible = false

# 버튼 연결 함수들
func _on_buy_button_pressed(): _process_trade("BUY")
func _on_sell_button_pressed(): _process_trade("SELL")
func _on_cancel_button_pressed(): trade_popup.visible = false

# 빈 함수들
func _on_company_selected(data): pass
func _process(delta): pass
func _on_money_button_pressed(): $Money.visible = true
func _on_money_cancel_button_pressed(): $Money.visible = false
func hide_tutorial(): pass
func _on_tutorial_button_pressed(): pass
func _on_setting_button_pressed(): pass
func _on_setting_cancel_pressed(): pass
func _on_save_and_exit_pressed(): pass
func _on_news_button_pressed(): pass
func _on_hint_button_pressed(): pass
func _on_news_cancel_button_pressed(): pass
func _on_magam_button_pressed(): pass
