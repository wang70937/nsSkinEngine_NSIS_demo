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
!define PRODUCT_VERSION "2016.01.11.000"
!define MAIN_APP_NAME "GoogleTranslate.exe"
!define PRODUCT_NAME "Google Translate"
!define PRODUCT_NAME_EN "Google Translate"
!define PRODUCT_PUBLISHER "aceui"
!define PRODUCT_WEB_SITE "http://www.aceui.cn"
!define PRODUCT_2345WEB_SITE "http://www.2345.com/?k652511569"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\${MAIN_APP_NAME}"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_AUTORUN_KEY "Software\Microsoft\Windows\CurrentVersion\Run"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define MUI_ICON "resouce\115Browser\app.ico"
!define MUI_UNICON "resouce\115Browser\app.ico"
!define UNINSTALL_DIR "$TEMP\ACEUI\aceuiStep"
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
Name "${PRODUCT_NAME}"
OutFile "output\115Browser.exe"
InstallDir "$PROGRAMFILES\Google Translate"
InstallDirRegKey HKLM "${PRODUCT_UNINST_KEY}" "UninstallString"
;Request application privileges for Windows Vista
RequestExecutionLevel admin
;文件版本声明-开始
VIProductVersion ${PRODUCT_VERSION}
VIAddVersionKey /LANG=2052 "ProductName" "Google Translate"
VIAddVersionKey /LANG=2052 "Comments" "Google Translate"
VIAddVersionKey /LANG=2052 "CompanyName" "Aceui"
VIAddVersionKey /LANG=2052 "LegalTrademarks" "Google Translate"
VIAddVersionKey /LANG=2052 "LegalCopyright" "Google Translate."
VIAddVersionKey /LANG=2052 "FileDescription" "Google Translate install"
VIAddVersionKey /LANG=2052 "FileVersion" ${PRODUCT_VERSION}
;文件版本声明-结束

; 引入的头文件
!include "MUI.nsh"
!include "FileFunc.nsh"
!include "StdUtils.nsh"
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
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "ACEUIInstall") i .r1 ?e'
  Pop $R0
  StrCmp $R0 0 +3
    MessageBox MB_OK|MB_ICONEXCLAMATION "有一个 Google Translate 安装向导已经运行！"
    Abort

  KillProcDLL::KillProc "${MAIN_APP_NAME}"     ;强制结束进程

  SetOutPath "${UNINSTALL_DIR}"
  File /r /x *.db ".\resouce\115Browser\*.*"
  ;初始化数据  安装目录
 
  ReadRegStr $installPath HKLM "SOFTWARE\aceui\115browser" "installDir"
  ${If} $installPath == ""
    ;初始化安装位置 $APPDATA
    StrCpy $installPath "$PROGRAMFILES\Google Translate"
  ${EndIf}
FunctionEnd

Function InstallProgress
   nsSkinEngine::NSISInitSkinEngine /NOUNLOAD "${UNINSTALL_DIR}" "InstallPackages.xml" "WizardTab" "false" "115浏览器" "3546da8ed962e968ee8624549cbcae89" "app.ico" "true"
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
   
	;展开自定义选项
   nsSkinEngine::NSISFindControl "CustomOptionsCheckBox"
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have CustomOptionsCheckBox"
   ${Else}
    GetFunctionAddress $0 OnCheckChanged    
        nsSkinEngine::NSISOnControlBindNSISScript "CustomOptionsCheckBox"  $0
   ${EndIf}
   
   ;是否同意
   nsSkinEngine::NSISFindControl "acceptCheckBox"
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have acceptCheckBox"
   ${Else}
    GetFunctionAddress $0 acceptCheckChangedFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "acceptCheckBox"  $0
   ${EndIf}
   
   ;使用协议
   nsSkinEngine::NSISFindControl "acceptBtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have acceptBtn button"
   ${Else}
    GetFunctionAddress $0 acceptPageFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "acceptBtn"  $0
   ${EndIf}
   
   ;使用协议确定
   nsSkinEngine::NSISFindControl "okAcceptBtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have okAcceptBtn button"
   ${Else}
    GetFunctionAddress $0 acceptOkFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "okAcceptBtn"  $0
   ${EndIf}
   
   ;开始安装按钮绑定函数
   nsSkinEngine::NSISFindControl "InstallBtn"
   Pop $0
   ${If} $0 == "-1"
    MessageBox MB_OK "Do not have InstallBtn button"
   ${Else}
    GetFunctionAddress $0 InstallPageFunc    
        nsSkinEngine::NSISOnControlBindNSISScript "InstallBtn"  $0
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
   nsSkinEngine::NSISSetControlData "pop_ad_browser"  "http://www.aceui.cn"  "Navigate"
   ;--------------------------------------窗体显示-----------------------------------
   Call OnCheckChanged
   nsSkinEngine::NSISSetControlData "defaultAppCheckBox"  "true"  "Checked"
   nsSkinEngine::NSISSetControlData "acceptCheckBox"  "true"  "Checked"
   nsSkinEngine::NSISSetControlData "deskShortCheckBox"  "true"  "Checked"
   nsSkinEngine::NSISSetControlData "2345CheckBox"  "true"  "Checked"
   nsSkinEngine::NSISSetControlData "autoCheckBox"  "true"  "Checked"
   nsSkinEngine::NSISSetControlData "userFuckCheckBox"  "true"  "Checked"
   nsSkinEngine::NSISRunSkinEngine
