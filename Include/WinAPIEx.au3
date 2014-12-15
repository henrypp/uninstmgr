Global Const $tagJOBOBJECT_BASIC_ACCOUNTING_INFORMATION = 'int64 TotalUserTime;int64 TotalKernelTime;int64 ThisPeriodTotalUserTime;int64 ThisPeriodTotalKernelTime;dword TotalPageFaultCount;dword TotalProcesses;dword ActiveProcesses;dword TotalTerminatedProcesses;'

Global Const $HKEY_CURRENT_USER = 0x80000001
Global Const $HKEY_LOCAL_MACHINE = 0x80000002

Global Const $KEY_READ = 0x20019
Global Const $KEY_WRITE = 0x20006
Global Const $KEY_ALL_ACCESS = 0xF003F

Global Const $RT_RCDATA = 10
Global Const $RT_MANIFEST = 24

Func _WinAPI_AssignProcessToJobObject($hJob, $hProcess)

	Local $Ret = DllCall('kernel32.dll', 'int', 'AssignProcessToJobObject', 'ptr', $hJob, 'ptr', $hProcess)

	If (@error) Or (Not $Ret[0]) Then
		Return SetError(1, 0, 0)
	EndIf
	Return $Ret[0]
EndFunc   ;==>_WinAPI_AssignProcessToJobObject

Func _WinAPI_CreateJobObject($sName = '', $tSecurity = 0)
	Local $TypeOfName = 'wstr'

	If Not StringStripWS($sName, 3) Then
		$TypeOfName = 'ptr'
		$sName = 0
	EndIf

	Local $Ret = DllCall('kernel32.dll', 'int', 'CreateJobObjectW', 'ptr', $tSecurity, $TypeOfName, $sName)

	If (@error) Or (Not $Ret[0]) Then
		Return SetError(1, 0, 0)
	EndIf
	Return $Ret[0]
EndFunc   ;==>_WinAPI_CreateJobObject

Func _WinAPI_DWordToInt($iValue)
	Local $tData = DllStructCreate('int')
	
	DllStructSetData($tData, 1, $iValue)
	
	Return DllStructGetData($tData, 1)
EndFunc   ;==>_WinAPI_DWordToInt

Func _WinAPI_ExtractIcon($sFile, $iIndex, $pLarge, $pSmall, $iIcons)
	Local $aResult = DllCall("shell32.dll", "uint", "ExtractIconExW", "wstr", $sFile, "int", $iIndex, "handle", $pLarge, "handle", $pSmall, "uint", $iIcons)
	If @error Then Return SetError(@error, @extended, 0)
	Return $aResult[0]
EndFunc   ;==>_WinAPI_ExtractIconEx

Func _WinAPI_FindResource($hInstance, $sName, $sType)

	Local $TypeOfName = 'ptr', $TypeOfType = 'ptr'

	If IsString($sName) Then
		$TypeOfName = 'wstr'
	EndIf
	If IsString($sType) Then
		$TypeOfType = 'wstr'
	EndIf

	Local $Ret = DllCall('kernel32.dll', 'ptr', 'FindResourceW', 'ptr', $hInstance, $TypeOfName, $sName, $TypeOfType, $sType)

	If (@error) Or (Not $Ret[0]) Then
		Return SetError(1, 0, 0)
	EndIf
	Return $Ret[0]
EndFunc   ;==>_WinAPI_FindResource

Func _WinAPI_FreeHandle($hObject)

	Local $Ret = DllCall('kernel32.dll', 'int', 'CloseHandle', 'ptr', $hObject)

	If (@error) Or ($Ret[0] = 0) Then
		Return SetError(1, 0, 0)
	EndIf
	Return 1
EndFunc   ;==>_WinAPI_FreeHandle

Func _WinAPI_FreeIcon($hIcon)

	Local $Ret = DllCall('user32.dll', 'int', 'DestroyIcon', 'ptr', $hIcon)

	If (@error) Or ($Ret[0] = 0) Then
		Return SetError(1, 0, 0)
	EndIf
	Return 1
EndFunc   ;==>_WinAPI_FreeIcon

Func _WinAPI_GetClassLong($hWnd, $iIndex)

	Local $Ret = DllCall('user32.dll', 'int', 'GetClassLong', 'hwnd', $hWnd, 'int', $iIndex)

	If (@error) Or ($Ret[0] = 0) Then
		Return SetError(1, 0, 0)
	EndIf
	Return $Ret[0]
EndFunc   ;==>_WinAPI_GetClassLong

Func _WinAPI_LoadResource($hInstance, $hResource)

	Local $Ret = DllCall('kernel32.dll', 'ptr', 'LoadResource', 'ptr', $hInstance, 'ptr', $hResource)

	If (@error) Or (Not $Ret[0]) Then
		Return SetError(1, 0, 0)
	EndIf
	Return $Ret[0]
EndFunc   ;==>_WinAPI_LoadResource

