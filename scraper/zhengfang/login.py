"""教务系统登录模块

适配版本: Spring Security + MD5 密码加密
实际表单:
  - action: /j_spring_security_check
  - 学号字段: j_username
  - 密码字段: j_password (提交前 MD5 加密)
  - 验证码字段: j_captcha (4位数字/字母)
  - 隐藏字段: tokenValue (从登录页提取)
  - schoolCode: 100059
"""

import re
import base64
import hashlib
import uuid
from typing import Dict, Optional, Tuple
from bs4 import BeautifulSoup

from .client import ZhengfangClient


# 存储已登录的 session
_active_sessions: Dict[str, ZhengfangClient] = {}
# 待登录的客户端（获取验证码后暂存，保持同一 Session）
_pending_clients: Dict[str, ZhengfangClient] = {}
# 待登录的 tokenValue（与客户端一一对应）
_pending_tokens: Dict[str, str] = {}


def _generate_token() -> str:
    return uuid.uuid4().hex


def get_captcha() -> Tuple[str, str]:
    """
    获取验证码图片

    返回: (captcha_id, image_base64)
    """
    client = ZhengfangClient()

    # 访问登录页，获取 Cookie 和 tokenValue
    token_value = ""
    login_page_ok = False
    try:
        resp = client.get("/login")
        if resp.status_code == 200:
            login_page_ok = True
            soup = BeautifulSoup(resp.text, 'html.parser')
            token_input = soup.find('input', {'id': 'tokenValue'})
            if token_input:
                token_value = token_input.get('value', '')
        else:
            # 如果 /login 不可达，尝试根路径
            resp = client.get("/")
            if resp.status_code == 200:
                login_page_ok = True
    except Exception as e:
        raise Exception(f"无法访问教务系统登录页: {str(e)}")

    if not login_page_ok:
        raise Exception("教务系统登录页不可达，请检查网络或 jws.qgxy.cn 是否可访问")

    # 获取验证码图片
    captcha_bytes = client.get_captcha_image()

    # 暂存客户端 + tokenValue，后续登录时使用同一个 Session
    captcha_id = _generate_token()
    _pending_clients[captcha_id] = client
    # 把 tokenValue 也存起来，登录时不用再次访问 /login（会刷新 session 导致验证码失效）
    _pending_tokens[captcha_id] = token_value

    if captcha_bytes:
        image_base64 = base64.b64encode(captcha_bytes).decode('utf-8')
    else:
        raise Exception("验证码图片获取失败：教务系统返回空或无效的验证码图片，请稍后重试")

    return captcha_id, image_base64


def md5(text: str) -> str:
    """
    MD5 加密（与教务系统 JS 的 hex_md5 完全一致）

    教务系统用的是 Paul Johnston 的 JavaScript MD5 库，
    该库对每个字符取 Unicode 码的低 8 位 (charCode & 0xFF) 作为字节。
    对于纯 ASCII 密码（英文、数字、英文标点），等价于 UTF-8；
    对于中文标点（如 ，。！），需要用 & 0xFF 方式处理。
    """
    bytes_data = bytes([ord(c) & 0xFF for c in text])
    return hashlib.md5(bytes_data).hexdigest()


