# windows-nvm-installer

Easily to install [NVM](https://github.com/coreybutler/nvm-windows) on windows, automatically install [NRM](https://github.com/Pana/nrm), and setting up [Taobao](https://npm.taobao.org) registry.

Only support **windows 8, 8.1, 10**, and make sure **PowerShell is installed** .

> 一键安装 [NVM](https://github.com/coreybutler/nvm-windows) 脚本, 同时自动安装 [NRM](https://github.com/Pana/nrm) 和设置[淘宝源](https://npm.taobao.org), 只支持安装有 **PowerShell** 的 Windows 计算机.

## Usage

Open cmd.exe with administrator privileges **(UAC)** and execute the following command:

> 使用 **管理员权限 (UAC)** 运行 cmd 并执行以下指令:

```bash
PowerShell -Command "Invoke-Expression (Invoke-WebRequest 'https://raw.githubusercontent.com/ShirasawaSama/windows-nvm-installer/master/i.ps1').Content"
```

## Author

Shirasawa

## License

[MIT](./LICENSE)
