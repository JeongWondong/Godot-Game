extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 버튼이 눌리면 _on_pressed 함수 실행
	pressed.connect(_on_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


# 이 버튼이 어떤 회사의 버튼인지 기억할 변수
var company_data = {}

# 메인 화면에 "나 클릭됐어!"라고 알릴 신호
signal company_selected(data)

func setup(data):
	company_data = data
	text = data["name"] # 버튼의 글자를 회사 이름으로 변경

func _on_pressed():
	# 클릭되면 내 데이터를 담아서 신호를 보냄
	company_selected.emit(company_data)
