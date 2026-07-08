"""
轻院课表 - 爬虫微服务 (FastAPI)

提供教务系统登录、课表拉取、空教室查询等接口

启动方式:
    uvicorn main:app --host 0.0.0.0 --port 8007 --reload
"""

from fastapi import FastAPI, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from typing import Optional
import os

from zhengfang.login import get_captcha, login, get_client_by_token, logout
from zhengfang.schedule import fetch_schedule
from zhengfang.classroom import fetch_free_classrooms

app = FastAPI(
    title="轻院课表 API",
    description="华北理工大学轻工学院教务系统爬虫接口",
    version="1.0.0",
)

# CORS 配置（允许 Flutter App 访问）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== 请求/响应模型 ====================

class LoginRequest(BaseModel):
    student_id: str
    password: str
    captcha_id: str
    captcha_code: str


class ClassroomRequest(BaseModel):
    token: str
    building: Optional[str] = None
    day_of_week: int = 1
    start_period: int = 1
    duration: int = 2


# ==================== API 接口 ====================

@app.get("/")
def root():
    return {"message": "轻院课表 API 运行中", "version": "1.0.0"}


@app.get("/test", response_class=HTMLResponse)
def test_page():
    """提供登录测试页面"""
    html_path = "d:/Code/QYclass/scraper/test_login.html"
    if os.path.exists(html_path):
        with open(html_path, "r", encoding="utf-8") as f:
            return f.read()
    return HTMLResponse(f"<h1>测试页面未找到: {html_path}</h1>", status_code=404)


@app.post("/api/v1/captcha")
def api_get_captcha():
    """获取验证码图片"""
    try:
        captcha_id, image_base64 = get_captcha()
        return {
            "captcha_id": captcha_id,
            "image_base64": image_base64,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取验证码失败: {str(e)}")


@app.post("/api/v1/login")
def api_login(req: LoginRequest):
    """登录教务系统"""
    try:
        result = login(
            student_id=req.student_id,
            password=req.password,
            captcha_id=req.captcha_id,
            captcha_code=req.captcha_code,
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"登录失败: {str(e)}")


@app.get("/api/v1/schedule")
def api_get_schedule(authorization: str = Header(...)):
    """获取课表（需要登录 token）"""
    token = authorization.replace("Bearer ", "").strip()
    client = get_client_by_token(token)

    if client is None:
        raise HTTPException(status_code=401, detail="未登录或 token 已过期，请重新登录")

    try:
        result = fetch_schedule(client)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取课表失败: {str(e)}")


@app.post("/api/v1/classrooms/free")
def api_get_free_classrooms(req: ClassroomRequest):
    """查询空教室"""
    client = get_client_by_token(req.token)

    if client is None:
        raise HTTPException(status_code=401, detail="未登录或 token 已过期，请重新登录")

    try:
        classrooms = fetch_free_classrooms(
            client=client,
            building=req.building,
            day_of_week=req.day_of_week,
            start_period=req.start_period,
            duration=req.duration,
        )
        return {"classrooms": classrooms}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"查询空教室失败: {str(e)}")


@app.get("/api/v1/buildings")
def api_get_buildings(authorization: str = Header(...)):
    """获取教学楼列表（丰润校区）"""
    token = authorization.replace("Bearer ", "").strip()
    client = get_client_by_token(token)
    if client is None:
        raise HTTPException(status_code=401, detail="未登录")
    # 直接使用实际教务系统的教学楼数据
    buildings = [
        {"id": "F101", "name": "第一教学楼"},
        {"id": "F102", "name": "第二教学楼"},
        {"id": "F103", "name": "第三教学楼"},
        {"id": "F104", "name": "第四教学楼"},
        {"id": "F105", "name": "第五教学楼"},
        {"id": "F106", "name": "实验楼"},
        {"id": "F106(新)", "name": "第六教学楼（新）"},
        {"id": "F107", "name": "第七教学楼"},
        {"id": "体育教学", "name": "体育教学"},
        {"id": "青春讲堂", "name": "青春讲堂"},
        {"id": "艺术中心", "name": "艺术中心"},
        {"id": "玻璃教室", "name": "玻璃教室"},
    ]
    return {"buildings": buildings}


@app.post("/api/v1/logout")
def api_logout(authorization: str = Header(...)):
    """登出"""
    token = authorization.replace("Bearer ", "").strip()
    logout(token)
    return {"success": True, "message": "已登出"}


# ==================== 启动入口 ====================

@app.get("/api/v1/debug/explore")
def api_explore(authorization: str = Header(...)):
    """调试：探测登录后所有可访问的页面"""
    token = authorization.replace("Bearer ", "").strip()
    client = get_client_by_token(token)
    if client is None:
        raise HTTPException(status_code=401, detail="未登录")

    results = {}
    for path in ["/index", "/", "/student/index", "/home", "/main"]:
        try:
            r = client.get(path)
            if r.status_code == 200 and len(r.text) > 300:
                from bs4 import BeautifulSoup
                soup = BeautifulSoup(r.text, 'html.parser')
                links = []
                for a in soup.find_all('a'):
                    href = a.get('href', '')
                    text = a.get_text(strip=True)
                    if href and not href.startswith('#') and not href.startswith('javascript:'):
                        links.append({"text": text[:50], "href": href[:120]})
                results[path] = {
                    "status": r.status_code,
                    "title": soup.title.string if soup.title else "无标题",
                    "link_count": len(links),
                    "links": links[:50]
                }
                break
        except Exception as e:
            results[path] = {"error": str(e)}
    return results


@app.get("/api/v1/debug/page")
def api_debug_page(authorization: str = Header(...), path: str = "/index"):
    """调试：通过已登录session获取指定页面HTML"""
    token = authorization.replace("Bearer ", "").strip()
    client = get_client_by_token(token)
    if client is None:
        raise HTTPException(status_code=401, detail="未登录")
    try:
        r = client.get(path)
        return {"status": r.status_code, "size": len(r.text), "html": r.text[:50000]}
    except Exception as e:
        return {"error": str(e)}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
