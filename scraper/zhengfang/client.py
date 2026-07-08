"""HTTP 客户端：管理 Cookie Session 和请求头

适配系统: jws.qgxy.cn — Spring Security 新版教务系统
"""

import requests
from typing import Optional
from urllib.parse import urljoin


class ZhengfangClient:
    """教务系统 HTTP 客户端 (Spring Security 版本)"""

    BASE_URL = "https://jws.qgxy.cn"

    def __init__(self):
        self.base_url = self.BASE_URL
        self.session = requests.Session()

        # 禁用 SSL 验证（部分校内系统证书问题）
        self.session.verify = False

        # 模拟手机浏览器
        self.session.headers.update({
            "User-Agent": (
                "Mozilla/5.0 (Linux; Android 13; Pixel 6) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/120.0.0.0 Mobile Safari/537.36"
            ),
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "zh-CN,zh;q=0.9",
            "Accept-Encoding": "gzip, deflate",
            "Connection": "keep-alive",
            "Referer": "https://jws.qgxy.cn/index",
        })

        self.is_logged_in = False

    def get(self, path: str, **kwargs) -> requests.Response:
        """发送 GET 请求"""
        url = urljoin(self.base_url, path)
        kwargs.setdefault("timeout", 15)
        return self.session.get(url, **kwargs)

    def post(self, path: str, **kwargs) -> requests.Response:
        """发送 POST 请求"""
        url = urljoin(self.base_url, path)
        kwargs.setdefault("timeout", 15)
        return self.session.post(url, **kwargs)

    def get_captcha_image(self) -> Optional[bytes]:
        """
        获取验证码图片
        实际地址: /img/captcha.jpg (加随机参数防缓存)
        """
        import random
        try:
            # 加随机参数避免缓存
            resp = self.get(f"/img/captcha.jpg?{random.randint(1, 99999)}")
            if resp.status_code == 200 and len(resp.content) > 100:
                return resp.content
        except Exception:
            pass
        return None

    def close(self):
        """关闭 Session"""
        self.session.close()


# 禁用 SSL 警告
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