Func _WinAPI_LockResource($hData)

	Local $Ret = DllCall('kernel32.dll', 'ptr', 'LockResource', 'ptr', $hData)

	If (@error) Or (Not $Ret[0]) Then
		Return SetError(1, 0, 0)
	EndIf
	Return $Ret[0]
EndFunc   ;==>_WinAPI_LockResource

Func _WinAPI_RegCloseKey($hKey, $fFlush = 0)

	If $fFlush Then
		If Not _WinAPI_RegFlushKey($hKey) Then
			Return SetError(1, @extended, 0)
		EndIf
	EndIf

	Local $Ret = DllCall('advapi32.dll', 'long', 'RegCloseKey', 'ulong_ptr', $hKey)

	If @error Then
		Return SetError(1, 0, 0)
	Else
		If $Ret[0] Then
			Return SetError(1, $Ret[0], 0)
		EndIf
	EndIf
	Return 1
EndFunc   ;==>_WinAPI_RegCloseKey

Func _WinAPI_RegEnumKey($hKey, $iIndex)

	Local $tData = DllStructCreate('wchar[256]')
	Local $Ret = DllCall('advapi32.dll', 'long', 'RegEnumKeyExW', 'ulong_ptr', $hKey, 'dword', $iIndex, 'ptr', DllStructGetPtr($tData), 'dword*', 256, 'dword', 0, 'ptr', 0, 'ptr', 0, 'ptr', 0)

	If @error Then
		Return SetError(1, 0, '')
	Else
		If $Ret[0] Then
			Return SetError(1, $Ret[0], '')
		EndIf
	EndIf
	Return DllStructGetData($tData, 1)
EndFunc   ;==>_WinAPI_RegEnumKey

Func _WinAPI_RegOpenKey($hKey, $sSubKey = '', $iDesired = $KEY_READ)

	Local $Ret = DllCall('advapi32.dll', 'long', 'RegOpenKeyExW', 'ulong_ptr', $hKey, 'wstr', $sSubKey, 'dword', 0, 'dword', $iDesired, 'ulong_ptr*', 0)

	If @error Then
		Return SetError(1, 0, 0)
	Else
		If $Ret[0] Then
			Return SetError(1, $Ret[0], 0)
		EndIf
	EndIf
	Return $Ret[5]
EndFunc   ;==>_WinAPI_RegOpenKey

Func _WinAPI_RegQueryInfoKey($hKey)
	Local $Ret = DllCall('advapi32.dll', 'long', 'RegQueryInfoKeyW', 'ulong_ptr', $hKey, 'ptr', 0, 'ptr', 0, 'dword', 0, 'dword*', 0, 'dword*', 0, 'ptr', 0, 'dword*', 0, 'dword*', 0, 'dword*', 0, 'ptr', 0, 'ptr', 0)

	If @error Then
		Return SetError(1, 0, 0)
	Else
		If $Ret[0] Then
			Return SetError(1, $Ret[0], 0)
		EndIf
	EndIf

	Local $Result[5]

	$Result[0] = $Ret[5]
	$Result[1] = $Ret[6]
	$Result[2] = $Ret[8]
	$Result[3] = $Ret[9]
	$Result[4] = $Ret[10]

	Return $Result
EndFunc   ;==>_WinAPI_RegQueryInfoKey

Func _WinAPI_ResumeThread($hThread)
    Local $Ret = DllCall('kernel32.dll', 'dword', 'ResumeThread', 'ptr', $hThread)

    If (@error) Or (_WinAPI_DWordToInt($Ret[0]) = -1) Then
        Return SetError(1, 0, -1)
    EndIf
    Return $Ret[0]
EndFunc

Func _WinAPI_ShellChangeNotify($iEvent, $iFlags, $iItem1 = 0, $iItem2 = 0)

	Local $TypeOfItem1 = 'dword_ptr', $TypeOfItem2 = 'dword_ptr'

	If IsString($iItem1) Then
		$TypeOfItem1 = 'wstr'
	EndIf
	If IsString($iItem2) Then
		$TypeOfItem2 = 'wstr'
	EndIf

	Local $Ret = DllCall('shell32.dll', 'none', 'SHChangeNotify', 'long', $iEvent, 'uint', $iFlags, $TypeOfItem1, $iItem1, $TypeOfItem2, $iItem2)

	If @error Then
		Return SetError(1, 0, 0)
	EndIf
	Return 1
EndFunc   ;==>_WinAPI_ShellChangeNotify

Func _WinAPI_SizeofResource($hInstance, $hResource)

	Local $Ret = DllCall('kernel32.dll', 'dword', 'SizeofResource', 'ptr', $hInstance, 'ptr', $hResource)

	If (@error) Or (Not $Ret[0]) Then
		Return SetError(1, 0, 0)
	EndIf
	Return $Ret[0]
EndFunc   ;==>_WinAPI_SizeofResource

