/*
    Compile the script to use the Unicode version of NSIS
    The producers：surou
*/
;ExecShell taskbarunpin "$DESKTOP\${PRODUCT_NAME}.lnk"是删除任务栏图标

;安装包 解压空白
!system '>blank set/p=MSCF<nul'
!packhdr temp.dat 'cmd /c Copy /b temp.dat /b +blank&&del blank'

;定义变量
Var Dialog
Var MessageBoxHandle
Var installPath
Var FreeSpaceSize

; 安装程序初始定义常量
!define PRODUCT_VERSION "2016.02.16.000"
!define MAIN_APP_NAME "wpsmail.exe"
!define PRODUCT_NAME "WPS Mail"
!define PRODUCT_NAME_EN "WPS Mail"
!define PRODUCT_PUBLISHER "Kingsoft Corporation"
!define PRODUCT_WEB_SITE "http://www.wps.cn"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\${MAIN_APP_NAME}"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_AUTORUN_KEY "Software\Microsoft\Windows\CurrentVersion\Run"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define MUI_ICON "resouce\WPS_Mail\nsis_res\mui_icon.ico"
!define MUI_UNICON "resouce\WPS_Mail\nsis_res_uninst\mui_unicon.ico"
!define UNINSTALL_DIR "$TEMP\ACEUI\BoltStep"
;刷新关联图标
!define SHCNE_ASSOCCHANGED 0x08000000
!define SHCNF_IDLIST 0
; 安装不需要重启
!define MUI_FINISHPAGE_NOREBOOTSUPPORT
; 设置文件覆盖标记
SetOverwrite on
; 设置压缩选项
SetCompress auto
; 选择压缩方式
SetCompressor /SOLID lzma
SetCompressorDictSize 32
; 设置数据块优化
SetDatablockOptimize on
; 设置在数据中写入文件时间
SetDateSave on
;设置Unicode 编码 3.0以上版本支持
Unicode false
; 是否允许安装在根目录下
AllowRootDirInstall false
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "output\WpsMailSetup.exe"
InstallDir "$PROGRAMFILES\WPS Mail"
InstallDirRegKey HKLM "${PRODUCT_UNINST_KEY}" "UninstallString"
;Request application privileges for Windows Vista
RequestExecutionLevel admin
;文件版本声明-开始
VIProductVersion ${PRODUCT_VERSION}
VIAddVersionKey /LANG=2052 "ProductName" "WPS Mail"
VIAddVersionKey /LANG=2052 "Comments" "Kingsoft Bolt Mail Client"
VIAddVersionKey /LANG=2052 "CompanyName" "Kingsoft Corporation"
VIAddVersionKey /LANG=2052 "LegalTrademarks" "Bolt is a Trademark of Kingsoft"
VIAddVersionKey /LANG=2052 "LegalCopyright" "Kingsoft and Mozilla Developers, according to the MPL 1.1/GPL 2.0/LGPL 2.1 licenses, as applicable."
VIAddVersionKey /LANG=2052 "FileDescription" "WPS Mail install"
VIAddVersionKey /LANG=2052 "FileVersion" ${PRODUCT_VERSION}
;文件版本声明-结束

; 引入的头文件
!include  "MUI.nsh"
!include "FileFunc.nsh"
; 引入的dll
ReserveFile "${NSISDIR}\Plugins\x86-unicode\nsSkinEngine.dll"
;Languages 
!insertmacro MUI_LANGUAGE "SimpChinese"
;初始化数据

; 安装和卸载页面
Page         custom     InstallProgress
Page         instfiles  "" InstallShow
UninstPage   custom     un.UninstallProgress
UninstPage   instfiles	""	un.UninstallNow
Function .onInit
 ;创建互斥防止重复运行
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "BoltInstall") i .r1 ?e'
  Pop $R0
  StrCmp $R0 0 +3
    MessageBox MB_OK|MB_ICONEXCLAMATION "有一个 WPS Mail 安装向导已经运行！"
    Abort

  KillProcDLL::KillProc "${MAIN_APP_NAME}"     ;强制结束进程

  SetOutPath "${UNINSTALL_DIR}"
  File /r /x *.db ".\resouce\WPS_Mail\nsis_res\*.*"
  ;初始化数据  安装目录
 
  ReadRegStr $installPath HKLM "SOFTWARE\kingsoft\WpsMail" "installDir"
  ${If} $installPath == ""
    ;初始化安装位置 $APPDATA
    StrCpy $installPath "$PROGRAMFILES\WPS Mail"
  ${EndIf}
