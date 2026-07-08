"""空教室查询模块 — URP 综合教务系统

真实数据接口:
  POST /student/teachingResources/freeClassroom/today/{periods}
  参数: dayplus=0 (0=今天, 1=明天, -1=昨天)
  返回 JSON: {"spareroomObjList": [{"acmcBuildingName":"第二教学楼", "claroom":[{"classroom":"2303"},...]}]}

流程:
  1. POST /freeClassroom/today 设置教学楼上下文 (form: position=007_F102, xqm=第二教学楼)
  2. AJAX POST /freeClassroom/today/1,2 (dayplus=0) 获取教室数据
"""

import json
import re
from typing import Dict, List, Any, Optional
from .client import ZhengfangClient


BUILDING_MAP = {
    "F101": {"name": "第一教学楼", "campus": "007"},
    "F102": {"name": "第二教学楼", "campus": "007"},
    "F103": {"name": "第三教学楼", "campus": "007"},
    "F104": {"name": "第四教学楼", "campus": "007"},
    "F105": {"name": "第五教学楼", "campus": "007"},
    "F106": {"name": "实验楼", "campus": "007"},
    "F106(新)": {"name": "第六教学楼（新）", "campus": "007"},
    "F107": {"name": "第七教学楼", "campus": "007"},
    "体育教学": {"name": "体育教学", "campus": "007"},
    "青春讲堂": {"name": "青春讲堂", "campus": "007"},
    "艺术中心": {"name": "艺术中心", "campus": "007"},
    "玻璃教室": {"name": "玻璃教室", "campus": "007"},
}


def fetch_buildings(client: ZhengfangClient) -> List[Dict[str, Any]]:
    """获取教学楼列表"""
    return [{"id": k, "name": v["name"]} for k, v in BUILDING_MAP.items()]


def fetch_free_classrooms(
    client: ZhengfangClient,
    building: Optional[str] = None,
    day_of_week: int = 1,
    start_period: int = 1,
    duration: int = 2,
) -> List[Dict[str, Any]]:
    """
    查询空教室

    步骤:
      1. POST /freeClassroom/today 设置教学楼 (form提交)
      2. POST /freeClassroom/today/{periods} 获取数据 (AJAX JSON)

    参数:
        building: 教学楼代码 (如 "F102")，None=查全部
        day_of_week: 星期几 (转成 dayplus: 0=今天, 1=明天...)
        start_period: 起始节次
        duration: 持续节数
    """

    # 计算 dayplus (相对于今天)
    import datetime
    today_weekday = datetime.datetime.now().weekday()  # 0=周一
    dayplus = day_of_week - (today_weekday + 1)

    # 构造节次列表
    periods = ",".join(str(p) for p in range(start_period, start_period + duration))
    ajax_url = f"/student/teachingResources/freeClassroom/today/{periods}"

    classrooms = []

    # 确定查询哪些楼（先设置教学楼上下文）
    if building and building in BUILDING_MAP:
        targets = {building: BUILDING_MAP[building]}
    else:
        targets = BUILDING_MAP

    for bld_id, bld_info in targets.items():
        try:
            # Step 1: 设置教学楼上下文
            position = f"{bld_info['campus']}_{bld_id}"
            client.post(
                "/student/teachingResources/freeClassroom/today",
                data={"position": position, "xqm": bld_info["name"]},
                timeout=15
            )

            # Step 2: 获取教室数据
            resp = client.post(
                ajax_url,
                data={"dayplus": str(dayplus)},
                timeout=30
            )

            if resp.status_code == 200 and resp.text:
                # 强制 UTF-8 编码，防止 Brotli 或 GBK 乱码
                resp.encoding = 'utf-8'
                rooms = _parse_ajax_response(resp.text, bld_info["name"])
                classrooms.extend(rooms)

        except Exception as e:
            print(f"[DEBUG] {bld_id} error: {e}")
            continue

    return classrooms


def _parse_ajax_response(text: str, building_name: str) -> List[Dict[str, Any]]:
    """
    解析 AJAX JSON 响应

    格式:
    {"spareroomObjList": [
        {"acmcBuildingName":"第二教学楼",
         "claroom":[{"classroom":"2303"},{"classroom":"2405"},...]}
    ]}
    """
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return []

    classrooms = []
    room_list = data.get("spareroomObjList", [])

    for building_data in room_list:
        name = building_data.get("acmcBuildingName", building_name)
        for room in building_data.get("claroom", []):
            room_number = room.get("classroom", "")
            if room_number:
                classrooms.append({
                    "building": name,
                    "room_number": room_number,
                    "capacity": 0,
                })

    return classrooms
