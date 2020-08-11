Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# �J�����g�f�B���N�g�����擾
$path = Split-Path -Parent $MyInvocation.MyCommand.Path

# �E�B���h�E���\����
$cscode = @"
// Win32Api ��ǂݍ��ނ��߂� C# �R�[�h
[DllImport("user32.dll")]
[return: MarshalAs(UnmanagedType.Bool)]
// �E�B���h�E�̏�Ԃ𐧌䂷�邽�� ShowWindowAsync() �� extern ����
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@
$Win32Functions = Add-Type -MemberDefinition $cscode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$Win32Functions::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0) > $null # bool �l��Ԃ��̂� null �Ɏ̂Ă�

# �^�X�N�g���C�ɃA�C�R�����쐬����
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Visible = $true

# �_�[�N���[�h����
$theme = "light"
if ((Get-ItemProperty -Path "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize").AppsUseLightTheme -eq 0) {
    $theme = "dark"
}

# ���\�[�X�̓ǂ݂���
$cats = @(
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat0.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat1.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat2.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat3.ico";
    New-Object System.Drawing.Icon -ArgumentList "$path\\resources\\${theme}_cat4.ico"
)

# �^�X�N�g���C�A�C�R�������I�ɍ����ւ��邽�߁A�^�C�}�[�I�u�W�F�N�g���쐬����
$timer = New-Object Windows.Forms.Timer

$script:idx = 0 # �^�C�}�[�̃C�x���g�n���h��������ǂݎ���悤�� script �X�R�[�v�Ő錾
$timer.Add_Tick( {
        $timer.Stop()
  
        $notifyIcon.Icon = $cats[$script:idx++]
        if ($script:idx -eq 5) { $script:idx = 0 }

        $timer.Start()
    })
  
$timer.Interval = 100
$timer.Start()

# ���b�Z�[�W���[�v�ŗ��p���� ApplicationContext ���쐬����
$applicationContext = New-Object System.Windows.Forms.ApplicationContext
  
# �A�C�R���N���b�N���̃C�x���g�n���h��
$notifyIcon.add_Click( {
        # ���b�Z�[�W���[�v���I��
        $applicationContext.ExitThread() 
    })

# �A�C�R���������܂ŏI���Ȃ��悤�A���b�Z�[�W���[�v����
[System.Windows.Forms.Application]::Run($applicationContext)

$timer.Stop()