FunctionEnd

Function OnNextBtnFunc
   nsSkinEngine::NSISNextTab "WizardTab"
FunctionEnd

Function OnInstallCancelFunc
    nsSkinEngine::NSISExitSkinEngine
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

Function OnCheckChanged
    nsSkinEngine::NSISGetControlData "CustomOptionsCheckBox" "Checked" ;
    Pop $0
    ${If} $0 == "1"
	nsSkinEngine::NSISResize "445" "608"
	nsSkinEngine::NSISSetControlData "customVer"  "true"  "visible"
	${Else}
	nsSkinEngine::NSISResize "445" "462"
	nsSkinEngine::NSISSetControlData "customVer"  "false"  "visible"
	${EndIf}
FunctionEnd

Function acceptCheckChangedFunc
	nsSkinEngine::NSISGetControlData "acceptCheckBox" "Checked" ;
    Pop $0
    ${If} $0 == "1"
		nsSkinEngine::NSISSetControlData "InstallBtn"  "true"  "enable"
	${Else}
		nsSkinEngine::NSISSetControlData "InstallBtn"  "false"  "enable"
    ${EndIf}
FunctionEnd

Function acceptPageFunc
	nsSkinEngine::NSISSetControlData "windowbk"  "1"  "TabCurrentIndexInt"
	nsSkinEngine::NSISShowLicense "acceptInfo" "license.txt"
FunctionEnd

Function acceptOkFunc
	nsSkinEngine::NSISSetControlData "windowbk"  "0"  "TabCurrentIndexInt"
FunctionEnd

Function InstallPageFunc
    nsSkinEngine::NSISSetControlData "InstallTab_sysCloseBtn"  "false"  "enable"
	nsSkinEngine::NSISResize "445" "462"
	nsSkinEngine::NSISSetControlData "customVer"  "false"  "visible"
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
	 nsSkinEngine::NSISBindingDetail "progressDetail"
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
    CreateDirectory "$SMPROGRAMS\Google Translate"
    CreateShortCut "$SMPROGRAMS\Google Translate\${PRODUCT_NAME}.lnk" "$INSTDIR\${MAIN_APP_NAME}"
    CreateShortCut "$SMPROGRAMS\Google Translate\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
    CreateShortCut "$SMPROGRAMS\Google Translate\Uninstall.lnk" "$INSTDIR\uninst.exe"
    SetOverwrite ifnewer
	nsSkinEngine::NSISGetControlData "deskShortCheckBox" "Checked" ;
    Pop $0
    ${If} $0 == "1"
      ;创建桌面快捷方式
		CreateShortCut "$DESKTOP\${PRODUCT_NAME}.lnk" "$INSTDIR\${MAIN_APP_NAME}"
    ${EndIf}
    
    ${StdUtils.InvokeShellVerb} $0 "$INSTDIR" "${MAIN_APP_NAME}" ${StdUtils.Const.ShellVerb.PinToTaskbar}
    Call RefreshShellIcons
SectionEnd

