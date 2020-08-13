Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

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
$path = Split-Path -Parent $MyInvocation.MyCommand.Path
$cats = @(
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat0.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat1.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat2.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat3.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat4.ico"
)

# CPU 負荷の取得が GUI プロセスをブロックしないよう、バックグラウンドジョブとして実行する
$job = Start-Job -ScriptBlock {
    Get-Counter -Counter "\Processor(_Total)\% Processor Time" -Continuous | ForEach-Object {
        $_.CounterSamples.CookedValue
    }
}

# CPU使用率を定期的に取得するため、タイマーオブジェクトを作成する
$cpuTimer = New-Object Windows.Forms.Timer

# タイマーのイベントハンドラからも書き込みたい変数を script スコープで宣言
$script:cpuUsage = 1

$cpuTimer.Add_Tick( {
        $cpuTimer.Stop()

        # バックグラウンドジョブから結果を取得する
        $script:cpuUsage = [double](Receive-Job $job)[0]

        $cpuTimer.Start()
    })

$cpuTimer.Interval = 3 * 1000
$cpuTimer.Start()

# タスクトレイアイコンを任意のタイミングで差し替えるため、タイマーオブジェクトを作成する
$animateTimer = New-Object Windows.Forms.Timer

# タイマーのイベントハンドラからも書き込みたい変数を script スコープで宣言
$script:idx = 0

$animateTimer.Add_Tick( {
        $animateTimer.Stop()
  
        # 次のコマを表示
        $notifyIcon.Icon = $cats[$script:idx++]
        if ($script:idx -eq 5) { $script:idx = 0 }

        # CPU 使用率をバックグラウンド処理結果から取得
        $notifyIcon.Text = $script:cpuUsage
        # ネコチャンの速さを変更
        $animateTimer.Interval = (200.0 / [System.Math]::Max(1.0, [System.Math]::Min(20.0, $script:cpuUsage / 5)))

        $animateTimer.Start()
    })
  
$animateTimer.Interval = 200
$animateTimer.Start()

# メッセージループで利用する ApplicationContext を作成する
$applicationContext = New-Object System.Windows.Forms.ApplicationContext
  
# アイコンクリック時のイベントハンドラ
$notifyIcon.add_Click( {
        # メッセージループを終了
        $applicationContext.ExitThread()
    })

# アイコンを押すまで終わらないよう、メッセージループを回す
[System.Windows.Forms.Application]::Run($applicationContext)

# 終了処理
$cpuTimer.Stop()
$animateTimer.Stop()
$notifyIcon.Visible = $false