FunctionEnd

Function InstallProgress
   nsSkinEngine::NSISInitSkinEngine /NOUNLOAD "${UNINSTALL_DIR}" "InstallPackages.xml" "WizardTab" "true" "WPS邮箱" "c9febcaa5f1519ab06c5f67878499e29" "mui_icon.ico" "true"
   Pop $Dialog
   ;初始化MessageBox窗口
   nsSkinEngine::NSISInitMessageBox "MessageBox.xml" "TitleLab" "TextLab" "CloseBtn" "YESBtn" "NOBtn"
   Pop $MessageBoxHandle
   
   ;关闭按钮绑定函数
   nsSkinEngine::NSISFindControl "InstallTab_sysCloseBtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have InstallTab_sysCloseBtn"
   ${Else}
    GetFunctionAddress $0 OnInstallCancelFunc
    nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_sysCloseBtn" $0
   ${EndIf}

   ;-------------------------欢迎界面----------------------
   ;下一步按钮绑定函数
   nsSkinEngine::NSISFindControl "WelcomeTab_NextBtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have WelcomeTab_NextBtn button"
   ${Else}
    GetFunctionAddress $0 OnNextBtnFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "WelcomeTab_NextBtn"  $0
   ${EndIf}
   
   ;------------------------安装界面-----------------------

    ;安装路径编辑框设定数据
   nsSkinEngine::NSISFindControl "InstallTab_InstallFilePath"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have InstallTab_InstallFilePath"
   ${Else}
   
    GetFunctionAddress $0 OnTextChangeFunc
    nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_InstallFilePath" $0
    nsSkinEngine::NSISSetControlData "InstallTab_InstallFilePath" $installPath "text"
    Call OnTextChangeFunc
   ${EndIf}

   ;安装路径浏览按钮绑定函数
   nsSkinEngine::NSISFindControl "InstallTab_SelectFilePathBtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have InstallTab_SelectFilePathBtn button"
   ${Else}
    GetFunctionAddress $0 OnInstallPathBrownBtnFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_SelectFilePathBtn"  $0
   ${EndIf}

   ;开始安装按钮绑定函数
   nsSkinEngine::NSISFindControl "InstallTab_InstallBtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have InstallTab_InstallBtn button"
   ${Else}
    GetFunctionAddress $0 InstallPageFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "InstallTab_InstallBtn"  $0
   ${EndIf}
   ;--------------------------------------完成页面----------------------------------
   nsSkinEngine::NSISFindControl "CompleteTab_CompleteBtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have CompleteTab_CompleteBtn button"
   ${Else}
    GetFunctionAddress $0 OnCompleteBtnFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "CompleteTab_CompleteBtn"  $0
   ${EndIf}
   ;--------------------------------------窗体显示-----------------------------------
   GetFunctionAddress $0 goAheadCallback
   GetFunctionAddress $1 retreatCallback
   nsSkinEngine::NSISInitAnimationBkControl "windowbk" "${UNINSTALL_DIR}\step" "145" "90" "1" "68" $0 $1
   nsSkinEngine::NSISStartAnimationBkControl "0" "33"
   nsSkinEngine::NSISSetControlData "welcomeText"  "false"  "visible"
   nsSkinEngine::NSISRunSkinEngine
FunctionEnd

Function goAheadCallback
    nsSkinEngine::NSISSetControlData "welcomeText"  "true"  "visible"
FunctionEnd

