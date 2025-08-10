extends Node
class_name DataStore
## [필수] 앱 전역 상태와 저장/불러오기를 담당하는 Autoload 싱글톤.
## - staffs, duties, assignments를 메모리에 보관
## - JSON 파일(user://assignments.json)로 저장/로드
## - 데이터 변경시 data_changed 시그널 발신

signal data_changed()

# --------------------------
# 상태(런타임 메모리 캐시)
# --------------------------
var staffs: Dictionary = {}     # id(String) -> Staff
var duties: Dictionary = {}     # id(String) -> Duty
var assignments: Array[Assignment] = []  # 배정 레코드 리스트

# --------------------------
# 저장 위치
# --------------------------
const SAVE_PATH := "user://assignments.json"

# --------------------------
# 생명주기
# --------------------------

func _ready() -> void:
	## [필수] 노드 준비 완료 시 자동 실행.
	## - 저장 파일이 있으면 로드, 없으면 시드(초기 데이터) 생성 후 저장
	## - 완료 후 data_changed 시그널 1회 발행
	load_all()

# --------------------------
# 퍼블릭 API(외부에서 호출)
# --------------------------

func load_all() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var text: String = f.get_as_text()
		var parsed: Variant = JSON.parse_string(text)  # <-- 명시적으로 Variant
		if typeof(parsed) == TYPE_DICTIONARY:
			_from_dict(parsed as Dictionary)           # 필요시 캐스팅
		else:
			_load_seed()
			save_all()
	else:
		_load_seed()
		save_all()

	emit_signal("data_changed")


func save_all() -> void:
	var d = _to_dict()
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(d, "  ")) # pretty print
	emit_signal("data_changed")



func clear_all(confirm: bool = true) -> void:
	## [선택] 모든 데이터(교직원/업무/배정)를 메모리에서 비우고 저장 파일도 초기화.
	## - 배정 리셋이나 “새 프로젝트” 기능이 필요할 때 유용
	## 부작용: 되돌리기 불가(백업 권장)
	if confirm:
		staffs.clear()
		duties.clear()
		assignments.clear()
		save_all()
	else:
		# confirm=false라도 행동은 동일하게 처리(원하면 로직 바꾸세요)
		staffs.clear()
		duties.clear()
		assignments.clear()
		save_all()


func export_csv(path: String) -> void:
	## [선택] 엑셀 호환 CSV로 내보내기 (date, duty, staff 컬럼)
	## - UI의 “내보내기” 메뉴용
	## 부작용: 지정 경로 파일 생성/덮어쓰기
	var out := "date,duty,staff\n"
	for a in assignments:
		var duty_title = duties[a.duty_id].title if duties.has(a.duty_id) else a.duty_id
		var staff_name = staffs[a.staff_id].name if staffs.has(a.staff_id) else a.staff_id
		out += "%s,%s,%s\n" % [a.date, duty_title, staff_name]

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(out)
	else:
		push_error("CSV 저장 실패: %s" % path)




func import_json(dict_data: Dictionary) -> void:
	## [선택] 외부 JSON(동일 스키마)을 받아 현재 상태로 반영.
	## - 다른 파일에서 불러오기를 UI에서 처리했다면, 파싱 후 여기로 전달
	## 부작용: 현재 메모리 상태 대체, 저장 파일도 덮어쓸 수 있음(원하면 save_all 호출)
	_from_dict(dict_data)
	emit_signal("data_changed")

# --------------------------
# 내부 유틸(프라이빗)
# --------------------------

func _load_seed() -> void:
	## [권장] 저장 파일이 없거나 손상되었을 때 사용할 초기 데이터 로드.
	## - 학교 업무 앱 특성상 첫 실행 UX를 위해 기본 항목 제공
	var seed := {
		"staffs": [
			{"id":"s1","name":"김담임","dept":"교무","tags":["1학년"],"max_load":3},
			{"id":"s2","name":"이교사","dept":"학생","tags":["체육"],"max_load":2},
		],
		"duties": [
			{"id":"d1","title":"조례지도","category":"일상","required_count":2,"weight":1.0},
			{"id":"d2","title":"급식당번","category":"일상","required_count":3,"weight":1.0},
			{"id":"d3","title":"축제운영","category":"행사","required_count":4,"weight":2.0},
		],
		"assignments":[]
	}
	_from_dict(seed)


func _from_dict(d: Dictionary) -> void:
	## [필수] Dictionary(JSON 파싱 결과)를 런타임 오브젝트로 역직렬화.
	## - 기존 상태 초기화 후 Staff/Duty/Assignment 생성
	## 부작용: 기존 메모리 상태 파기
	staffs.clear()
	duties.clear()
	assignments.clear()

	# Staff 역직렬화
	for s in d.get("staffs", []):
		var st := Staff.new(s.id, s.name, s.get("dept",""))
		st.tags = s.get("tags", [])
		st.max_load = int(s.get("max_load", 3))
		st.unavailable = s.get("unavailable", {})
		staffs[st.id] = st

	# Duty 역직렬화
	for t in d.get("duties", []):
		var du := Duty.new()
		du.id = t.id
		du.title = t.title
		du.category = t.get("category","")
		du.required_count = int(t.get("required_count",1))
		du.weight = float(t.get("weight",1.0))
		du.notes = t.get("notes","")
		duties[du.id] = du

	# Assignment 역직렬화
	for a in d.get("assignments", []):
		var asn := Assignment.new()
		asn.date = a.date
		asn.duty_id = a.duty_id
		asn.staff_id = a.staff_id
		assignments.append(asn)


func _to_dict() -> Dictionary:
	var staffs_arr = []
	for s in staffs.values():
		staffs_arr.append(_staff_to_dict(s))

	var duties_arr = []
	for d in duties.values():
		duties_arr.append(_duty_to_dict(d))

	var assignments_arr = []
	for a in assignments:
		assignments_arr.append({
			"date": a.date if a is Assignment else a["date"],
			"duty_id": a.duty_id if a is Assignment else a["duty_id"],
			"staff_id": a.staff_id if a is Assignment else a["staff_id"]
		})

	return {
		"staffs": staffs_arr,
		"duties": duties_arr,
		"assignments": assignments_arr
	}



func _staff_to_dict(s: Staff) -> Dictionary:
	## [필수] Staff -> Dictionary 직렬화 유틸.
	return {
		"id": s.id,
		"name": s.name,
		"dept": s.dept,
		"tags": s.tags,
		"max_load": s.max_load,
		"unavailable": s.unavailable
	}


func _duty_to_dict(d: Duty) -> Dictionary:
	## [필수] Duty -> Dictionary 직렬화 유틸.
	return {
		"id": d.id,
		"title": d.title,
		"category": d.category,
		"required_count": d.required_count,
		"weight": d.weight,
		"notes": d.notes
	}
