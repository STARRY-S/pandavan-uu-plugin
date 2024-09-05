# UU Plugin for Pandavan

适用于毛子 Pandavan 的 [网易 UU 加速器](https://uu.163.com/) 路由器插件安装脚本。

此项目的脚本基于网易 UU 官方 [install.sh](https://uu.gdl.netease.com/uuplugin-script/20231117102400/install.sh) 脚本（日期 `20231117`），增添了 Pandavan 系统支持。

有关此脚本的更多信息请访问网易 UU 路由器插件[官方文档](https://router.uu.163.com/app/html/online/baike_share.html?baike_id=5f963c9304c215e129ca40e8)。

## 使用方法

1. 拷贝本项目 [install.sh](install.sh) 安装脚本到路由器中。
1. 执行 `install.sh`，将在 `/etc/storage/uu` 目录下安装加速器插件，并自动配置路由器开机自启动。

    安装脚本日志可在 `/tmp/install.log` 获取。

## 说明

此项目的脚本仅在 *小米路由器 R3G*，Pandavan 系统版本 `3.4.3.9-099_24-06-1` 上进行测试。

**使用风险请自负！**

## LICENSE

MIT License

Copyright (c) 2024 STARRY-S

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
