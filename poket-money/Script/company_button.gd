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
	
	# 📌 DB/JSON에서 수신된 키 이름(coName)을 정확하게 사용합니다.
	if data.has("coName"):
		text = data["coName"]
	else:
		# 혹시 키가 다를 경우를 대비한 디버깅
		text = "키 오류: " + str(data)

func _on_pressed():
	# 클릭되면 내 데이터를 담아서 신호를 보냄
	company_selected.emit(company_data)