Function retreatCallback
    nsSkinEngine::NSISSetControlData "WelcomeTab_NextBtn"  "false"  "visible"
    nsSkinEngine::NSISSetControlData "welcomeText"  "false"  "visible"
FunctionEnd

Function OnBackBtnFunc
   nsSkinEngine::NSISBackTab "WizardTab"
FunctionEnd

Function OnNextBtnFunc
   nsSkinEngine::NSISNextTab "WizardTab"
   Call goAheadCallback
   nsSkinEngine::NSISStartAnimationBkControl "90" "33"
FunctionEnd

Function OnInstallCancelFunc
   nsSkinEngine::NSISMessageBox "" " 确定要退出WPS邮件的安装？"
   ;nsSkinEngine::NSISSendMessage $Dialog WM_NSISCANCEL "Wps Mail安装" "确定要退出Wps Mail安装？"
   Pop $0
    ${If} $0 == "1"
     nsSkinEngine::NSISExitSkinEngine "true"
   ${EndIf} 
FunctionEnd

Function UpdateFreeSpace
  ${GetRoot} $INSTDIR $0
  StrCpy $1 "Bytes"

  System::Call kernel32::GetDiskFreeSpaceEx(tr0,*l,*l,*l.r0)
   ${If} $0 > 1024
   ${OrIf} $0 < 0
      System::Int64Op $0 / 1024
      Pop $0
      StrCpy $1 "KB"
      ${If} $0 > 1024
      ${OrIf} $0 < 0
     System::Int64Op $0 / 1024
     Pop $0
     StrCpy $1 "MB"
     ${If} $0 > 1024
     ${OrIf} $0 < 0
        System::Int64Op $0 / 1024
        Pop $0
        StrCpy $1 "GB"
     ${EndIf}
      ${EndIf}
   ${EndIf}

   StrCpy $FreeSpaceSize  "$0$1"
FunctionEnd

Function FreshInstallDataStatusFunc
    ;更新磁盘空间文本显示
   nsSkinEngine::NSISFindControl "InstallTab_FreeSpace"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have InstallTab_FreeSpace"
   ${Else}
    nsSkinEngine::NSISSetControlData "InstallTab_FreeSpace"  $FreeSpaceSize  "text"
   ${EndIf}
   ;路径是否合法（合法则不为0Bytes）
   ${If} $FreeSpaceSize == "0Bytes"
    nsSkinEngine::NSISSetControlData "InstallTab_InstallBtn" "false" "enable"
   ${Else}
    nsSkinEngine::NSISSetControlData "InstallTab_InstallBtn" "true" "enable"
   ${EndIf}
FunctionEnd

Function OnTextChangeFunc
   ; 改变可用磁盘空间大小
   nsSkinEngine::NSISGetControlData InstallTab_InstallFilePath "text"
   Pop $0
   ;MessageBox MB_OK $0
   StrCpy $INSTDIR $0

   ;重新获取磁盘空间
   Call UpdateFreeSpace
   Call FreshInstallDataStatusFunc
FunctionEnd

Function OnInstallPathBrownBtnFunc
   nsSkinEngine::NSISGetControlData "InstallTab_InstallFilePath" "text" ;
   Pop $installPath
   nsSkinEngine::NSISSelectFolderDialog "请选择文件夹" $installPath
   Pop $installPath

   StrCpy $0 $installPath
   ${If} $0 == "-1"
   ${Else}
      StrCpy $INSTDIR "$installPath\${PRODUCT_NAME_EN}"
      ;设置安装路径编辑框文本
      nsSkinEngine::NSISFindControl "InstallTab_InstallFilePath"
      Pop $0
      ${If} $0 == "-1"
     MessageBox MB_OK "Do not have Wizard_InstallPathBtn4Page2 button"
      ${Else}
     ;nsSkinEngine::SetText2Control "InstallTab_InstallFilePath"  $installPath
     StrCpy $installPath $INSTDIR
     nsSkinEngine::NSISSetControlData "InstallTab_InstallFilePath"  $installPath  "text"
      ${EndIf}
   ${EndIf}

   ;重新获取磁盘空间
   Call UpdateFreeSpace
   Call FreshInstallDataStatusFunc
