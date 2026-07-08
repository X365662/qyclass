"""URP 教务系统数据解析器

适配: URP 综合教务系统 (jws.qgxy.cn)
课表数据来自 AJAX 接口返回的 JSON
"""

import json
import re
from typing import List, Dict, Any, Optional
from bs4 import BeautifulSoup


# ==================== 主解析函数 ====================

def parse_urp_schedule_json(json_text: str) -> Dict[str, Any]:
    """
    解析 URP 系统课表 AJAX 返回的 JSON 数据

    JSON 结构:
    {
      "allUnits": 30.0,
      "xkxx": [
        { "COURSE_CODE_01": {
            "courseName": "课程名",
            "attendClassTeacher": "教师",
            "unit": 1.0,
            "courseCategoryName": "公共选修",
            "coursePropertiesName": "公选",
            "timeAndPlaceList": [{
              "classDay": 6,
              "classSessions": 7,
              "continuingSession": 2,
              "classroomName": "2303",
              "teachingBuildingName": "第二教学楼",
              "classWeek": "001111111100000000000000",
              "weekDescription": "3-10周",
              "campusName": "丰润校区"
            }]
        }}}
      ]
    }
    """
    courses = []
    schedules = []

    try:
        data = json.loads(json_text)
    except json.JSONDecodeError:
        # 可能不是纯 JSON，尝试从文本中提取
        data = _extract_json_from_text(json_text)
        if data is None:
            return {"courses": [], "schedules": []}

    xkxx = data.get("xkxx", [])
    if not xkxx:
        # 也可能是其他 key
        for key in ["list", "data", "rows", "result"]:
            xkxx = data.get(key, [])
            if xkxx:
                break

    course_index = {}
    schedule_id = 0

    for item in xkxx:
        if not isinstance(item, dict):
            continue

        # 每个 item 是 {课程编号: {...}} 的结构
        for course_code, course_data in item.items():
            if not isinstance(course_data, dict):
                continue

            course_name = course_data.get("courseName", "")
            if not course_name:
                continue

            teacher = (course_data.get("attendClassTeacher") or "").rstrip("* ").strip()
            credit = float(course_data.get("unit", 0))
            course_type = course_data.get("coursePropertiesName") or course_data.get("courseCategoryName", "必修")

            # 生成课程 ID
            course_id = course_data.get("id", {}).get("coureNumber") or course_code.split("_")[0]
            if not isinstance(course_id, str):
                course_id = str(course_code)

            # 记录课程（去重）
            if course_id not in course_index:
                course_index[course_id] = {
                    "id": course_id,
                    "name": course_name,
                    "teacher": teacher,
                    "credit": credit,
                    "type": course_type,
                }

            # 解析上课时间地点
            time_list = course_data.get("timeAndPlaceList", [])
            if not time_list:
                # 有些课程没有时间（如自学课程），跳过
                continue

            for tp in time_list:
                if not isinstance(tp, dict):
                    continue

                day_of_week = tp.get("classDay", 1)  # 1=周一
                start_period = tp.get("classSessions", 1)
                duration = tp.get("continuingSession", 2)
                classroom = tp.get("classroomName", "") or ""
                building = tp.get("teachingBuildingName", "") or ""

                # 解析周次
                start_week, end_week, week_type = _parse_urp_weeks(
                    tp.get("classWeek", ""),
                    tp.get("weekDescription", "")
                )

                schedule_id += 1
                schedules.append({
                    "course_id": course_id,
                    "course_name": course_name,
                    "teacher": teacher,
                    "day_of_week": int(day_of_week),
                    "start_period": int(start_period),
                    "duration": int(duration),
                    "location": f"{building}{classroom}",
                    "building": building,
                    "start_week": start_week,
                    "end_week": end_week,
                    "week_type": week_type,
                    "credit": credit,
                    "type": course_type,
                })

    return {
        "courses": list(course_index.values()),
        "schedules": schedules,
    }


def _parse_urp_weeks(class_week: str, week_description: str) -> tuple:
    """
    解析 URP 系统的周次格式

    classWeek: "001111111100000000000000" (二进制字符串, 长度=20, 1=有课 0=无课)
    weekDescription: "3-10周" (人类可读)

    返回: (start_week, end_week, week_type)
    """
    # 优先用 weekDescription
    if week_description:
        week_description = week_description.replace("周", "")
        # "3-10" 格式
        match = re.match(r'(\d+)\s*[-–—~]\s*(\d+)', week_description)
        if match:
            start = int(match.group(1))
            end = int(match.group(2))
            return (start, end, "every")

    # 解析 classWeek 二进制字符串
    if class_week and len(class_week) > 0:
        ones = [i + 1 for i, c in enumerate(class_week) if c == '1']
        if ones:
            start_week = min(ones)
            end_week = max(ones)

            # 判断单双周
            odd_weeks = [w for w in ones if w % 2 == 1]
            even_weeks = [w for w in ones if w % 2 == 0]

            if odd_weeks and not even_weeks:
                return (start_week, end_week, "odd")
            elif even_weeks and not odd_weeks:
                return (start_week, end_week, "even")

            return (start_week, end_week, "every")

    return (1, 18, "every")


def _extract_json_from_text(text: str) -> Optional[dict]:
    """从混合文本中提取 JSON 对象"""
    # 尝试直接解析
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # 找 { 开头 } 结尾的块
    depth = 0
    start = -1
    for i, c in enumerate(text):
        if c == '{':
            if depth == 0:
                start = i
            depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0 and start >= 0:
                try:
                    return json.loads(text[start:i+1])
                except json.JSONDecodeError:
                    start = -1
    return None


# ==================== 兼容旧版解析（备用） ====================

def parse_schedule_json(html: str) -> List[Dict[str, Any]]:
    """兼容旧接口：从 HTML 中提取 JSON 课表"""
    result = parse_urp_schedule_json(html)
    return result.get("schedules", [])


def parse_schedule_table(html: str) -> List[Dict[str, Any]]:
    """备用：解析 HTML 表格"""
    return []


def parse_empty_classroom_page(html: str) -> List[Dict[str, Any]]:
    """备用：解析空教室页面，URP 系统通常返回 JSON"""
    try:
        data = json.loads(html)
        if isinstance(data, list):
            return [_parse_classroom_item(item) for item in data]
        if isinstance(data, dict):
            lst = data.get('list') or data.get('data') or data.get('rows') or []
            return [_parse_classroom_item(item) for item in lst]
    except (json.JSONDecodeError, TypeError):
        pass
    return []


def _parse_classroom_item(item: dict) -> Dict[str, Any]:
    return {
        "building": item.get('building') or item.get('teachingBuildingName') or item.get('jxl') or '',
        "room_number": str(item.get('roomNumber') or item.get('classroomName') or item.get('room') or ''),
        "capacity": int(item.get('capacity') or 0),
    }