Section Finish
	nsSkinEngine::NSISSetControlData "InstallTab_sysCloseBtn"  "true"  "enable"
	nsSkinEngine::NSISGetControlData "2345CheckBox" "Checked" ;
    Pop $0
    ${If} $0 == "1"
      ;设置浏览器首页
		WriteRegStr HKCU "Software\Microsoft\Internet Explorer\Main" "Start Page" "${PRODUCT_2345WEB_SITE}"
    ${EndIf}
SectionEnd

Function OnCompleteBtnFunc
    nsSkinEngine::NSISHideSkinEngine
    nsSkinEngine::NSISStopAnimationBkControl
    nsSkinEngine::NSISGetControlData "autoCheckBox" "Checked" ;
    Pop $0
    ${If} $0 == "1"
      WriteRegStr HKCU "${PRODUCT_AUTORUN_KEY}" "${PRODUCT_NAME}" "$INSTDIR\${MAIN_APP_NAME} -mini"
    ${EndIf}
	
    Exec '"$INSTDIR\${MAIN_APP_NAME}"'
    nsSkinEngine::NSISExitSkinEngine "false"
FunctionEnd


Function un.accept
  ;nsSkinEngine::NSISSendMessage $Dialog WM_NSISOPENURL "http://www.aceui.cn/";
FunctionEnd
;-----------------------------------------------------------------------------------------------------------------------------

Function un.onInit
  ;创建互斥防止重复运行
  System::Call 'kernel32::CreateMutexA(i 0, i 0, t "aceuiUnInstall") i .r1 ?e'
  Pop $R0
  StrCmp $R0 0 +3
    MessageBox MB_OK|MB_ICONEXCLAMATION "有一个 115浏览器 卸载向导已经运行！"
    Abort

  SetOutPath "${UNINSTALL_DIR}"
  File /r /x *.db ".\resouce\115Browser\*.*"
  
  KillProcDLL::KillProc "${MAIN_APP_NAME}"     ;强制结束进程
FunctionEnd

Function un.UninstallProgress
    nsSkinEngine::NSISInitSkinEngine /NOUNLOAD "${UNINSTALL_DIR}" "UninstallPackages.xml" "WizardTab" "false" "115浏览器" "3546da8ed962e968ee8624549cbcae89" "app.ico" "true"
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
   
   ;--------------------------------------窗体显示-----------------------------------
   nsSkinEngine::NSISRunSkinEngine
FunctionEnd

Function un.OnUnInstallCancelFunc
     nsSkinEngine::NSISExitSkinEngine
FunctionEnd

Function un.OnNextBtnFunc
   nsSkinEngine::NSISNextTab "WizardTab"
FunctionEnd

Function un.UnInstallPageFunc
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
    # 设置为所有用户
    SetShellVarContext all
	
    ${StdUtils.InvokeShellVerb} $0 "$INSTDIR" "${MAIN_APP_NAME}" ${StdUtils.Const.ShellVerb.UnpinFromTaskbar}
    Delete "$SMPROGRAMS\Google Translate\*.lnk"
    Delete "$SMPROGRAMS\Google Translate\Uninstall.lnk"
    Delete "$SMPROGRAMS\Google Translate\Website.lnk"
    Delete "$SMPROGRAMS\Google Translate\${PRODUCT_NAME}.lnk"
    Delete "$DESKTOP\${PRODUCT_NAME}.lnk"
    RMDir /r /REBOOTOK  "$SMPROGRAMS\Google Translate"
    RMDir /r /REBOOTOK  "$INSTDIR"
	
	DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
    DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
    DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Translate"
    DeleteRegValue HKCU "${PRODUCT_AUTORUN_KEY}" "${PRODUCT_NAME}"
    
SectionEnd

Function un.OnCompleteBtnFunc
    nsSkinEngine::NSISHideSkinEngine
    ;Call un.SendStatistics
    ;Call un.DeleteRegKey ;发送完统计再调用删除key,因为发送可能需要某些键值
    nsSkinEngine::NSISExitSkinEngine
FunctionEnd

;刷新关联图标
Function RefreshShellIcons
  System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v \
  (${SHCNE_ASSOCCHANGED}, ${SHCNF_IDLIST}, 0, 0)'
FunctionEnd

Function .onInstSuccess
FunctionEnd