FunctionEnd

Function InstallPageFunc
    nsSkinEngine::NSISSetControlData "InstallTab_sysCloseBtn"  "false"  "enable"
    ;设置进度条
    nsSkinEngine::NSISSetControlData "CompleteTab_RunAppCheckBox"  "true" "Checked" ;默认勾选运行程序
    nsSkinEngine::NSISFindControl "InstallProgressBar"
      Pop $0
      ${If} $0 == "-1"
     MessageBox MB_OK "Do not have InstallProgressBar"
      ${Else}
     nsSkinEngine::NSISSetControlData "InstallProgressBar"  "0"  "ProgressInt"
     nsSkinEngine::NSISSetControlData "progressText"  "0%"  "text"
     nsSkinEngine::NSISStartInstall
     ${EndIf} 
FunctionEnd

Function InstallShow
     nsSkinEngine::NSISFindControl "InstallProgressBar"
      Pop $0
      ${If} $0 == "-1"
     MessageBox MB_OK "Do not have InstallProgressBar"
      ${Else}
     nsSkinEngine::NSISBindingProgress "InstallProgressBar" "progressText"
	 ${EndIf}
FunctionEnd

Section InstallFiles
  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer
  File /r "bin\*.*"
SectionEnd

Section RegistKeys
    WriteUninstaller "$INSTDIR\uninst.exe"
    WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\${MAIN_APP_NAME}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\${MAIN_APP_NAME},0"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
    WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd

Section CreateShorts
    WriteIniStr "$INSTDIR\${PRODUCT_NAME}.url" "InternetShortcut" "URL" "${PRODUCT_WEB_SITE}"
    SetShellVarContext all
    ;创建开始菜单快捷方式
    CreateDirectory "$SMPROGRAMS\WPS Mail"
    CreateShortCut "$SMPROGRAMS\WPS Mail\${PRODUCT_NAME}.lnk" "$INSTDIR\${MAIN_APP_NAME}"
    CreateShortCut "$SMPROGRAMS\WPS Mail\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
    CreateShortCut "$SMPROGRAMS\WPS Mail\Uninstall.lnk" "$INSTDIR\uninst.exe"
    SetOverwrite ifnewer
    ;创建桌面快捷方式
    CreateShortCut "$DESKTOP\${PRODUCT_NAME}.lnk" "$INSTDIR\${MAIN_APP_NAME}"
/* 	CreateShortCut "$QUICKLAUNCH\${PRODUCT_NAME}.lnk" "$INSTDIR\${MAIN_APP_NAME}"
	System::Call 'shell32.dll::ShellExecute(i 0, t "taskbarpin", t "$QUICKLAUNCH\${PRODUCT_NAME}.lnk", i 0, i 0, i 0)  i .r1 ?e' */
    Call RefreshShellIcons
SectionEnd

Section Finish
SectionEnd

Function OnCompleteBtnFunc
    nsSkinEngine::NSISHideSkinEngine
    nsSkinEngine::NSISStopAnimationBkControl
    nsSkinEngine::NSISGetControlData "CompleteTab_AutoRunCheckBox" "Checked" ;
    Pop $0
    ${If} $0 == "1"
      WriteRegStr HKCU "${PRODUCT_AUTORUN_KEY}" "${PRODUCT_NAME}" "$INSTDIR\${MAIN_APP_NAME} -mini"
    ${EndIf}

    nsSkinEngine::NSISGetControlData "CompleteTab_RunAppCheckBox" "Checked" ;
    Pop $0
   ${If} $0 == "1"
     Exec '"$INSTDIR\${MAIN_APP_NAME}"'
   ${EndIf}
    nsSkinEngine::NSISExitSkinEngine "false"
FunctionEnd

;-----------------------------------------------------------------------------------------------------------------------------

