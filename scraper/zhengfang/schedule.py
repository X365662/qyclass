"""课表抓取模块 — URP 综合教务系统

数据流:
  1. GET /student/courseSelect/thisSemesterCurriculum/index
  2. 从页面提取动态 ID
  3. GET .../ajaxStudentSchedule/curr/callback → JSON
  4. 解析 JSON → 结构化课表数据
"""

import re
from typing import Dict, List, Any
from bs4 import BeautifulSoup

from .client import ZhengfangClient
from .parser import parse_urp_schedule_json


def fetch_schedule(client: ZhengfangClient) -> Dict[str, Any]:
    """
    拉取当前学期课表

    返回格式:
    {
        "semester": {...},
        "courses": [{id, name, teacher, credit, type}],
        "schedules": [{course_id, ...}]
    }
    """
    # Step 1: 获取课表页面
    schedule_page_url = "/student/courseSelect/thisSemesterCurriculum/index"
    resp = client.get(schedule_page_url)

    if resp.status_code != 200 or len(resp.text) < 500:
        # 重定向到登录页？session 过期
        return _empty_result()

    html = resp.text

    # Step 2: 提取动态 ID
    # 页面中有类似: /student/courseSelect/thisSemesterCurriculum/xxxxx/ajaxStudentSchedule/curr/callback
    match = re.search(r'thisSemesterCurriculum/([A-Za-z0-9]+)/ajaxStudentSchedule', html)
    if not match:
        # 尝试找 schedulerURL 或类似的 JS 变量
        match = re.search(r'ajaxStudentSchedule.*?curr.*?callback', html)
        if not match:
            return _empty_result()
        # 从页面中提取完整 URL
        url_match = re.search(
            r'/student/courseSelect/thisSemesterCurriculum/([A-Za-z0-9]+)/ajaxStudentSchedule/curr/callback',
            html
        )
        if not url_match:
            return _empty_result()
        dynamic_id = url_match.group(1)
    else:
        dynamic_id = match.group(1)

    # Step 3: 调用 AJAX 接口获取课表 JSON
    ajax_url = f"/student/courseSelect/thisSemesterCurriculum/{dynamic_id}/ajaxStudentSchedule/curr/callback"
    resp = client.get(ajax_url)

    if resp.status_code != 200:
        return _empty_result()

    # Step 4: 解析 JSON 数据
    result = parse_urp_schedule_json(resp.text)
    courses = result.get("courses", [])
    schedules = result.get("schedules", [])

    # Step 5: 构建学期信息（从页面提取）
    semester = _parse_semester_from_page(html)

    return {
        "semester": semester,
        "courses": courses,
        "schedules": schedules,
    }


def _parse_semester_from_page(html: str) -> Dict[str, Any]:
    """从课表页面提取学期信息"""
    semester = {
        "id": "2025-2026-2",
        "name": "2025-2026学年第二学期",
        "start_date": "2026-02-23",
        "end_date": "2026-07-05",
        "total_weeks": 20,
        "is_current": True,
    }

    # 尝试从页面提取学期标题
    match = re.search(r'title_dy\s*=\s*"([^"]+)"', html)
    if match:
        title = match.group(1)
        # "2025-2026学年春季学期学生课表" → 用于提取学期
        year_match = re.search(r'(\d{4}-\d{4})', title)
        if year_match:
            semester["id"] = year_match.group(1) + "-2" if "春" in title else year_match.group(1) + "-1"
            season = "第二学期" if "春" in title else "第一学期"
            semester["name"] = f"{year_match.group(1)}学年{season}"

    # 学号等信息
    sub_match = re.search(r'subtitle_dy\s*=\s*"([^"]+)"', html)
    if sub_match:
        info = sub_match.group(1)
        id_match = re.search(r'学号[：:]\s*(\d+)', info)
        if id_match:
            semester["_student_id"] = id_match.group(1)

    return semester


def _empty_result() -> Dict[str, Any]:
    return {"semester": None, "courses": [], "schedules": []}
