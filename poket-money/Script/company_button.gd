# company_button.gd
extends Button

# 이 버튼이 어떤 회사의 버튼인지 기억할 변수
var company_data = {}

# 메인 화면에 "나 클릭됐어!"라고 알릴 신호
signal company_selected(data)

func setup(data):
	company_data = data
	# 📌 이름(coName) 또는 name을 확인해서 버튼 텍스트 변경
	text = data.get("coName", data.get("name", "Unknown"))

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed():
	# 클릭되면 내 데이터를 담아서 신호를 보냄
	company_selected.emit(company_data)