Function un.onInit
  ;创建互斥防止重复运行
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "BoltUnInstall") i .r1 ?e'
  Pop $R0
  StrCmp $R0 0 +3
    MessageBox MB_OK|MB_ICONEXCLAMATION "有一个 WPS Mail 安装向导已经运行！"
    Abort

  SetOutPath "${UNINSTALL_DIR}"
  File /r /x *.db ".\resouce\WPS_Mail\nsis_res_uninst\*.*"
  
  KillProcDLL::KillProc "${MAIN_APP_NAME}"     ;强制结束进程
FunctionEnd

Function un.UninstallProgress
    nsSkinEngine::NSISInitSkinEngine /NOUNLOAD "${UNINSTALL_DIR}" "UninstallPackages.xml" "WizardTab" "false" "WPS邮箱" "c9febcaa5f1519ab06c5f67878499e29" "${UNINSTALL_DIR}\mui_unicon.ico"
   Pop $Dialog
   ;初始化MessageBox窗口
   nsSkinEngine::NSISInitMessageBox "MessageBox.xml" "TitleLab" "TextLab" "CloseBtn" "YESBtn" "NOBtn"
   Pop $MessageBoxHandle
   
   ;关闭按钮绑定函数
   nsSkinEngine::NSISFindControl "sysCloseBtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have sysCloseBtn"
   ${Else}
    GetFunctionAddress $0 un.OnUnInstallCancelFunc
    nsSkinEngine::NSISOnControlBindNSISScript "sysCloseBtn" $0
   ${EndIf}
   
   ;取消按钮绑定函数
   nsSkinEngine::NSISFindControl "cancelUninstallBtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have cancelUninstallBtn"
   ${Else}
    GetFunctionAddress $0 un.OnUnInstallCancelFunc
    nsSkinEngine::NSISOnControlBindNSISScript "cancelUninstallBtn" $0
   ${EndIf}
   
   ;联系我们按钮 
   nsSkinEngine::NSISFindControl "contactbtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have contactbtn"
   ${Else}
    GetFunctionAddress $0 un.contactUs
    nsSkinEngine::NSISOnControlBindNSISScript "contactbtn" $0
   ${EndIf}
   
   ;残忍卸载 okUninstallBtn
   nsSkinEngine::NSISFindControl "okUninstallBtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have okUninstallBtn"
   ${Else}
    GetFunctionAddress $0 un.UnInstallPageFunc
    nsSkinEngine::NSISOnControlBindNSISScript "okUninstallBtn" $0
   ${EndIf}
   
   ;卸载完成 completeBtn
   nsSkinEngine::NSISFindControl "completeBtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have completeBtn"
   ${Else}
    GetFunctionAddress $0 un.OnCompleteBtnFunc
    nsSkinEngine::NSISOnControlBindNSISScript "completeBtn" $0
   ${EndIf}
   
   ;问题1
   nsSkinEngine::NSISFindControl "question1btn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have question1btn"
   ${Else}
    GetFunctionAddress $0 un.question1
    nsSkinEngine::NSISOnControlBindNSISScript "question1btn" $0
   ${EndIf}
   
   ;问题2
   nsSkinEngine::NSISFindControl "question2btn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have question2btn"
   ${Else}
    GetFunctionAddress $0 un.question2
    nsSkinEngine::NSISOnControlBindNSISScript "question2btn" $0
   ${EndIf}
   
   ;问题3
   nsSkinEngine::NSISFindControl "question3btn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have question3btn"
   ${Else}
    GetFunctionAddress $0 un.question3
    nsSkinEngine::NSISOnControlBindNSISScript "question3btn" $0
   ${EndIf}
   ;--------------------------------------窗体显示-----------------------------------
   nsSkinEngine::NSISSetControlData "SavaData_CheckBox"  "true"  "Checked"
   nsSkinEngine::NSISRunSkinEngine
FunctionEnd

Function un.OnUnInstallCancelFunc
   nsSkinEngine::NSISMessageBox "" " 确定要退出WPS邮件的卸载？"
   Pop $0
    ${If} $0 == "1"
     nsSkinEngine::NSISExitSkinEngine "false"
   ${EndIf} 