def login(student_id: str, password: str, captcha_id: str, captcha_code: str) -> Dict:
    """
    登录教务系统

    参数:
        student_id: 学号
        password: 明文密码（会进行 MD5 加密后提交）
        captcha_id: 获取验证码时返回的 ID
        captcha_code: 用户输入的验证码

    返回:
        {"success": bool, "token": str, "message": str, "user_info": dict}
    """
    # --- 1. 检查 captcha_id 是否有效 ---
    if captcha_id not in _pending_clients:
        return {
            "success": False, "token": "", "message": "验证码已过期，请刷新重试",
            "user_info": {}
        }

    client = _pending_clients.pop(captcha_id)
    # 使用获取验证码时保存的 tokenValue，避免再次访问 /login 刷新 session
    token_value = _pending_tokens.pop(captcha_id, "")

    try:
        # --- 2. 构造登录请求 ---
        # 密码需要 MD5 加密（和前端 JS 的 hex_md5 一致）
        encrypted_password = md5(password)

        login_data = {
            "j_username": student_id,
            "j_password": encrypted_password,
            "j_captcha": captcha_code,
            "tokenValue": token_value,
            "schoolCode": "100059",  # 华北理工大学轻工学院固定值
        }

        # --- 4. 提交登录（禁止自动重定向，我们需要判断302去向） ---
        resp = client.post("/j_spring_security_check", data=login_data, allow_redirects=False)

        # --- 5. 判断登录结果 ---
        # Spring Security: 成功→302到首页, 失败→302到/login?error=true

        login_success = False
        error_message = "登录失败，请检查学号、密码和验证码"

        if resp.status_code in (302, 301):
            location = resp.headers.get("Location", "")
            # 成功：重定向到 /index 或 / 等非登录页
            if "error" not in location.lower() and "login" not in location.lower():
                login_success = True
                # 跟着重定向完成登录
                try:
                    resp = client.get(location)
                except Exception:
                    pass
            elif "error" in location.lower():
                # 失败：/login?error=true
                # 跟着重定向获取错误详情
                try:
                    resp = client.get(location)
                    error_message = _extract_error(resp.text)
                except Exception:
                    pass
        else:
            # 非重定向（可能是200带错误信息）
            text = resp.text if hasattr(resp, 'text') else ''
            error_message = _extract_error(text)

        if not login_success:
            # 收集调试信息
            debug_info = f"HTTP {resp.status_code}"
            try:
                text = resp.text[:300] if hasattr(resp, 'text') else ''
                if 'title' in text:
                    import re
                    title_match = re.search(r'<title>([^<]+)</title>', text)
                    if title_match:
                        debug_info += f", 页面标题: {title_match.group(1)}"
            except Exception:
                pass
            client.close()
            return {
                "success": False, "token": "",
                "message": f"{error_message} [{debug_info}]",
                "user_info": {}
            }

        # --- 6. 登录成功 ---
        client.is_logged_in = True
        token = _generate_token()
        _active_sessions[token] = client

        # 尝试获取用户信息
        user_info = _fetch_user_info(client, student_id)

        return {
            "success": True,
            "token": token,
            "message": "登录成功",
            "user_info": user_info,
        }

    except Exception as e:
        client.close()
        return {
            "success": False, "token": "",
            "message": f"登录异常: {str(e)}",
            "user_info": {}
        }


def _extract_error(html: str) -> str:
    """从登录失败页面提取错误信息"""
    soup = BeautifulSoup(html, 'lxml')
    # 常见错误提示元素
    for selector in ['.error', '.alert', '.message', '.errormessage', '#error']:
        elem = soup.select_one(selector)
        if elem and elem.get_text(strip=True):
            return elem.get_text(strip=True)
    # 尝试正则匹配
    import re
    match = re.search(r'(验证码错误|密码错误|用户名不存在|用户名或密码错误|账号已锁定|系统维护)', html)
    if match:
        return match.group(1)
    return "登录失败，请重试"


def _fetch_user_info(client: ZhengfangClient, student_id: str) -> dict:
    """获取用户基本信息"""
    user_info = {"name": "", "student_id": student_id, "department": ""}
    try:
        # 尝试访问学生信息相关页面
        for path in ["/student/info", "/xsgrxx", "/student/profile", "/index"]:
            try:
                resp = client.get(path)
                if resp.status_code == 200 and len(resp.text) > 200:
                    text = resp.text
                    # 提取姓名
                    name_match = re.search(r'姓名[：:\s]*[\"\']?(\S{2,4})', text)
                    if name_match:
                        user_info["name"] = name_match.group(1)
                    # 提取院系
                    dept_match = re.search(r'(?:院系|学院|专业|部门)[：:\s]*[\"\']?(\S+)', text)
                    if dept_match:
                        user_info["department"] = dept_match.group(1)
                    if user_info["name"]:
                        break
            except Exception:
                continue
    except Exception:
        pass
    return user_info


def get_client_by_token(token: str) -> Optional[ZhengfangClient]:
    """通过 token 获取已登录的客户端"""
    return _active_sessions.get(token)


def logout(token: str):
    """登出"""
    client = _active_sessions.pop(token, None)
    if client:
        try:
            client.get("/logout")
        except Exception:
            pass
        client.close()
