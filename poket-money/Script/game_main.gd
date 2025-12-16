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

# 📌 [그래프] 관련 노드 (사진에 맞춰 경로 수정됨)
# CompanyGraph -> GraphFrame -> GraphLine 구조라고 가정
@onready var graph_bg = $CompanyGraph/GraphFrame
@onready var graph_line = $CompanyGraph/GraphFrame/GraphLine 

# 전역 변수
var cached_company_list = []

# 콜백 참조 변수 (메모리 해제 방지)
var _js_company_list_callback = null
var _js_assets_callback = null
var _js_price_history_callback = null # 그래프용 콜백

func _ready() -> void:
	trade_popup.visible = false
	
	# 1. 팝업 버튼 연결
	if not popup_buy_btn.pressed.is_connected(_on_buy_button_pressed):
		popup_buy_btn.pressed.connect(_on_buy_button_pressed)
	if not popup_sell_btn.pressed.is_connected(_on_sell_button_pressed):
		popup_sell_btn.pressed.connect(_on_sell_button_pressed)
	if not popup_cancel_btn.pressed.is_connected(_on_cancel_button_pressed):
		popup_cancel_btn.pressed.connect(_on_cancel_button_pressed)

	# 📌 2. 자바스크립트 인터페이스 가져오기 (여기서 한 번만 선언!)
	var window = JavaScriptBridge.get_interface("window")
	
	# 3. 콜백 연결 (회사 목록)
	_js_company_list_callback = JavaScriptBridge.create_callback(_on_js_receive_company_list)
	window.receive_company_list = _js_company_list_callback
	
	# 4. 콜백 연결 (자산 정보)
	_js_assets_callback = JavaScriptBridge.create_callback(_on_js_receive_assets)
	window.receive_assets = _js_assets_callback
	
	# 5. 📌 [그래프] 콜백 연결 (주가 기록)
	_js_price_history_callback = JavaScriptBridge.create_callback(_on_js_receive_price_history)
	window.receive_price_history = _js_price_history_callback
	
	print(">>> [DEBUG] JS 콜백 연결 완료")
	
	# 6. 초기 데이터 요청
	JavaScriptBridge.eval("getCompanyListToGodot()")
	JavaScriptBridge.eval("getMemberAssetsToGodot()")

# 📌 [그래프] 회사 버튼 클릭 시 실행 (그래프 데이터 요청)
func _on_company_selected(data):
	# 1. 회사 ID 가져오기
	var co_id = data.get("coNum", data.get("id", null))
	
	if co_id != null:
		print(">>> [그래프] ID:", co_id, " 데이터 요청")
		JavaScriptBridge.eval("getCompanyPriceHistoryToGodot(" + str(co_id) + ")")

# 📌 [그래프] 데이터 수신 및 그리기 (콜백)
func _on_js_receive_price_history(args):
	var json_data = args[0]
	var price_list = []
	
	# 데이터 파싱
	if typeof(json_data) == TYPE_STRING:
		var parsed = JSON.parse_string(json_data)
		if typeof(parsed) == TYPE_ARRAY: price_list = parsed
	elif typeof(json_data) == TYPE_ARRAY:
		price_list = json_data
		
	print(">>> [그래프] 데이터 수신. 개수: ", price_list.size())
	draw_graph(price_list)

# 📌 [그래프] 실제 그리기 로직
func draw_graph(prices: Array):
	if graph_line == null: 
		print("!!! [오류] GraphLine 노드를 찾을 수 없습니다.")
		return
		
	if prices.size() < 2: return
		
	graph_line.clear_points() # 기존 선 지우기
	
	# 최대/최소 가격 찾기
	var min_p = prices[0]
	var max_p = prices[0]
	for p in prices:
		if p < min_p: min_p = p
		if p > max_p: max_p = p
		
	if min_p == max_p:
		max_p += 100
		min_p -= 100
		
	# 그래프 크기 및 좌표 계산
	var width = graph_bg.size.x
	var height = graph_bg.size.y
	var margin = 20
	
	for i in range(prices.size()):
		var price = prices[i]
		var ratio_x = float(i) / float(prices.size() - 1)
		var x = margin + (ratio_x * (width - margin * 2))
		
		var ratio_y = float(price - min_p) / float(max_p - min_p)
		var y = (height - margin) - (ratio_y * (height - margin * 2))
		
		graph_line.add_point(Vector2(x, y))

# --- 기존 매수/매도 및 기타 로직 (그대로 유지) ---

func _on_js_receive_company_list(args):
	var json_data = args[0]
	var company_list = []
	if typeof(json_data) == TYPE_ARRAY: company_list = json_data
	elif typeof(json_data) == TYPE_STRING:
		var parsed = JSON.parse_string(json_data)
		if typeof(parsed) == TYPE_ARRAY: company_list = parsed
			
	if company_list.size() > 0:
		cached_company_list = company_list
		create_company_buttons(company_list)
		if trade_popup.visible: _refresh_dropdown()

func _on_js_receive_assets(args):
	var data = args[0]
	if typeof(data) == TYPE_STRING:
		var parsed = JSON.parse_string(data)
		if parsed: data = parsed
	if typeof(data) == TYPE_DICTIONARY:
		var money = data.get("property", 0)
		var point = data.get("pt", 0)
		if money_label: money_label.text = str(money) + " 원"
		if point_label: point_label.text = str(point) + " P"

func create_company_buttons(company_list):
	if list_container == null: return
	for child in list_container.get_children(): child.queue_free()
	
	for data in company_list:
		var btn = button_scene.instantiate()
		list_container.add_child(btn)
		
		# 버튼 설정
		if btn.has_method("setup"): btn.setup(data)
		# 📌 버튼 클릭 신호를 _on_company_selected 함수와 연결!
		if btn.has_signal("company_selected"):
			if not btn.company_selected.is_connected(_on_company_selected):
				btn.company_selected.connect(_on_company_selected)
			
		if btn is Control:
			btn.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
			btn.custom_minimum_size = Vector2(0, 60)
	list_container.call_deferred("queue_sort")

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
	JavaScriptBridge.eval("sendTradeRequest('%s', %d, %d)" % [type, int(co_id), amount])
	trade_popup.visible = false

func _on_buy_button_pressed(): _process_trade("BUY")
func _on_sell_button_pressed(): _process_trade("SELL")
func _on_cancel_button_pressed(): trade_popup.visible = false

# 빈 함수들
func _on_money_button_pressed(): $Money.visible = true
func _on_money_cancel_button_pressed(): $Money.visible = false
func hide_tutorial(): pass
func _on_tutorial_button_pressed(): pass
func _on_setting_button_pressed(): pass
func _on_setting_cancel_pressed(): pass
func _on_save_and_exit_pressed(): pass
func _on_news_button_pressed(): pass
func _on_hint_button_pressed(): pass