FunctionEnd

Function un.OnNextBtnFunc
   nsSkinEngine::NSISNextTab "WizardTab"
FunctionEnd

Function un.UnInstallPageFunc
    nsSkinEngine::NSISSetControlData "okUninstallBtn2"  "false"  "enable"
    nsSkinEngine::NSISSetControlData "cancelUninstallBtn2"  "false"  "enable"
	nsSkinEngine::NSISSetControlData "progressTip"  "正在删除WPS邮箱"  "text"
    nsSkinEngine::NSISStartUnInstall
FunctionEnd

Function un.UninstallNow
     nsSkinEngine::NSISFindControl "UnInstallProgressBar"
      Pop $0
      ${If} $0 == "-1"
     MessageBox MB_OK "Do not have UnInstallProgressBar"
      ${Else}
     nsSkinEngine::NSISBindingProgress "UnInstallProgressBar" "progressText"
	 ${EndIf}
FunctionEnd

Section "Uninstall"
    # 设置为当前用户
    SetShellVarContext current
    nsSkinEngine::NSISGetControlData "SavaData_CheckBox" "Checked" ;
    Pop $0
    ${If} $0 == "0"
     RMDir /r /REBOOTOK "$APPDATA\Kingsoft\Bolt"
    ${EndIf}
    # 设置为所有用户
    SetShellVarContext all
    ;删除任务栏快捷方式
    ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentVersion"
    ${if} $R0 >= 6.0  # Vista以上  锁定任务栏
        ExecShell taskbarunpin "$DESKTOP\${PRODUCT_NAME}.lnk"
    ${else}           # XP以下  快速任务栏
        IfFileExists "$QUICKLAUNCH\${PRODUCT_NAME}.lnk" 0 +2
            Delete "$QUICKLAUNCH\${PRODUCT_NAME}.lnk";
    ${Endif}

    Delete "$SMPROGRAMS\WPS Mail\*.lnk"
    Delete "$SMPROGRAMS\WPS Mail\Uninstall.lnk"
    Delete "$SMPROGRAMS\WPS Mail\Website.lnk"
    Delete "$SMPROGRAMS\WPS Mail\${PRODUCT_NAME}.lnk"
    Delete "$DESKTOP\${PRODUCT_NAME}.lnk"
    RMDir /r /REBOOTOK  "$SMPROGRAMS\WPS Mail"
    RMDir /r /REBOOTOK  "$INSTDIR"
	
	DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
    DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
    DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WPS Mail"
    DeleteRegKey HKLM "Software\Clients\Mail\WPS Mail"
    DeleteRegKey HKLM "Software\Clients\News\WPS Mail"
    DeleteRegKey HKLM "SOFTWARE\kingsoft\WpsMail"
    DeleteRegValue HKCU "${PRODUCT_AUTORUN_KEY}" "${PRODUCT_NAME}"
    
SectionEnd

Function un.OnCompleteBtnFunc
    nsSkinEngine::NSISHideSkinEngine
    ;Call un.SendStatistics
    ;Call un.DeleteRegKey ;发送完统计再调用删除key,因为发送可能需要某些键值
    nsSkinEngine::NSISExitSkinEngine "false"
FunctionEnd

;刷新关联图标
Function RefreshShellIcons
  System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v \
  (${SHCNE_ASSOCCHANGED}, ${SHCNF_IDLIST}, 0, 0)'
FunctionEnd

Function un.contactUs
  ;nsSkinEngine::NSISSendMessage $Dialog WM_NSISOPENURL "";
FunctionEnd

Function un.question1
  ;nsSkinEngine::NSISSendMessage $Dialog WM_NSISOPENURL "";
FunctionEnd

Function un.question2
  ;nsSkinEngine::NSISSendMessage $Dialog WM_NSISOPENURL "";
FunctionEnd

Function un.question3
  ;nsSkinEngine::NSISSendMessage $Dialog WM_NSISOPENURL "";
FunctionEnd

Function .onInstSuccess
FunctionEnd