Func _WinAPI_PathCompactPath($hWnd, $sPath, $iWidth = -1)

	Local $hDC, $hBack, $tPath = DllStructCreate('wchar[' & (StringLen($sPath) + 1) & ']')
	Local $Ret

	If $iWidth < 0 Then
		$iWidth = _WinAPI_GetWindowWidth($hWnd)
	EndIf
	$Ret = DllCall('user32.dll', 'hwnd', 'GetDC', 'hwnd', $hWnd)
	If (@error) Or ($Ret[0] = 0) Then
		Return SetError(1, 0, $sPath)
	EndIf
	$hDC = $Ret[0]
	$Ret = DllCall('user32.dll', 'ptr', 'SendMessage', 'hwnd', $hWnd, 'int', 0x0031, 'int', 0, 'int', 0)
	$hBack = _WinAPI_SelectObject($hDC, $Ret[0])
	DllStructSetData($tPath, 1, $sPath)
	$Ret = DllCall('shlwapi.dll', 'int', 'PathCompactPathW', 'hwnd', $hDC, 'ptr', DllStructGetPtr($tPath), 'int', $iWidth)
	If (@error) Or ($Ret[0] = 0) Then
		$Ret = 0
	EndIf
	_WinAPI_SelectObject($hDC, $hBack)
	_WinAPI_ReleaseDC($hWnd, $hDC)
	If Not IsArray($Ret) Then
		Return SetError(1, 0, $sPath)
	EndIf
	Return DllStructGetData($tPath, 1)
EndFunc   ;==>_WinAPI_PathCompactPath

Func _WinAPI_SetClassLong($hWnd, $iIndex, $iNewLong)

	Local $Ret = DllCall('user32.dll', 'int', 'SetClassLong', 'hwnd', $hWnd, 'int', $iIndex, 'long', $iNewLong)

	If (@error) Or ($Ret[0] = 0) Then
		Return SetError(1, 0, 0)
	EndIf
	Return $Ret[0]
EndFunc   ;==>_WinAPI_SetClassLong

Func _WinAPI_RegGetTimeStamp($iRegHive, $sRegKey)
    Local $sTxt = '', $aRet, $hReg = DllStructCreate("int")
    Local $FILETIME = DllStructCreate("dword;dword")
    Local $SYSTEMTIME1 = DllStructCreate("ushort;ushort;ushort;ushort;ushort;ushort;ushort;ushort")
    Local $SYSTEMTIME2 = DllStructCreate("ushort;ushort;ushort;ushort;ushort;ushort;ushort;ushort")
	
    Local $hAdvAPI32 = DllOpen('advapi32.dll')
	Local $hKernel32 = DllOpen('kernel32.dll')

    $aRet = DllCall("advapi32.dll", "int", "RegOpenKeyEx", "int", $iRegHive, "str", $sRegKey, "int", 0, "int", $KEY_READ, "ptr", DllStructGetPtr($hReg))
    $aRet = DllCall("advapi32.dll", "int", "RegQueryInfoKey", "int", DllStructGetData($hReg, 1), "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", 0, "ptr", DllStructGetPtr($FILETIME))  
    $aRet = DllCall("advapi32.dll", "int", "RegCloseKey", "int", DllStructGetData($hReg, 1))
    $aRet = DllCall("kernel32.dll", "int", "FileTimeToSystemTime", "ptr", DllStructGetPtr($FILETIME), "ptr", DllStructGetPtr($SYSTEMTIME1))  
    $aRet = DllCall("kernel32.dll", "int", "SystemTimeToTzSpecificLocalTime", "ptr", 0, "ptr", DllStructGetPtr($SYSTEMTIME1), "ptr", DllStructGetPtr($SYSTEMTIME2))

	DllClose($hAdvAPI32)
	DllClose($hKernel32)
	
    $sTxt &= StringFormat("%.2d",DllStructGetData($SYSTEMTIME2,4)) &'/'
    $sTxt &= StringFormat("%.2d",DllStructGetData($SYSTEMTIME2,2)) &'/'
    $sTxt &= StringFormat("%.2d",DllStructGetData($SYSTEMTIME2,1)) &' '
    $sTxt &= StringFormat("%.2d",DllStructGetData($SYSTEMTIME2,5)) &':'
    $sTxt &= StringFormat("%.2d",DllStructGetData($SYSTEMTIME2,6)) &':'
    $sTxt &= StringFormat("%.2d",DllStructGetData($SYSTEMTIME2,7))

    Return $sTxt
EndFunc   ;==> _WinAPI_RegGetTimeStamp

Func _WinAPI_QueryInformationJobObject($hJob, $iJobObjectInfoClass, ByRef $tJobObjectInfo)
	Local $Ret = DllCall('kernel32.dll', 'int', 'QueryInformationJobObject', 'ptr', $hJob, 'int', $iJobObjectInfoClass, 'ptr', DllStructGetPtr($tJobObjectInfo), 'dword', DllStructGetSize($tJobObjectInfo), 'dword*', 0)

	If (@error) Or (Not $Ret[0]) Then
		Return SetError(1, 0, 0)
	EndIf
	Return $Ret[5]
EndFunc   ;==>_WinAPI_QueryInformationJobObject