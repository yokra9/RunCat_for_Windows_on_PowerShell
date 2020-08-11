Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# カレントディレクトリを取得
$path = Split-Path -Parent $MyInvocation.MyCommand.Path

# ウィンドウを非表示化
$cscode = @"
// Win32Api を読み込むための C# コード
[DllImport("user32.dll")]
[return: MarshalAs(UnmanagedType.Bool)]
// ウィンドウの状態を制御するため ShowWindowAsync() を extern する
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@
$Win32Functions = Add-Type -MemberDefinition $cscode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$Win32Functions::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0) > $null # bool 値を返すので null に捨てる

# タスクトレイにアイコンを作成する
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Visible = $true

# ダークモード判定
$theme = "light"
if ((Get-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize").AppsUseLightTheme -eq 0) {
    $theme = "dark"
}

# リソースの読みこみ
$cats = @(
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat0.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat1.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat2.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat3.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat4.ico"
)

# タスクトレイアイコンを定期的に差し替えるため、タイマーオブジェクトを作成する
$timer = New-Object Windows.Forms.Timer

$script:idx = 0 # タイマーのイベントハンドラからも読み取れるように script スコープで宣言
$timer.Add_Tick( {
        $timer.Stop()
  
        $notifyIcon.Icon = $cats[$script:idx++]
        if ($script:idx -eq 5) { $script:idx = 0 }

        $timer.Start()
    })
  
$timer.Interval = 100
$timer.Start()

# メッセージループで利用する ApplicationContext を作成する
$applicationContext = New-Object System.Windows.Forms.ApplicationContext
  
# アイコンクリック時のイベントハンドラ
$notifyIcon.add_Click( {
        # メッセージループを終了
        $applicationContext.ExitThread() 
    })

# アイコンを押すまで終わらないよう、メッセージループを回す
[System.Windows.Forms.Application]::Run($applicationContext)

$timer.Stop()

