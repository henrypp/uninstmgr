#cs
	Uninstall Manager 1.50
	
	Author: [Nuker-Hoax]
	HomePage: http://uninstmgr.sourceforge.net
#ce

#NoTrayIcon

#include "ComboConstants.au3"
#include "EditConstants.au3"
#include "GUIConstants.au3"
#include "GuiListView.au3"
#Include "GUIMenu.au3"
#Include "GUIStatusBar.au3"
#include "StaticConstants.au3"
#include "WindowsConstants.au3"

#include "Include\ColorPicker.au3"
#include "Include\WinAPIEx.au3"

Global $admin_status, $status_str, $find_text = ""

If @OSArch <> "X86" Then
	MsgBox(16, "Ошибка ("& StringLower(@OSArch) &")", "Архитектура операционной системы не поддерживается")
	Exit
EndIf

If not IsAdmin() Then
	$admin_status = 0
	If MsgBox(4 + 32, "Внимание", 'Внимание: "'& @UserName &'" не имеет прав "Администратора"' &@CRLF& 'Продолжить выполнение программы в режиме "Только чтение"?' &@CRLF&@CRLF& 'В режиме "Только чтение" вы не можете:' &@CRLF& '- Деинсталлировать программы' &@CRLF& '- Удалять данные из реестра') = 7 Then Exit
Else
	$admin_status = 1
EndIf

Global $application = "Uninstall Manager"
Global $version = "1.50"
If $admin_status = 0 Then $status_str = " (только чтение)"
Global $homepage = "http://sforce5.narod.ru/uninstmgr"
Global $projectpage = "http://sourceforge.net/projects/uninstmgr"
Global $settings_file = @ScriptDir &"\"& StringTrimRight(@ScriptName, 4) &".ini"
Global $update_url = $homepage &"/update.dat"

Global $reg_open_desired = $KEY_READ

Global Const $GCL_HICONSM = -34, $GCL_HICON = -14
Global Const $FR_DOWN = 0x1
Global Const $FR_MATCHCASE = 0x4
Global Const $FR_FINDNEXT = 0x8
Global Const $FR_HIDEMATCHCASE = 0x8000
Global Const $FR_HIDEWHOLEWORD = 0x10000

Global $tFINDREPLACE = DllStructCreate("dword;hwnd hOwner;hwnd hInstance;dword Flags;ptr FindWhat;ptr ReplaceWith;ushort FindLen;ushort ReplaceLen;ptr CustData;ptr pHook;ptr")
Global $tFindBuffer = DllStructCreate("char[256]")
Global $tReplaceBuffer = DllStructCreate("char[256]")

If _Mutex("UNINSTALL_MANAGER") = 1 Then 
	WinActivate($application &" "& $version)
	Exit
EndIf

_ReadSettings()

Global $main_dlg = GUICreate($application &" "& $version &" ["& @ComputerName &"\"& @UserName &"]"& $status_str, $win_width, $win_height, $win_left, $win_top, $WS_MAXIMIZEBOX + $WS_MINIMIZEBOX + $WS_SIZEBOX + $WS_SYSMENU)
GUISetIcon(@ScriptFullPath, -1, $main_dlg)

;Gui ListView
Global $uninstall_lv = GUICtrlCreateListView("", 0, 0, $win_width, $win_height, $LVS_SORTASCENDING)
_GUICtrlListView_SetExtendedListViewStyle($uninstall_lv, $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT + $LVS_EX_INFOTIP)
_GUICtrlListView_AddColumn($uninstall_lv, "Название программы", 200)
_GUICtrlListView_AddColumn($uninstall_lv, "Издатель", 150)
_GUICtrlListView_AddColumn($uninstall_lv, "Версия", 80)
_GUICtrlListView_AddColumn($uninstall_lv, "Комманда удаления", 230)
_GUICtrlListView_AddColumn($uninstall_lv, "Ключ в реестре", 200)
_GUICtrlListView_AddColumn($uninstall_lv, "Инсталлятор", 100)
_GUICtrlListView_AddColumn($uninstall_lv, "Ветка реестра", 100)
_GUICtrlListView_AddColumn($uninstall_lv, "Дата установки", 100)

;ListView Context Menu
Global $Dummy = GUICtrlCreateDummy()
Global $lv_menu = GUICtrlCreateContextMenu($Dummy)
Global $uninstall_item = GUICtrlCreateMenuItem("Деинсталлировать" &@TAB& "Del", $lv_menu)
Global $silent_uninstall_item = GUICtrlCreateMenuItem('"Тихая" деинсталляция', $lv_menu)
Global $modify_item = GUICtrlCreateMenuItem("Восстановить", $lv_menu)
GUICtrlCreateMenuItem("", $lv_menu)
Global $delete_reg_key_item = GUICtrlCreateMenuItem("Удалить ключ реестра", $lv_menu)
Global $copy_item = GUICtrlCreateMenuItem("Копировать данные"& @TAB &"Ctrl+C", $lv_menu)
GUICtrlCreateMenuItem("", $lv_menu)
Global $open_folder_item = GUICtrlCreateMenuItem("Открыть папку", $lv_menu)
Global $open_regedit_item = GUICtrlCreateMenuItem("Открыть в реестре", $lv_menu)
Global $search_google_item = GUICtrlCreateMenuItem("Поиск в Google", $lv_menu)
GUICtrlCreateMenuItem("", $lv_menu)
Global $http_site_item = GUICtrlCreateMenuItem("Открыть страницу программы", $lv_menu)
Global $http_support_item = GUICtrlCreateMenuItem("Открыть страницу поддержки", $lv_menu)
Global $http_update_item = GUICtrlCreateMenuItem("Открыть страницу обновления", $lv_menu)
GUICtrlCreateMenuItem("", $lv_menu)
Global $properties_item = GUICtrlCreateMenuItem("Свойства" &@TAB& "Enter", $lv_menu)
Global $hMenu = GUICtrlGetHandle($lv_menu)

;Gui Menu
Global $file_menu = GUICtrlCreateMenu("Файл")
Global $refresh_item = GUICtrlCreateMenuItem("Обновить"& @TAB &"F5", $file_menu)
Global $exit_item = GUICtrlCreateMenuItem("Выйти"& @TAB &"Esc", $file_menu)
Global $edit_menu = GUICtrlCreateMenu("Правка")
Global $copy_2_item = GUICtrlCreateMenuItem("Копировать"& @TAB &"Ctrl+C", $edit_menu)
Global $select_all_item = GUICtrlCreateMenuItem("Выделить всё"& @TAB &"Ctrl+A", $edit_menu)
GUICtrlCreateMenuItem("", $edit_menu)
Global $find_item = GUICtrlCreateMenuItem("Найти..."& @TAB &"Ctrl+F", $edit_menu)
Global $find_next_item = GUICtrlCreateMenuItem("Найти далее"& @TAB &"F3", $edit_menu)
Global $view_menu = GUICtrlCreateMenu("Вид")
Global $view_details_item = GUICtrlCreateMenuItem("Детали", $view_menu, 0, 1)
Global $view_icons_item = GUICtrlCreateMenuItem("Значки", $view_menu, 0, 1)
Global $view_list_item = GUICtrlCreateMenuItem("Список", $view_menu, 0, 1)
GUICtrlCreateMenuItem("", $view_menu)
Global $auto_size_column_width_item = GUICtrlCreateMenuItem("Выровнять ширину колонок", $view_menu)
Global $tools_menu = GUICtrlCreateMenu("Инструменты")
Global $backup_item = GUICtrlCreateMenuItem("Сохранить раздел реестра (Uninstall)", $tools_menu)
Global $html_item = GUICtrlCreateMenuItem("Сохранить список в отчёт (HTML)", $tools_menu)
Global $options_menu = GUICtrlCreateMenu("Параметры")
Global $show_icons_item = GUICtrlCreateMenuItem("Загружать значки", $options_menu)
Global $show_updates_item = GUICtrlCreateMenuItem("Показывать обновления", $options_menu)
Global $show_components_item = GUICtrlCreateMenuItem("Показывать системные компоненты", $options_menu)
Global $show_incorrect_item = GUICtrlCreateMenuItem("Показывать неудаляемые элементы", $options_menu)
GUICtrlCreateMenuItem("", $options_menu)
Global $settings_item = GUICtrlCreateMenuItem("Настройки", $options_menu)
Global $help_menu = GUICtrlCreateMenu("Помощь")
Global $homepage_item = GUICtrlCreateMenuItem("Сайт программы", $help_menu)
Global $projectpage_item = GUICtrlCreateMenuItem("Страница проекта (sf.net)", $help_menu)
Global $check_update_item = GUICtrlCreateMenuItem("Проверить обновления", $help_menu)
Global $about_item = GUICtrlCreateMenuItem("О программе", $help_menu)

Global $set_view = IniRead($settings_file, "settings", "ViewMode", 0)
_GUICtrlListView_SetView($uninstall_lv, $set_view)
If $set_view = 0 Then _SetChecked($view_details_item)
If $set_view = 1 Then _SetChecked($view_icons_item)
If $set_view = 2 Then _SetChecked($view_list_item)

;Gui StatusBar
Dim $iStatusParts[3] = [200, 600]
Global $main_status = _GUICtrlStatusBar_Create($main_dlg,"", "", $SBT_TOOLTIPS)
_GUICtrlStatusBar_SetParts($main_status, $iStatusParts)
_GUICtrlStatusBar_SetMinHeight($main_status, 25)
_GUICtrlStatusBar_Resize($main_status)

If $show_application_icon_option = 1 Then
	GuiCtrlSetState($show_icons_item, $GUI_CHECKED)
Else
	GuiCtrlSetState($show_icons_item, $GUI_UNCHECKED)
EndIf
If $show_updates_option = 1 Then
	GuiCtrlSetState($show_updates_item, $GUI_CHECKED)
Else
	GuiCtrlSetState($show_updates_item, $GUI_UNCHECKED)
EndIf
If $show_incorrect_option = 1 Then
	GuiCtrlSetState($show_incorrect_item, $GUI_CHECKED)
Else
	GuiCtrlSetState($show_incorrect_item, $GUI_UNCHECKED)
EndIf
If $show_components_option = 1 Then
	GuiCtrlSetState($show_components_item, $GUI_CHECKED)
Else
	GuiCtrlSetState($show_components_item, $GUI_UNCHECKED)
EndIf

_GUICtrlListView_RegisterSortCallBack($uninstall_lv)

If $admin_status = 0 Then 
	AdlibRegister("_SetReadOnly", 200)
	Dim $HotKeys[6][2]=[["{ENTER}", $properties_item], ["{F5}", $refresh_item], ["^a", $select_all_item], ["^f", $find_item], ["{F3}", $find_next_item], ["^c", $copy_item]]
	GUISetAccelerators($HotKeys)
Else
	Dim $HotKeys[7][2]=[["{DEL}", $uninstall_item], ["{ENTER}", $properties_item], ["{F5}", $refresh_item], ["^a", $select_all_item], ["^f", $find_item], ["{F3}", $find_next_item], ["^c", $copy_item]]
	GUISetAccelerators($HotKeys)
EndIf

GUIRegisterMsg(_WinAPI_RegisterWindowMessage("commdlg_FindReplace"), "WM_FINDREPLACE")
GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")
GUIRegisterMsg($WM_SIZE, "WM_SIZE")

If $check_updates_at_startup_option = 1 Then _CheckForUpdate(1)
GUISetState(@SW_SHOW)

_GenerateUninstallList("HKEY_LOCAL_MACHINE", $show_loading_dialog_option)
If $show_hkcu_option = 1 Then _GenerateUninstallList("HKEY_CURRENT_USER", $show_loading_dialog_option)

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE, $exit_item
			If $remember_widow_position_option = 1 Then
				Local $pos = WinGetPos($main_dlg)
				If not @error and $pos[0] > 0 Then IniWrite($settings_file, "settings", "WindowPosition", $pos[2] &","& $pos[3] &","& $pos[0] &","& $pos[1])
			EndIf
			Exit
		Case $refresh_item
			_GenerateUninstallList()
			If $show_hkcu_option = 1 Then _GenerateUninstallList("HKEY_CURRENT_USER")
		Case $select_all_item
			_GUICtrlListView_SetItemSelected($uninstall_lv, -1, 1)
		Case $find_item
			_FindCreateDialog()
		Case $find_next_item
			If $find_text <> "" Then
				Local $selected = _GUICtrlListView_GetSelectedIndices($uninstall_lv, 1)
				If $selected[0] <> 0 Then
					$iFind = _GUICtrlListView_FindInText($uninstall_lv, $find_text, $selected[1], 0)
					If $iFind = -1 Then
						MsgBox(64, "Поиск", "Поиск завершён", 0, $main_dlg)
					Else
						_GUICtrlListView_ClickItem($uninstall_lv, $iFind)
					EndIf
				EndIf
			EndIf
		Case $settings_item
			_SettingsDlg($main_dlg)
		Case $homepage_item
			ShellExecute($homepage)
		Case $projectpage_item
			ShellExecute($projectpage)
		Case $check_update_item
			_CheckForUpdate()
		Case $about_item
			MsgBox(64, "О программе", $application &" "& $version &@CRLF& "Copyright © 2010 [Nuker-Hoax]" &@CRLF&@CRLF& "Благодарности:" &@CRLF& "Mr.Creator, Yashied, Jarvis Stubblefield, Bob Anthony" &@CRLF& "Rajesh V R, Suppir, Kaster, amel27, engine, Vendor" &@CRLF&@CRLF& "За Tablecloth (CSS) спасибо Css Globe (www.cssglobe.com)" &@CRLF&@CRLF& "Эта программа бесплатна и распространяется" &@CRLF& "под лицензией GNU General Public License." &@CRLF&@CRLF& $homepage, 0, $main_dlg)
		Case $uninstall_item
			Local $request = 6
			Local $selected = _GUICtrlListView_GetSelectedIndices($uninstall_lv, True)
			If $selected[0] <> 0 Then
				Local $program_list = ""
				For $i = 1 to $selected[0]
					Local $get_array_1 = _GUICtrlListView_GetItemTextArray($uninstall_lv, $selected[$i])
					If RegRead($get_array_1[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $get_array_1[5], "UninstallString") = "" Then 
						$program_list &= ""
					Else
						$program_list &= $i &") "& $get_array_1[1] &@CRLF
					EndIf
				Next
				If $program_list <> "" Then
				If $selected[0] > 30 Then $program_list = ""
					If $request_delete_option = 1 Then $request = MsgBox(4 + 32, "Внимание", "Вы действительно хотите удалить выбранные программы с компьютера ("& $selected[0] &") ?" &@CRLF&@CRLF& $program_list, 0, $main_dlg)
						If $request = 6 Then
							GUISetState(@SW_MINIMIZE)
							For $i = 1 to $selected[0]
								Local $get_array_2 =_GUICtrlListView_GetItemTextArray($uninstall_lv, $selected[$i])
								Local $UninstCmd = RegRead($get_array_2[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $get_array_2[5], "UninstallString")
								_RunWait($UninstCmd, $get_array_2[5], $get_array_2[7])
							Next
							GUISetState(@SW_RESTORE)
							_GenerateUninstallList("HKEY_LOCAL_MACHINE")
							If $show_hkcu_option = 1 Then _GenerateUninstallList("HKEY_CURRENT_USER")
							_WinAPI_ShellChangeNotify(0x8000000, 0x00001000)
					EndIf
				EndIf
				For $a = 1 to $selected[0]
					_GUICtrlListView_SetItemState($uninstall_lv, $selected[$a], $LVIS_SELECTED, $LVIS_SELECTED)
				Next
				_GUICtrlListView_EnsureVisible($uninstall_lv, $selected[1])
			EndIf
		Case $modify_item
			Local $selected = _GUICtrlListView_GetSelectionMark($uninstall_lv)
			If $selected <> -1 Then
				Local $together =_GUICtrlListView_GetItemTextArray($uninstall_lv, $selected)
				If MsgBox(4 + 32, "Внимание", "Вы действительно хотите восстановить "& $together[1] &" ?", 0, $main_dlg) = 6 Then
					Local $ModifyPath = RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "ModifyPath")

					GUISetState(@SW_MINIMIZE)
					_RunWait($ModifyPath, $together[5], $together[7])
					GUISetState(@SW_RESTORE)

					_GUICtrlListView_EnsureVisible($uninstall_lv, $selected)
					_GUICtrlListView_SetItemSelected($uninstall_lv, $selected)
					_GenerateUninstallList("HKEY_LOCAL_MACHINE")
					If $show_hkcu_option = 1 Then _GenerateUninstallList("HKEY_CURRENT_USER")
					_WinAPI_ShellChangeNotify(0x8000000, 0x00001000)
				EndIf
			EndIf
		Case $silent_uninstall_item
			Local $selected = _GUICtrlListView_GetSelectionMark($uninstall_lv)
			If $selected <> -1 Then
				Local $together =_GUICtrlListView_GetItemTextArray($uninstall_lv, $selected)
				If MsgBox(4 + 32, "Внимание", "Вы действительно хотите деинсталлировать "& $together[1] &" ?", 0, $main_dlg) = 6 Then
					Local $UninstallString = RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "UninstallString")
					Local $QuietUninstallString = RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "QuietUninstallString")
					Local $WindowsInstaller = RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "WindowsInstaller")

					If $QuietUninstallString <> "" Then 
						GUISetState(@SW_MINIMIZE)
						_RunWait($QuietUninstallString, $together[5], $together[7])
						GUISetState(@SW_RESTORE)
					ElseIf $WindowsInstaller = 1 Then
						GUISetState(@SW_MINIMIZE)
						_RunWait("msiexec.exe /passive /promptrestart /x "& $together[5], $together[5], $together[7])
						GUISetState(@SW_RESTORE)
					ElseIf $together[6] = "NSIS" Then
						GUISetState(@SW_MINIMIZE)
						_RunWait($UninstallString &" /S", $together[5], $together[7])
						GUISetState(@SW_RESTORE)
					ElseIf $together[6] = "Inno Setup" Then
						GUISetState(@SW_MINIMIZE)
						_RunWait($UninstallString &" /SILENT /NORESTART", $together[5], $together[7])
						GUISetState(@SW_RESTORE)
					ElseIf $together[6] = "Smart Install Maker" Then
						GUISetState(@SW_MINIMIZE)
						_RunWait($UninstallString &" /s", $together[5], $together[7])
						GUISetState(@SW_RESTORE)
					ElseIf $together[6] = "Astrum Installer" Then
						GUISetState(@SW_MINIMIZE)
						_RunWait($UninstallString
					ElseIf $together[6] = "Excelsior Installer" Then
						GUISetState(@SW_MINIMIZE)
						_RunWait($UninstallString &" /batch", $together[5], $together[7])
						GUISetState(@SW_RESTORE)
					ElseIf $together[6] = "Ghost Installer" Then
						GUISetState(@SW_MINIMIZE)
						_RunWait($UninstallString &" -s", $together[5], $together[7])
						GUISetState(@SW_RESTORE)
					ElseIf $together[6] = "Setup Factory" Then
						GUISetState(@SW_MINIMIZE)
						_RunWait($UninstallString &" /S", $together[5], $together[7])
						GUISetState(@SW_RESTORE)
						GUISetState(@SW_RESTORE)
					EndIf

					_GUICtrlListView_EnsureVisible($uninstall_lv, $selected)
					_GUICtrlListView_SetItemSelected($uninstall_lv, $selected)
					_GenerateUninstallList("HKEY_LOCAL_MACHINE")
					If $show_hkcu_option = 1 Then _GenerateUninstallList("HKEY_CURRENT_USER")
					_WinAPI_ShellChangeNotify(0x8000000, 0x00001000)
				EndIf
			EndIf
		Case $delete_reg_key_item
			Local $selected = _GUICtrlListView_GetSelectedIndices($uninstall_lv, True)
			If $selected[0] <> 0 Then
				Local $program_list = ""
				For $i = 1 to $selected[0]
					Local $get_array_1 =_GUICtrlListView_GetItemTextArray($uninstall_lv, $selected[$i])
					$program_list &= $i &") "& $get_array_1[1] &@CRLF& $together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"&$get_array_1[5] &@CRLF&@CRLF
				Next
				If $selected[0] > 15 Then $program_list = ""
				If MsgBox(4 + 32, "Внимание", "Вы действительно хотите удалить данные из реестра ("& $selected[0] &") ?" &@CRLF&@CRLF& $program_list, 0, $main_dlg) = 6 Then
					Local $error_text = ""
					For $i = 1 to $selected[0]
						Local $get_array_2 =_GUICtrlListView_GetItemTextArray($uninstall_lv, $selected[$i])
						Local $reg_del = RegDelete($get_array_2[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"&$get_array_2[5])
						If $reg_del = 0 Then $error_text &= "Ключ не существует: "& $get_array_2[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"&$get_array_2[5] &@CRLF
						If $reg_del = 2 Then $error_text &= "Ошибка при удалении: "& $get_array_2[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"&$get_array_2[5] &@CRLF
					Next
					If StringLen($error_text) > 0 Then MsgBox(16, "Ошибки", "При выполнении операций произошли следующие ошибки:" &@CRLF&@CRLF& $error_text, 0, $main_dlg)
					_GenerateUninstallList("HKEY_LOCAL_MACHINE")
					If $show_hkcu_option = 1 Then _GenerateUninstallList("HKEY_CURRENT_USER")
					For $a = 1 to $selected[0]
						_GUICtrlListView_SetItemState($uninstall_lv, $selected[$a], $LVIS_SELECTED, $LVIS_SELECTED)
					Next
					_GUICtrlListView_EnsureVisible($uninstall_lv, $selected[1])
				EndIf
			EndIf
		Case $copy_item, $copy_2_item
			Local $selected = _GUICtrlListView_GetSelectedIndices($uninstall_lv, True)
			If $selected[0] <> 0 Then
				Local $copy_text = ""
				For $i = 1 to $selected[0]
					Local $together =_GUICtrlListView_GetItemTextArray($uninstall_lv, $selected[$i])
					If $together[0] <> 0 Then
						$copy_text &= "Название программы: " &@TAB& $together[1] &@CRLF& "Издатель: " &@TAB&@TAB& $together[2] &@CRLF& "Версия: " &@TAB&@TAB& $together[3] &@CRLF& "Комманда удаления: " &@TAB& $together[4] &@CRLF& "Ключ в реестре: " &@TAB& $together[5] &@CRLF& "Инсталлятор: " &@TAB&@TAB& $together[6] &@CRLF& "Ветка реестра: " &@TAB&@TAB& $together[7] &@CRLF& "Дата установки: " &@TAB& $together[8] &@CRLF&@CRLF
					EndIf
				Next
				
				ClipPut($copy_text)
				
				For $a = 1 to $selected[0]
					_GUICtrlListView_SetItemState($uninstall_lv, $selected[$a], $LVIS_SELECTED, $LVIS_SELECTED)
				Next
			EndIf
		Case $open_folder_item
			Local $selected = _GUICtrlListView_GetSelectionMark($uninstall_lv)
			If $selected <> -1 Then
				Local $together =_GUICtrlListView_GetItemTextArray($uninstall_lv, $selected)
				Local $InstallLocation = RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "InstallLocation")
				Local $UninstallString = RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "UninstallString")
				If $InstallLocation <> "" Then 
					ShellExecute($InstallLocation)
				Else
					Local $sPath = _GetPath($UninstallString)
					If FileExists($sPath) Then 
						$sFolder = StringRegExp($sPath, '(^.*\\).*', 1)
						If not @error Then ShellExecute($sFolder[0])
					EndIf
				EndIf
				_GUICtrlListView_EnsureVisible($uninstall_lv, $selected)
				_GUICtrlListView_SetItemSelected($uninstall_lv, $selected)
			EndIf
		Case $open_regedit_item
			Local $selected = _GUICtrlListView_GetSelectionMark($uninstall_lv)
			If $selected <> -1 Then
				Local $together =_GUICtrlListView_GetItemTextArray($uninstall_lv, $selected)
				If $together[0] <> 0 Then
					_RegOpenKey($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], $main_dlg)
				EndIf
				_GUICtrlListView_EnsureVisible($uninstall_lv, $selected)
				_GUICtrlListView_SetItemSelected($uninstall_lv, $selected)
			EndIf
		Case $search_google_item
			Local $selected = _GUICtrlListView_GetSelectionMark($uninstall_lv)
			If $selected <> -1 Then
				Local $together =_GUICtrlListView_GetItemTextArray($uninstall_lv, $selected)
				If $together[1] <> "" Then ShellExecute("http://www.google.ru/search?hl=ru&lr=lang_ru&q="& $together[1])
				_GUICtrlListView_EnsureVisible($uninstall_lv, $selected)
				_GUICtrlListView_SetItemSelected($uninstall_lv, $selected)
			EndIf
		Case $http_site_item
			Local $selected = _GUICtrlListView_GetSelectionMark($uninstall_lv)
			If $selected <> -1 Then
				Local $together =_GUICtrlListView_GetItemTextArray($uninstall_lv, $selected)
				If $together[1] <> "" Then 
					Local $Link = RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "URLInfoAbout")
					If $Link <> "" Then ShellExecute($Link)
				EndIf
				_GUICtrlListView_EnsureVisible($uninstall_lv, $selected)
				_GUICtrlListView_SetItemSelected($uninstall_lv, $selected)
			EndIf		
		Case $http_support_item
			Local $selected = _GUICtrlListView_GetSelectionMark($uninstall_lv)
			If $selected <> -1 Then
				Local $together =_GUICtrlListView_GetItemTextArray($uninstall_lv, $selected)
				If $together[1] <> "" Then 
					Local $Link = RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "HelpLink")
					If $Link <> "" Then ShellExecute($Link)
				EndIf
				_GUICtrlListView_EnsureVisible($uninstall_lv, $selected)
				_GUICtrlListView_SetItemSelected($uninstall_lv, $selected)
			EndIf		
		Case $http_update_item
			Local $selected = _GUICtrlListView_GetSelectionMark($uninstall_lv)
			If $selected <> -1 Then
				Local $together =_GUICtrlListView_GetItemTextArray($uninstall_lv, $selected)
				If $together[1] <> "" Then 
					Local $Link = RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "URLUpdateInfo")
					If $Link <> "" Then ShellExecute($Link)
				EndIf
				_GUICtrlListView_EnsureVisible($uninstall_lv, $selected)
				_GUICtrlListView_SetItemSelected($uninstall_lv, $selected)
			EndIf
		Case $properties_item
			Local $selected = _GUICtrlListView_GetSelectionMark($uninstall_lv)
			If $selected <> -1 Then
				Local $together = _GUICtrlListView_GetItemTextArray($uninstall_lv, $selected)
				If $together[1] <> "" Then _PropertiesDlg($together[5], $together[7], $main_dlg)
				_GUICtrlListView_EnsureVisible($uninstall_lv, $selected)
				_GUICtrlListView_SetItemSelected($uninstall_lv, $selected)
			EndIf
		Case $backup_item
			Local $reg_file = FileSaveDialog("Выберите файл для сохранения...", "", "Файл реестра (*.reg)", 16, "uninstall_" &@MDAY &"_"& @MON&"_"& @YEAR, $main_dlg)
			If @error = 0 Then
				Local $sFile = $reg_file &".reg"
				FileDelete($sFile)
				Run("regedit.exe /e "& '"'& $sFile &'"'& "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall")
			EndIf
		Case $html_item
			Local $iCount = _GUICtrlListView_GetItemCount($uninstall_lv)
			If ($iCount - 1) = 0 Then 
				MsgBox(16, "Ошибка", "Нет данных для сохранения отчёта", 0, $main_dlg)
			Else
				Local $html_file = FileSaveDialog("Выберите файл для сохранения...", "", "HTML файлы (*.html)", 16, "report_" &@MDAY &"_"& @MON&"_"& @YEAR, $main_dlg)
				If @error = 0 Then
					Local $sFile = $html_file &".html"
					FileDelete($sFile)
					FileWrite($sFile, _GenerateHTMLReport())
					If MsgBox(4 + 32, "Сохранено", "Отчёт сохранён, вы хотите его открыть?" &@CRLF&@CRLF& _WinAPI_PathCompactPath(0, $sFile, 400), -1, $main_dlg) = 6 Then ShellExecute($sFile)
				EndIf
			EndIf
		Case $show_icons_item
			Local $def_setting = IniRead($settings_file, "settings", "ShowApplicationIcons", 0)
			If $def_setting = 1 Then
				GuiCtrlSetState($show_icons_item, $GUI_UNCHECKED)
				IniWrite($settings_file, "settings", "ShowApplicationIcons", 0)
			Else
				GuiCtrlSetState($show_icons_item, $GUI_CHECKED)
				IniWrite($settings_file, "settings", "ShowApplicationIcons", 1)
			EndIf
			_GenerateUninstallList("HKEY_LOCAL_MACHINE")
			If $show_hkcu_option = 1 Then _GenerateUninstallList("HKEY_CURRENT_USER")
		Case $show_updates_item
			Local $def_setting = IniRead($settings_file, "settings", "ShowUpdates", 0)
			If $def_setting = 1 Then
				GuiCtrlSetState($show_updates_item, $GUI_UNCHECKED)
				IniWrite($settings_file, "settings", "ShowUpdates", 0)
			Else
				GuiCtrlSetState($show_updates_item, $GUI_CHECKED)
				IniWrite($settings_file, "settings", "ShowUpdates", 1)
			EndIf
			_GenerateUninstallList("HKEY_LOCAL_MACHINE")
			If $show_hkcu_option = 1 Then _GenerateUninstallList("HKEY_CURRENT_USER")
		Case $show_components_item
			Local $def_setting = IniRead($settings_file, "settings", "ShowComponents", 0)
			If $def_setting = 1 Then
				GuiCtrlSetState($show_components_item, $GUI_UNCHECKED)
				IniWrite($settings_file, "settings", "ShowComponents", 0)
			Else
				GuiCtrlSetState($show_components_item, $GUI_CHECKED)
				IniWrite($settings_file, "settings", "ShowComponents", 1)
			EndIf
			_GenerateUninstallList("HKEY_LOCAL_MACHINE")
			If $show_hkcu_option = 1 Then _GenerateUninstallList("HKEY_CURRENT_USER")
		Case $show_incorrect_item
			Local $def_setting = IniRead($settings_file, "settings", "ShowIncorrectItem", 0)
			If $def_setting = 1 Then
				GuiCtrlSetState($show_incorrect_item, $GUI_UNCHECKED)
				IniWrite($settings_file, "settings", "ShowIncorrectItem", 0)
			Else
				GuiCtrlSetState($show_incorrect_item, $GUI_CHECKED)
				IniWrite($settings_file, "settings", "ShowIncorrectItem", 1)
			EndIf
			_GenerateUninstallList("HKEY_LOCAL_MACHINE")
			If $show_hkcu_option = 1 Then _GenerateUninstallList("HKEY_CURRENT_USER")
        Case $Dummy
            $Item = GUICtrlRead($Dummy)
            If $Item >= 0 Then
				Local $together = _GUICtrlListView_GetItemTextArray($uninstall_lv, $Item)
				If $together <> "" Then
					Local $ModifyPath = RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "ModifyPath")
					If RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "DisplayName") = "" Then GUICtrlSetState($search_google_item, $GUI_DISABLE)
					If  $ModifyPath = "" Then GUICtrlSetState($modify_item, $GUI_DISABLE)
					If RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "QuietUninstallString") = "" and $together[6] = "" or $together[6] = "CreateInstall" or $together[6] = "Agentix Installer" Then GUICtrlSetState($silent_uninstall_item, $GUI_DISABLE)
					If RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "HelpLink") = "" Then GUICtrlSetState($http_support_item, $GUI_DISABLE)
					If RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "URLInfoAbout") = "" Then GUICtrlSetState($http_site_item, $GUI_DISABLE)
					If RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "URLUpdateInfo") = "" Then GUICtrlSetState($http_update_item, $GUI_DISABLE)
				EndIf
					
				Local $IL = RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "InstallLocation")
				Local $US = RegRead($together[7] &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $together[5], "UninstallString")

				If $IL = "" and _GetPath($US) = "" Then GUICtrlSetState($open_folder_item, $GUI_DISABLE)
				If $US = "" Then GUICtrlSetState($uninstall_item, $GUI_DISABLE)
										
                _GUICtrlMenu_TrackPopupMenu($hMenu, $main_dlg)

				GUICtrlSetState($uninstall_item, $GUI_ENABLE)
				GUICtrlSetState($open_folder_item, $GUI_ENABLE)
				GUICtrlSetState($search_google_item, $GUI_ENABLE)
				GUICtrlSetState($modify_item, $GUI_ENABLE)
				GUICtrlSetState($silent_uninstall_item, $GUI_ENABLE)
				GUICtrlSetState($http_support_item, $GUI_ENABLE)
				GUICtrlSetState($http_site_item, $GUI_ENABLE)
				GUICtrlSetState($http_update_item, $GUI_ENABLE)
            EndIf
		Case $view_icons_item
			_GUICtrlListView_SetView($uninstall_lv, 1)
			IniWrite($settings_file, "settings", "ViewMode", 1)
			_SetChecked($view_icons_item)
		Case $view_list_item
			_GUICtrlListView_SetView($uninstall_lv, 2)
			IniWrite($settings_file, "settings", "ViewMode", 2)
			_SetChecked($view_list_item)
		Case $view_details_item
			_GUICtrlListView_SetView($uninstall_lv, 0)
			IniWrite($settings_file, "settings", "ViewMode", 0)
			_SetChecked($view_details_item)
		Case $auto_size_column_width_item
			Local $iColumnCount = _GUICtrlListView_GetColumnCount($uninstall_lv)
			For $i = 0 to $iColumnCount - 1
				_GUICtrlListView_SetColumnWidth($uninstall_lv, $i, $LVSCW_AUTOSIZE)
			Next
		Case $uninstall_lv
			_GUICtrlListView_SortItems($uninstall_lv, GUICtrlGetState($uninstall_lv))
	EndSwitch
WEnd

Func _CheckForUpdate($iStartupCheck = 0)
	FileDelete(@ScriptDir &"\update.dat")
	Local $UpdateStart = TimerInit(), $get_update = InetGet($update_url, @ScriptDir &"\update.dat", 1, 1)
	
	Do
		Sleep(250)
		If $iStartupCheck Then 
			If Round(TimerDiff($UpdateStart), -1) > 2000 Then ExitLoop
		EndIf
	Until InetGetInfo($get_update, 2)
			
	InetClose($get_update)
	
	Local $new_ver = IniRead(@ScriptDir &"\update.dat", "update", "version", $version)
	FileDelete(@ScriptDir &"\update.dat")
	
	If $new_ver <> $version Then
		If MsgBox(4 + 32, "Обновление", "Доступная новая версия "& $new_ver &@CRLF &"Вы хотите открыть сайт программы для скачивания новой версии?", 0, $main_dlg) = 6 Then ShellExecute($homepage)
	Else
		If $iStartupCheck = 0 Then MsgBox(64, "Обновление", "Нет доступных обновлений", 0, $main_dlg)
	EndIf
EndFunc

Func _SetReadOnly()
	GUICtrlSetState($uninstall_item, $GUI_DISABLE)
	GUICtrlSetState($silent_uninstall_item, $GUI_DISABLE)
	GUICtrlSetState($modify_item, $GUI_DISABLE)
	GUICtrlSetState($delete_reg_key_item, $GUI_DISABLE)
EndFunc

Func _SetChecked($hItem)
	GUICtrlSetState($view_icons_item, $GUI_UNCHECKED)
	GUICtrlSetState($view_list_item, $GUI_UNCHECKED)
	GUICtrlSetState($view_details_item, $GUI_UNCHECKED)
	GUICtrlSetState($hItem, $GUI_CHECKED)
EndFunc

Func _ReadSettings()
	Local $halfWidth = @DesktopWidth / 2, $halfHeight = @DesktopHeight / 2 - 50
	Local $defPosition = $halfWidth + $halfWidth / 2 &","& $halfHeight + $halfHeight / 2 &",-1,-1"

	Global $remember_widow_position_option = IniRead($settings_file, "settings", "RememberWindowPosition", 1)
	Local $win_pos = IniRead($settings_file, "settings", "WindowPosition", $defPosition)
	
	If $remember_widow_position_option = 1 Then
		Local $pos_split = StringSplit($win_pos, ",", 2)
	Else
		Local $pos_split = StringSplit($defPosition, ",", 2)
	EndIf
	
	Global $win_width = $pos_split[0]
	Global $win_height = $pos_split[1]
	Global $win_left = $pos_split[2]
	Global $win_top = $pos_split[3]
	
	Global $check_updates_at_startup_option = IniRead($settings_file, "settings", "CheckUpdatesAtStartup", 1)
	Global $show_application_icon_option = IniRead($settings_file, "settings", "ShowApplicationIcons", 1)
	Global $show_updates_option = IniRead($settings_file, "settings", "ShowUpdates", 0)
	Global $show_components_option = IniRead($settings_file, "settings", "ShowComponents", 0)
	Global $show_loading_dialog_option = IniRead($settings_file, "settings", "ShowLoadingDialog", 1)
	Global $request_delete_option = IniRead($settings_file, "settings", "RequestBeforeDelete", 1)
	Global $allow_highlighting_option = IniRead($settings_file, "settings", "AllowHighlighting", 1)
	Global $show_incorrect_option = IniRead($settings_file, "settings", "ShowIncorrectItem", 0)
	Global $show_freename_option = IniRead($settings_file, "settings", "ShowFreeName", 0)
	Global $show_hkcu_option = IniRead($settings_file, "settings", "ShowHKCU", 1)
	Global $color_updates_option = IniRead($settings_file, "settings", "ColorUpdates", 0xd06c00)
	Global $color_components_option = IniRead($settings_file, "settings", "ColorComponents", 0xd0d0ff)
	Global $color_incorrect_option = IniRead($settings_file, "settings", "ColorIncorrectItem", 0x880015)
EndFunc

Func _GenerateUninstallList($sRoot = "HKEY_LOCAL_MACHINE", $iShow = 0, $hWnd = $main_dlg)
	Local $selected_item = _GUICtrlListView_GetSelectedIndices($uninstall_lv, True), $LV_Item
	
	_ReadSettings()

	Local $iWidth = 352, $iHeight = 88, $iLeft = -1, $iTop = -1

	If IsHWnd($hWnd) Then
		Local $aPos = WinGetPos($hWnd)
		$iLeft = ($aPos[2] - $iWidth) / 2 + $aPos[0] - 3
		$iTop = ($aPos[3] - $iHeight) / 2 + $aPos[1] - 20
	EndIf

	Local $status_dlg = GUICreate("Загрузка...", $iWidth, $iHeight, $iLeft, $iTop, $WS_POPUP + $WS_BORDER, -1, $hWnd)
	WinSetOnTop($status_dlg, "", 1)
	
	GUICtrlCreateIcon(@ScriptFullPath, -1, 15, 15, 32, 32)
	GUICtrlCreateLabel("Обработка:", 64, 15, 62, 17)
	Local $status_label = GUICtrlCreateLabel("", 64, 30, 270, 17)
	Local $status_progress = GUICtrlCreateProgress(15, 58, 322, 17)
	
	If $iShow = 1 Then GUISetState(@SW_SHOW)

	If $sRoot = "HKEY_LOCAL_MACHINE" Then
		Local $hRootName = $HKEY_LOCAL_MACHINE
		Local $hKey = _WinAPI_RegOpenKey($HKEY_LOCAL_MACHINE, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', $reg_open_desired)
	ElseIf $sRoot = "HKEY_CURRENT_USER" Then
		Local $hRootName = $HKEY_CURRENT_USER
		Local $hKey = _WinAPI_RegOpenKey($HKEY_CURRENT_USER, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall', $reg_open_desired)
	EndIf

	Local $Count = _WinAPI_RegQueryInfoKey($hKey)
	If IsArray($Count) Then
		If $Count[0] = 0 or @error <> 0 Then 
				GUIDelete($status_dlg)
			Return
		EndIf
	Else
		GUIDelete($status_dlg)
		Return
	EndIf
	
    Local $UnInstKey = $sRoot &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"

    If $sRoot <> "HKEY_CURRENT_USER" Then _GUICtrlListView_DeleteAllItems($uninstall_lv)
	_GUICtrlListView_BeginUpdate($uninstall_lv)

	Dim $aKey[$Count[0]]
	
	For $i = 0 To UBound($aKey) - 1
		Local $AppKey = _WinAPI_RegEnumKey($hKey, $i)
		
		_GUICtrlStatusBar_SetText($main_status, "Всего программ: "& _GUICtrlListView_GetItemCount($uninstall_lv), 0)
		_GUICtrlStatusBar_SetText($main_status, "Обработка ключа: "& $AppKey, 1)

        Local $aName = StringStripWS(RegRead($UnInstKey &"\"& $AppKey, "DisplayName"), 3)
		
		Local $iPercent = Int(($i / UBound($aKey)) * 100)
		GUICtrlSetData($status_progress, $iPercent)
		GUICtrlSetData($status_label, $AppKey)

		Local $aVersion = StringStripWS(RegRead($UnInstKey &"\"& $AppKey, "DisplayVersion"), 3)
        Local $aPublisher = StringStripWS(RegRead($UnInstKey &"\"& $AppKey, "Publisher"), 3)
        Local $aUninstallString = StringStripWS(RegRead($UnInstKey &"\"& $AppKey, "UninstallString"), 3)

		Local $Installer = _CheckInstaller(_GetPath($aUninstallString))
		If $Installer = "" Then
			If RegRead($UnInstKey &"\"& $AppKey, "WindowsInstaller") = 1 or StringInStr($aUninstallString, "msiexec") <> 0 Then $Installer = "Windows Installer"
			If RegRead($UnInstKey &"\"& $AppKey, "WindowsInstaller") = 1 Then $Installer = "Windows Installer"
		EndIf
	
		Local $aKeyInfo = _GetVersionInfoEx($sRoot, $AppKey)
		If $aVersion = "" Then $aVersion = $aKeyInfo[0]
		If $aPublisher = "" Then $aPublisher = $aKeyInfo[1]
	
		If $aUninstallString <> "" and $aName <> "" and _IsSystemUpdate($AppKey) <> 1 and _IsSystemComponent($AppKey) <> 1 Then 
			Local $sDate = _WinAPI_RegGetTimeStamp($hRootName, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $AppKey)
			Local $LV_Item = GUICtrlCreateListViewItem($aName &"|"& $aPublisher &"|"& $aVersion &"|"& $aUninstallString &"|"& $AppKey &"|"& $Installer &"|"& $sRoot &"|"& $sDate, $uninstall_lv)
			_EntrySetIcon($LV_Item, $AppKey, 0, $sRoot)
		EndIf
		
		If $show_freename_option = 1 and $aName = "" Then 
			Local $sDate = _WinAPI_RegGetTimeStamp($hRootName, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $AppKey)
			Local $LV_Item = GUICtrlCreateListViewItem($aName &"|"& $aPublisher &"|"& $aVersion &"|"& $aUninstallString &"|"& $AppKey &"|"& $Installer &"|"& $sRoot &"|"& $sDate, $uninstall_lv)
			_EntrySetIcon($LV_Item, $AppKey, 0, $sRoot)
		EndIf
		
		If $show_incorrect_option = 1 and $aUninstallString = "" Then
			Local $sDate = _WinAPI_RegGetTimeStamp($hRootName, "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $AppKey)
			Local $LV_Item = GUICtrlCreateListViewItem($aName & "|" & $aPublisher & "|" & $aVersion & "|" & $aUninstallString & "|" & $AppKey & "|" & $Installer &"|"& $sRoot &"|"& $sDate, $uninstall_lv)
			_EntrySetIcon($LV_Item, $AppKey, 0, $sRoot)
			If $allow_highlighting_option = 1 Then 
				GUICtrlSetBkColor($LV_Item, $color_incorrect_option)
				GUICtrlSetColor($LV_Item, 0xffffff)
			EndIf
		EndIf
		
		If $show_updates_option = 1 and _IsSystemUpdate($AppKey) = 1 Then
			$LV_Item = GUICtrlCreateListViewItem($aName & "|" & $aPublisher & "|" & $aVersion & "|" & $aUninstallString & "|" & $AppKey & "|" & $Installer &"|"& $sRoot, $uninstall_lv)
			_EntrySetIcon($LV_Item, $AppKey, 0, $sRoot)
			If $allow_highlighting_option = 1 Then 
				GUICtrlSetBkColor($LV_Item, $color_updates_option)
				GUICtrlSetColor($LV_Item, 0xffffff)
			EndIf
		EndIf
		
		If $show_components_option = 1 and _IsSystemComponent($AppKey) = 1 Then
			$LV_Item = GUICtrlCreateListViewItem($aName & "|" & $aPublisher & "|" & $aVersion & "|" & $aUninstallString & "|" & $AppKey & "|" & $Installer &"|"& $sRoot, $uninstall_lv)
			_EntrySetIcon($LV_Item, $AppKey, 0, $sRoot)
			If $allow_highlighting_option = 1 Then 
				GUICtrlSetBkColor($LV_Item, $color_components_option)
				GUICtrlSetColor($LV_Item, 0xffffff)
			EndIf
		EndIf
	Next
		
	_WinAPI_RegCloseKey($hKey)
	
	_GUICtrlListView_EndUpdate($uninstall_lv)
		
	_GUICtrlStatusBar_SetText($main_status, "Всего программ: "& _GUICtrlListView_GetItemCount($uninstall_lv), 0)
	_GUICtrlStatusBar_SetText($main_status, "", 1)
	
	GUIDelete($status_dlg)

	If $selected_item[0] <> 0 Then
		For $i = 1 to $selected_item[0]
			_GUICtrlListView_SetItemState($uninstall_lv, $selected_item[$i], $LVIS_SELECTED, $LVIS_SELECTED)
			Local $last = $selected_item[$i]
		Next
		_GUICtrlListView_EnsureVisible($uninstall_lv, $last)
	EndIf
EndFunc

Func _SettingsDlg($hWnd = 0)
	GUISetState(@SW_DISABLE, $hWnd)
	
	_ReadSettings()

	Local $iWidth = 412, $iHeight = 260, $iLeft = -1, $iTop = -1
	
	If IsHWnd($hWnd) Then
		Local $aPos = WinGetPos($hWnd)
		$iLeft = ($aPos[2] - $iWidth) / 2 + $aPos[0] - 3
		$iTop = ($aPos[3] - $iHeight) / 2 + $aPos[1] - 20
	EndIf

	Local $settings_dlg = GUICreate("Настройки", $iWidth, $iHeight, $iLeft, $iTop, $WS_CAPTION + $WS_SYSMENU, $WS_EX_DLGMODALFRAME, $hWnd)
	Local $hIcon = _WinAPI_GetClassLong($settings_dlg, $GCL_HICON)
	_WinAPI_DestroyIcon($hIcon)
	_WinAPI_SetClassLong($settings_dlg, $GCL_HICON, 0)
	_WinAPI_SetClassLong($settings_dlg, $GCL_HICONSM, 0)

	Local $save_btn = GUICtrlCreateButton("Сохранить", 246, 224, 75, 25, -1, $WS_EX_STATICEDGE)
	DllCall("UxTheme.dll", "int", "SetWindowTheme", "hwnd", GUICtrlGetHandle(-1), "wstr", "", "wstr", "")
	GUICtrlSetState(-1, $GUI_DEFBUTTON)
	
	Local $cancel_btn = GUICtrlCreateButton("Закрыть", 326, 224, 75, 25, -1, $WS_EX_STATICEDGE)
	DllCall("UxTheme.dll", "int", "SetWindowTheme", "hwnd", GUICtrlGetHandle(-1), "wstr", "", "wstr", "")

	Local $main_tab = GUICtrlCreateTab(10, 10, 393, 201)

	Local $main_tab_item = GUICtrlCreateTabItem("Основные")

	GUICtrlCreateGroup("", 21, 37, 370, 161)
	DllCall("UxTheme.dll", "int", "SetWindowTheme", "hwnd", GUICtrlGetHandle(-1), "wstr", "", "wstr", "")

	Local $check_updates_at_startup_chk = GUICtrlCreateCheckbox("Проверять обновления при запуске", 35, 55, 330, 20)
	If $check_updates_at_startup_option = 1 Then GuiCtrlSetState(-1, $GUI_CHECKED)
		
	Local $show_loading_dialog_chk = GUICtrlCreateCheckbox("Показывать окно загрузки данных из реестра при запуске", 35, 75, 330, 20)
	If $show_loading_dialog_option = 1 Then GuiCtrlSetState(-1, $GUI_CHECKED)
		
	Local $remember_widow_position_chk = GUICtrlCreateCheckbox("Запоминать положение окна программы", 35, 95, 330, 20)
	If $remember_widow_position_option = 1 Then GuiCtrlSetState(-1, $GUI_CHECKED)
	
	Local $request_delete_chk = GUICtrlCreateCheckbox("Запрашивать подтверждение на удаление программ", 35, 115, 330, 20)
	If $request_delete_option = 1 Then GuiCtrlSetState(-1, $GUI_CHECKED)

	Local $list_tab_item = GUICtrlCreateTabItem("Список")
	GUICtrlCreateGroup("", 21, 37, 370, 161)
	DllCall("UxTheme.dll", "int", "SetWindowTheme", "hwnd", GUICtrlGetHandle(-1), "wstr", "", "wstr", "")

	Local $show_icons_chk = GUICtrlCreateCheckbox("Загружать значки элементов", 35, 55, 330, 20)
	If $show_application_icon_option = 1 Then GuiCtrlSetState(-1, $GUI_CHECKED)
	
	Local $show_update_chk = GUICtrlCreateCheckbox("Показывать установленные обновления", 35, 75, 330, 20)
	If $show_updates_option = 1 Then GuiCtrlSetState(-1, $GUI_CHECKED)
	
	Local $show_components_chk = GUICtrlCreateCheckbox("Показывать системные компоненты", 35, 95, 330, 20)
	If $show_components_option = 1 Then GuiCtrlSetState(-1, $GUI_CHECKED)
	
	Local $show_incorrect_chk = GUICtrlCreateCheckbox("Показывать неудаляемые элементы", 35, 115, 330, 20)
	If $show_incorrect_option = 1 Then GuiCtrlSetState(-1, $GUI_CHECKED)
		
	Local $show_freename_chk = GUICtrlCreateCheckbox("Показывать элементы с пустым именем", 35, 135, 330, 20)
	If $show_freename_option = 1 Then GuiCtrlSetState(-1, $GUI_CHECKED)
		
	Local $show_hkcu_chk = GUICtrlCreateCheckbox("Обрабатывать ветку реестра из HKCU", 35, 155, 330, 20)
	If $show_hkcu_option = 1 Then GuiCtrlSetState(-1, $GUI_CHECKED)

	Local $highlighting_tab_item = GUICtrlCreateTabItem("Подсветка")
	GUICtrlCreateGroup("", 21, 37, 370, 161)
	DllCall("UxTheme.dll", "int", "SetWindowTheme", "hwnd", GUICtrlGetHandle(-1), "wstr", "", "wstr", "")

	Local $allow_highlighting_chk = GUICtrlCreateCheckbox('Разрешить подсветку "особых" элементов', 35, 55, 330, 20)
	If $allow_highlighting_option = 1 Then GuiCtrlSetState(-1, $GUI_CHECKED)

	GUICtrlCreateLabel("Обновления:", 35, 85, 140, 25, $SS_CENTERIMAGE)
	Local $updates_color_btn = _GUIColorPicker_Create("", 200, 85, 70, 25, $color_updates_option, $CP_FLAG_DEFAULT + $CP_FLAG_ARROWSTYLE + $CP_FLAG_TIP, -1, -1, -1, -1, "", "Изменить")

	GUICtrlCreateLabel("Системные компоненты:", 35, 115, 140, 25, $SS_CENTERIMAGE)
	Local $components_color_btn = _GUIColorPicker_Create("", 200, 115, 70, 25, $color_components_option, $CP_FLAG_DEFAULT + $CP_FLAG_ARROWSTYLE + $CP_FLAG_TIP, -1, -1, -1, -1, "", "Изменить")

	GUICtrlCreateLabel("Неудаляемые элементы:", 35, 145, 140, 25, $SS_CENTERIMAGE)
	Local $incorrect_color_btn = _GUIColorPicker_Create("", 200, 145, 70, 25, $color_incorrect_option, $CP_FLAG_DEFAULT + $CP_FLAG_ARROWSTYLE + $CP_FLAG_TIP, -1, -1, -1, -1, "", "Изменить")
	
	GUISetState(@SW_SHOW)

	While 1
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $save_btn
				IniWrite($settings_file, "settings", "RememberWindowPosition", Number(GUICtrlRead($remember_widow_position_chk) = $GUI_CHECKED))
				IniWrite($settings_file, "settings", "CheckUpdatesAtStartup", Number(GUICtrlRead($check_updates_at_startup_chk) = $GUI_CHECKED))
				IniWrite($settings_file, "settings", "ShowApplicationIcons", Number(GUICtrlRead($show_icons_chk) = $GUI_CHECKED))
				IniWrite($settings_file, "settings", "ShowUpdates", Number(GUICtrlRead($show_update_chk) = $GUI_CHECKED))
				IniWrite($settings_file, "settings", "ShowComponents", Number(GUICtrlRead($show_components_chk) = $GUI_CHECKED))
				IniWrite($settings_file, "settings", "ShowLoadingDialog", Number(GUICtrlRead($show_loading_dialog_chk) = $GUI_CHECKED))
				IniWrite($settings_file, "settings", "AllowHighlighting", Number(GUICtrlRead($allow_highlighting_chk) = $GUI_CHECKED))
				IniWrite($settings_file, "settings", "RequestBeforeDelete", Number(GUICtrlRead($request_delete_chk) = $GUI_CHECKED))
				IniWrite($settings_file, "settings", "ShowIncorrectItem", Number(GUICtrlRead($show_incorrect_chk) = $GUI_CHECKED))
				IniWrite($settings_file, "settings", "ShowFreeName", Number(GUICtrlRead($show_freename_chk) = $GUI_CHECKED))
				IniWrite($settings_file, "settings", "ShowHKCU", Number(GUICtrlRead($show_hkcu_chk) = $GUI_CHECKED))
				IniWrite($settings_file, "settings", "ColorUpdates", "0x"& StringTrimLeft(Hex(_GUIColorPicker_GetColor($updates_color_btn)), 2))
				IniWrite($settings_file, "settings", "ColorComponents", "0x"& StringTrimLeft(Hex(_GUIColorPicker_GetColor($components_color_btn)), 2))
				IniWrite($settings_file, "settings", "ColorIncorrectItem", "0x"& StringTrimLeft(Hex(_GUIColorPicker_GetColor($incorrect_color_btn)), 2))

				_ReadSettings()
				
				If $show_application_icon_option = 1 Then
					GuiCtrlSetState($show_icons_item, $GUI_CHECKED)
				Else
					GuiCtrlSetState($show_icons_item, $GUI_UNCHECKED)
				EndIf
				If $show_updates_option = 1 Then
					GuiCtrlSetState($show_updates_item, $GUI_CHECKED)
				Else
					GuiCtrlSetState($show_updates_item, $GUI_UNCHECKED)
				EndIf
				If $show_components_option = 1 Then
					GuiCtrlSetState($show_components_item, $GUI_CHECKED)
				Else
					GuiCtrlSetState($show_components_item, $GUI_UNCHECKED)
				EndIf
				If $show_incorrect_option = 1 Then
					GuiCtrlSetState($show_incorrect_item, $GUI_CHECKED)
				Else
					GuiCtrlSetState($show_incorrect_item, $GUI_UNCHECKED)
				EndIf

				_GUIColorPicker_Delete($updates_color_btn)
				_GUIColorPicker_Delete($components_color_btn)
				_GUIColorPicker_Delete($incorrect_color_btn)
				
				GUISetState(@SW_ENABLE, $hWnd)
				GUIDelete($settings_dlg)
				_GenerateUninstallList("HKEY_LOCAL_MACHINE")
				If $show_hkcu_option = 1 Then _GenerateUninstallList("HKEY_CURRENT_USER")
				ExitLoop
			Case $GUI_EVENT_CLOSE, $cancel_btn
				_GUIColorPicker_Delete($updates_color_btn)
				_GUIColorPicker_Delete($components_color_btn)
				_GUIColorPicker_Delete($incorrect_color_btn)
				
				GUISetState(@SW_ENABLE, $hWnd)
				GUIDelete($settings_dlg)
				ExitLoop
		EndSwitch
	WEnd
EndFunc

Func _PropertiesDlg($sEntry, $sRoot, $hWnd = $main_dlg)
	Local $aKeyInfo = _GetVersionInfoEx($sRoot, $sEntry)
	Local $RegPath = $sRoot &"\Software\Microsoft\Windows\CurrentVersion\Uninstall\"& $sEntry
	Local $DisplayName = RegRead($RegPath, "DisplayName")
	If $DisplayName = "" Then $DisplayName = "n/a"
	Local $DisplayVersion = RegRead($RegPath, "DisplayVersion")
	If $DisplayVersion = "" Then $DisplayVersion = $aKeyInfo[0]
	If $DisplayVersion = "" Then $DisplayVersion = "n/a"
	Local $Publisher = RegRead($RegPath, "Publisher")
	If $Publisher = "" Then $Publisher = $aKeyInfo[1]
	If $Publisher = "" Then $Publisher = "n/a"
	
	Local $iWidth = 439, $iHeight = 453, $iLeft = -1, $iTop = -1
	
	If IsHWnd($hWnd) Then
		Local $aPos = WinGetPos($hWnd)
		$iLeft = ($aPos[2] - $iWidth) / 2 + $aPos[0] - 3
		$iTop = ($aPos[3] - $iHeight) / 2 + $aPos[1] - 20
	EndIf
	
	GUISetState(@SW_DISABLE, $hWnd)
	Local $properties_dlg = GUICreate("Свойства", $iWidth, $iHeight, $iLeft, $iTop, $WS_CAPTION + $WS_SYSMENU, $WS_EX_DLGMODALFRAME, $hWnd)
	Local $hIcon = _WinAPI_GetClassLong($properties_dlg, $GCL_HICON)
	_WinAPI_DestroyIcon($hIcon)
	_WinAPI_SetClassLong($properties_dlg, $GCL_HICON, 0)
	_WinAPI_SetClassLong($properties_dlg, $GCL_HICONSM, 0)
	
	GUICtrlCreateGroup("Свойства программы", 10, 5, 420, 150)
	DllCall("UxTheme.dll", "int", "SetWindowTheme", "hwnd", GUICtrlGetHandle(-1), "wstr", "", "wstr", "")
	GUICtrlCreateIcon("", -1, 25, 30, 32, 32)
	_EntrySetIcon(-1, $sEntry, 1, $sRoot)
	
	GUICtrlCreateLabel("Название:", 60, 25, 75, 15, $SS_RIGHT)
	GUICtrlCreateInput($DisplayName, 145, 25, 270, 15, $ES_READONLY + $ES_AUTOHSCROLL, $WS_EX_WINDOWEDGE)

	GUICtrlCreateLabel("Версия:", 60, 45, 75, 15, $SS_RIGHT)
	GUICtrlCreateInput($DisplayVersion, 145, 45, 270, 15, $ES_READONLY + $ES_AUTOHSCROLL, $WS_EX_WINDOWEDGE)

	GUICtrlCreateLabel("Издатель:", 60, 65, 75, 15, $SS_RIGHT)
	GUICtrlCreateInput($Publisher, 145, 65, 270, 15, $ES_READONLY + $ES_AUTOHSCROLL, $WS_EX_WINDOWEDGE)
	
	GUICtrlCreateLabel("Ветка:", 60, 85, 75, 15, $SS_RIGHT)
	GUICtrlCreateInput($sRoot, 145, 85, 270, 15, $ES_READONLY + $ES_AUTOHSCROLL, $WS_EX_WINDOWEDGE)

	GUICtrlCreateLabel("Запись:", 60, 105, 75, 15, $SS_RIGHT)
	GUICtrlCreateInput($sEntry, 145, 105, 270, 15, $ES_READONLY + $ES_AUTOHSCROLL, $WS_EX_WINDOWEDGE)

	GUICtrlCreateLabel("Полный путь:", 60, 125, 75, 15, $SS_RIGHT)
	GUICtrlCreateInput($RegPath, 145, 125, 270, 15, $ES_READONLY + $ES_AUTOHSCROLL, $WS_EX_WINDOWEDGE)

	Local $properties_lv = GUICtrlCreateListView("", 10, 162, 420, 250, $LVS_SORTASCENDING + $LVS_NOSORTHEADER)
	_GUICtrlListView_SetExtendedListViewStyle($properties_lv, $LVS_EX_FULLROWSELECT + $LVS_EX_INFOTIP + $LVS_EX_GRIDLINES)
	_GUICtrlListView_AddColumn($properties_lv, "Параметр", 150)
	_GUICtrlListView_AddColumn($properties_lv, "Значение", 265)
	
	Local $properties_cxt = GUICtrlCreateContextMenu($properties_lv)
	Local $copy_item = GUICtrlCreateMenuItem("Копировать", $properties_cxt)
	Local $copy_value_item = GUICtrlCreateMenuItem("Копировать значение", $properties_cxt)
	
	Local $i = 1

	While 1
		Local $enum_val = RegEnumVal($sRoot &"\Software\Microsoft\Windows\CurrentVersion\Uninstall\"& $sEntry, $i)
		If @error Then ExitLoop
		Local $value = RegRead($sRoot &"\Software\Microsoft\Windows\CurrentVersion\Uninstall\"& $sEntry, $enum_val)
		Local $value_type = @extended
		If $enum_val <> "" Then
			Local $lv_item = GUICtrlCreateListViewItem($enum_val &"|"& $value, $properties_lv)
			Switch $value_type
				Case 1, 7
					GUICtrlSetImage($lv_item, "regedit.exe", 205)
				Case 3, 4
					GUICtrlSetImage($lv_item, "regedit.exe", 206)
				Case Else
					GUICtrlSetImage($lv_item, "regedit.exe", 205)
			EndSwitch
		EndIf
		$i+=1
	WEnd
	
	Local $regedit_btn = GUICtrlCreateButton("Открыть в реестре", 10, 420, 120, 25, -1, $WS_EX_STATICEDGE)
	DllCall("UxTheme.dll", "int", "SetWindowTheme", "hwnd", GUICtrlGetHandle(-1), "wstr", "", "wstr", "")
	
	Local $close_btn = GUICtrlCreateButton("Закрыть", 356, 420, 75, 25, $BS_DEFPUSHBUTTON, $WS_EX_STATICEDGE)
	DllCall("UxTheme.dll", "int", "SetWindowTheme", "hwnd", GUICtrlGetHandle(-1), "wstr", "", "wstr", "")

	GUISetState(@SW_SHOW)

	While 1
		$aMsg = GUIGetMsg()
		Switch $aMsg
			Case $GUI_EVENT_CLOSE, $close_btn
				GUISetState(@SW_ENABLE, $hWnd)
				GuiDelete($properties_dlg)
				ExitLoop
			Case $copy_item
				Local $selected = _GUICtrlListView_GetSelectionMark($properties_lv)
				If $selected <> -1 Then
					Local $together = _GUICtrlListView_GetItemTextArray($properties_lv, $selected)
					ClipPut($together[1] &" "& $together[2])
				EndIf
			Case $copy_value_item
				Local $selected_2 = _GUICtrlListView_GetSelectionMark($properties_lv)
				If $selected_2 <> -1 Then
					Local $together = _GUICtrlListView_GetItemTextArray($properties_lv, $selected_2)
					ClipPut($together[2])
				EndIf
			Case $regedit_btn
				_RegOpenKey($RegPath, $properties_dlg)
		EndSwitch
	WEnd
EndFunc

Func _FindCreateDialog()
	DllStructSetData($tFINDREPLACE, 1, DllStructGetSize($tFINDREPLACE))
	DllStructSetData($tFINDREPLACE, "hOwner", $main_dlg)
	DllStructSetData($tFINDREPLACE, "Flags", BitOR($FR_DOWN, $FR_HIDEWHOLEWORD, $FR_HIDEMATCHCASE))
	DllStructSetData($tFINDREPLACE, "FindWhat", DllStructGetPtr($tFindBuffer))
	DllStructSetData($tFINDREPLACE, "FindLen", 255)
	DllStructSetData($tFINDREPLACE, "ReplaceWith", DllStructGetPtr($tReplaceBuffer))
	DllStructSetData($tFINDREPLACE, "ReplaceLen", 255)
	Local $aRet = DllCall('comdlg32.dll', 'hwnd', 'FindText', 'ptr', DllStructGetPtr($tFINDREPLACE))
	If $aRet[0] <> 0 Then Return $aRet[0]
	$aRet = DllCall('comdlg32.dll', 'int', 'CommDlgExtendedError')
	Return SetError($aRet[0], 0, 0)
EndFunc

Func _CheckInstaller($sInstallerPath)
	Local $bCreateInstall = _ResourceGetAsStr($sInstallerPath, "SETUP_TEMP", $RT_RCDATA)
	Local $sManifest = _ResourceGetAsStr($sInstallerPath, 1, $RT_MANIFEST)
	
	Local $bOverlay = _GetEXEOverlay($sInstallerPath)
	Local $nsis_sign = "EFBEADDE4E756C6C736F6674496E7374"
	Local $inno_sign = "496E6E6F205365747570204D65737361676573"
	Local $createinstall_sign = "474541000000"
	
	If StringInStr($bCreateInstall, $createinstall_sign) Then Return "CreateInstall"
	If StringInStr($bOverlay, $nsis_sign) Then Return "NSIS"
	If StringInStr($bOverlay, $inno_sign) Then Return "Inno Setup"
		
	If StringInStr(BinaryToString($sManifest), "ThraexSoftware.AstrumInstallWizard.AstrumUninstaller") Then Return "Astrum Installer"
	If StringInStr(BinaryToString($sManifest), "AGENTIX_Software.AGInstaller") Then Return "Agentix Installer"
	Local $RegExp = StringRegExpReplace(BinaryToString($sManifest), '(?s).*<description>(.*)</description>.*', '\1')
	If not @error Then
		If StringInStr($RegExp, "Smart Install Maker") Then Return "Smart Install Maker"
		If StringInStr($RegExp, "Setup Factory") Then Return "Setup Factory"
		If StringInStr($RegExp, "Excelsior Uninstaller") Then Return "Excelsior Installer"
		If StringInStr($RegExp, "Inno Setup") Then Return "Inno Setup"
		If StringInStr($RegExp, "Nullsoft Install System") Then Return "NSIS"
		If StringInStr($RegExp, "Ghost Installer") Then Return "Ghost Installer"
	EndIf
	
	Return ""
EndFunc

Func _ResourceGetAsStr($sfile, $sName, $iType)
	Local $hInstance = _WinAPI_LoadLibrary($sfile)
	
	Local $hResource = _WinAPI_FindResource($hInstance, $sName, $iType)
	Local $Size = _WinAPI_SizeofResource($hInstance, $hResource)
	Local $hData = _WinAPI_LoadResource($hInstance, $hResource)
	Local $pData = _WinAPI_LockResource($hData)
	Local $tData = DllStructCreate('byte[' & $Size & ']', $pData)
	Local $sData = DllStructGetData($tData, 1)
	
	_WinAPI_FreeLibrary($hInstance)
	
	Return $sData
EndFunc

Func _GetEXEOverlay($sModule)
	Local $aCall = DllCall("kernel32.dll", "ptr", "LoadLibraryExW", "wstr", $sModule, "ptr", 0, "int", 1)

	If @error Or Not $aCall[0] Then
		Return SetError(1, 0, 0)
	EndIf

	Local $hModule = $aCall[0]
	Local $pPointer = $aCall[0]

	Local $tIMAGE_DOS_HEADER = DllStructCreate("char Magic[2];" & _
			"ushort BytesOnLastPage;" & _
			"ushort Pages;" & _
			"ushort Relocations;" & _
			"ushort SizeofHeader;" & _
			"ushort MinimumExtra;" & _
			"ushort MaximumExtra;" & _
			"ushort SS;" & _
			"ushort SP;" & _
			"ushort Checksum;" & _
			"ushort IP;" & _
			"ushort CS;" & _
			"ushort Relocation;" & _
			"ushort Overlay;" & _
			"char Reserved[8];" & _
			"ushort OEMIdentifier;" & _
			"ushort OEMInformation;" & _
			"char Reserved2[20];" & _
			"dword AddressOfNewExeHeader", _
			$pPointer)

	$pPointer += DllStructGetData($tIMAGE_DOS_HEADER, "AddressOfNewExeHeader")
	$pPointer += 4

	Local $tIMAGE_FILE_HEADER = DllStructCreate("ushort Machine;ushort NumberOfSections;dword TimeDateStamp;dword PointerToSymbolTable;dword NumberOfSymbols;ushort SizeOfOptionalHeader;ushort Characteristics", $pPointer)

	Local $iNumberOfSections = DllStructGetData($tIMAGE_FILE_HEADER, "NumberOfSections")

	$pPointer += 20

	$pPointer += 96

	$pPointer += 128

	Local $tIMAGE_SECTION_HEADER

	For $i = 1 To $iNumberOfSections
		$tIMAGE_SECTION_HEADER = DllStructCreate("char Name[8];dword VirtualSize;dword VirtualAddress;dword SizeOfRawData;dword PointerToRawData;dword PointerToRelocations;dword PointerToLinenumbers;ushort NumberOfRelocations;ushort NumberOfLinenumbers;dword Characteristics", $pPointer)

		If $i = $iNumberOfSections Then
			Local $iEndOfFile = DllStructGetData($tIMAGE_SECTION_HEADER, "PointerToRawData") + DllStructGetData($tIMAGE_SECTION_HEADER, "SizeOfRawData")
		EndIf
		$pPointer += 40
	Next

	$aCall = DllCall("kernel32.dll", "int", "FreeLibrary", "ptr", $hModule)
	If @error Or Not $aCall[0] Then
		Return SetError(2, 0, 0)
	EndIf

	Local $hFile = FileOpen($sModule, 16)
	If $hFile = -1 Then
		Return SetError(3, 0, 0)
	EndIf

	Local $bBinary = BinaryMid(FileRead($hFile), $iEndOfFile + 1)
	FileClose($hFile)
	Return $bBinary
EndFunc

Func _GenerateHTMLReport()
	Local $sText = "", $ItemCount = _GUICtrlListView_GetItemCount($uninstall_lv)

	For $i = 0 to $ItemCount - 1
		$aText = _GUICtrlListView_GetItemTextArray($uninstall_lv, $i)
		$sText &= '<tr><td>'& $aText[1] &'</td><td>'& $aText[2] &'</td><td>'& $aText[3] &'</td><td>'& $aText[4] &'</td><td>'& $aText[5] &'</td><td>'& $aText[6] &'</td><td>'& $aText[7] &'</td><td>'& $aText[8] &'</td></tr>' &@CRLF&@CRLF
	Next
	
	Local $HTML = '<html>' &@CRLF& _
	'<head>' &@CRLF& _
	'<meta http-equiv="Content-Type" content="text/html; charset=1251"/>' &@CRLF& _
	'<title>Установленные программы</title>' &@CRLF&@CRLF& _
	'<style>' &@CRLF& _
	'body{' &@CRLF& _
	'	margin:0;' &@CRLF& _
	'	padding:0;' &@CRLF& _
	'	background:#ffffff;' &@CRLF& _
	'	font:80% Arial;' &@CRLF& _
	'	color:#555;' &@CRLF& _
	'	line-height:150%;' &@CRLF& _
	'	text-align:center;' &@CRLF& _
	'}' &@CRLF& _
	'#container{' &@CRLF& _
	'	margin:0 auto;' &@CRLF& _
	'	width:90%;' &@CRLF& _
	'	background:#ffffff;' &@CRLF& _
	'	padding-bottom:20px;' &@CRLF& _
	'}' &@CRLF& _
	'</style>' &@CRLF&@CRLF& _
	'</head>' &@CRLF&@CRLF& _
	'<body>' &@CRLF&@CRLF& _
	'<div id="container">' &@CRLF& _
	'	<div id="content">' &@CRLF& _
	'		<table cellspacing="0" cellpadding="0">' &@CRLF& _
	'		<tr><th>Название программы</th><th>Издатель</th><th>Версия</th><th>Комманда удаления</th><th>Ключ в реестре</th><th>Инсталлятор</th><th>Ветка реестра</th><th>Дата установки</th></tr>' &@CRLF&@CRLF& _
	$sText &@CRLF&@CRLF& _
	'		</table>' &@CRLF& _
	'<div align=center><a href='& $homepage &'>'& $application &" "& $version&'</a><br>Copyright © 2010 [Nuker-Hoax]</div>' &@CRLF& _
	'	</div>' &@CRLF& _
	'</div>' &@CRLF& _
	'</body></html>' &@CRLF& _
	'<style>' &@CRLF& _
	'	table, td{' &@CRLF& _
	'		font:92% Arial, Helvetica, sans-serif;' &@CRLF& _
	'	}' &@CRLF& _
	'	table{width:100%;border-collapse:collapse;margin:1em 0;}' &@CRLF& _
	'	th, td{padding:.5em;}' &@CRLF& _
	'	th{text-align:center;background:#328aa4 repeat-x;color:#fff;border:1px solid #e5f1f4;}' &@CRLF& _
	'	td{text-align:left;background:#e5f1f4;border:1px solid #328aa4;}' &@CRLF& _
	'</style>'
	
	Return $HTML
EndFunc

Func _GetVersionInfoEx($sRoot, $sKey)
	;Author: Bob Anthony (big_daddy) / modified by [Nuker-Hoax]
	
	Local $aMatches, $sTempPath, $sFile, $hSearch, $sInstallFolder, $sUninstallString, $aRetArray[2]
	$sInstallFolder = RegRead($sRoot &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" & $sKey, "InstallLocation")
	$sUninstallString = RegRead($sRoot &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" & $sKey, "UninstallString")

	If Not FileExists($sInstallFolder) Then
		$aMatches = StringRegExp($sUninstallString, "((?i)(?U)[[:alpha:]]{1}\:\\.*\\?\.{1}(?:exe|dll|ico){1})", 1)
		If Not @error Then
			$sTempPath = StringTrimRight($aMatches[0], StringLen($aMatches[0]) - StringInStr($aMatches[0], "\", 0, -1))
			If Not StringInStr($sTempPath, @WindowsDir) And Not StringInStr($sTempPath, @CommonFilesDir) And Not StringInStr($sTempPath, FileGetShortName(@CommonFilesDir)) Then
				$sInstallFolder = $sTempPath
			EndIf
		EndIf
	EndIf

	If FileExists($sInstallFolder) Then
		$hSearch = FileFindFirstFile($sInstallFolder & "\*.exe")

		If $hSearch <> -1 Then
			While 1
				$sFile = FileFindNextFile($hSearch)
				If @error Then ExitLoop

				If Not StringInStr($sFile, "unins") And Not StringInStr($sFile, "install") And Not StringInStr($sFile, "unwise") And Not StringInStr($sFile, "setup") Then
					$aRetArray[0] = FileGetVersion($sInstallFolder & "\" & $sFile, "FileVersion")
					If $aRetArray[0] = "0.0.0.0" Then $aRetArray[0] = FileGetVersion($sInstallFolder & "\" & $sFile, "ProductVersion")
					$aRetArray[1] = FileGetVersion($sInstallFolder & "\" & $sFile, "CompanyName")
				EndIf
			WEnd

			FileClose($hSearch)
		EndIf
	EndIf
	Return $aRetArray
EndFunc

Func _EntrySetIcon($hWnd, $sEntry, $sForced = 0, $sRoot = "HKEY_LOCAL_MACHINE")
	If $show_application_icon_option <> 1 and $sForced <> 1 Then
		GuiCtrlSetImage($hWnd, @ScriptFullPath, -1)
		Return
	EndIf
	
	Local $aDisplayIcon = RegRead($sRoot &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $sEntry, "DisplayIcon")
	Local $aUninstallString = RegRead($sRoot &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $sEntry, "UninstallString")
	Local $aInstallLocation = StringReplace(RegRead($sRoot &"\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"& $sEntry, "InstallLocation"), '"', "")
	local $sPath = _GetPath($aUninstallString)
	
	If $aInstallLocation = "" Then 
		Local $sFolder = StringRegExp($sPath, '(^.*\\).*', 1)
		If not @error Then $aInstallLocation = $sFolder[0]
	EndIf

	Local $search = StringInStr($aDisplayIcon, ",")
	If $search <> 0 Then 
		$sIcon = StringRegExpReplace($aDisplayIcon, '^\s*(?>"([^"]*+)"|([^,]*?)\s*(?:,|$)).*+', "\1\2")
		$iIcon = StringRegExpReplace($aDisplayIcon, ".*?(?>[\s,]([+-]?\d++)\s*|)$", "\1")+0
		If _WinAPI_ExtractIcon($sIcon, _InvertIndex($iIcon), 0, 0, 0) Then
			GuiCtrlSetImage($hWnd, $sIcon, _InvertIndex($iIcon))
			Return 1
		EndIf
	EndIf
		
	If $aDisplayIcon <> "" Then $aDisplayIcon = StringReplace($aDisplayIcon, '"', "")
	If FileExists($aDisplayIcon) and _WinAPI_ExtractIcon($aDisplayIcon, -1, 0, 0, 0) Then
		GuiCtrlSetImage($hWnd, $aDisplayIcon, -1)
		Return 1
	EndIf
				
	Local $aMsiRegExp = StringRegExp($sEntry, "\{[[:alnum:]]{8}(?:-){1}[[:alnum:]]{4}(?:-){1}[[:alnum:]]{4}(?:-){1}[[:alnum:]]{4}(?:-){1}[[:alnum:]]{12}\}", 1)
	If Not @error Then
		$sInstallerWindows = @WindowsDir & "\Installer\" & $aMsiRegExp[0]

		$hSearch = FileFindFirstFile($sInstallerWindows & "\*.*")
		If $hSearch <> -1 Then
			While 1
				$sFile = FileFindNextFile($hSearch)
				If @error Then ExitLoop
						
				If Not StringInStr($sFile, "unins") And _WinAPI_ExtractIcon($sInstallerWindows & "\" & $sFile, -1, 0, 0, 0) Then
					GuiCtrlSetImage($hWnd, $sInstallerWindows & "\" & $sFile, 0)
					FileClose($hSearch)
					Return 1
				EndIf
			WEnd
		EndIf
		$sInstallerAppData = @AppDataDir & "\Microsoft\Installer\" & $aMsiRegExp[0]

		$hSearch = FileFindFirstFile($sInstallerAppData & "\*.*")
		If $hSearch <> -1 Then
			While 1
				$sFile = FileFindNextFile($hSearch)
				If @error Then ExitLoop
						
				If Not StringInStr($sFile, "unins") And _WinAPI_ExtractIcon($sInstallerAppData & "\" & $sFile, -1, 0, 0, 0) Then
					GuiCtrlSetImage($hWnd, $sInstallerAppData & "\" & $sFile, 0)
					FileClose($hSearch)
					Return 1
				EndIf
			WEnd
		EndIf
	EndIf
		
	If FileExists($aInstallLocation) Then
		$hSearch = FileFindFirstFile($aInstallLocation & "\*.ico")
		If $hSearch = -1 Then
			$hSearch = FileFindFirstFile($aInstallLocation & "\*.exe")
			If $hSearch = -1 Then
				$hSearch = FileFindFirstFile($aInstallLocation & "\*.dll")
			EndIf
		EndIf

		If $hSearch <> -1 Then
			While 1
				$sFile = FileFindNextFile($hSearch)
				If @error Then ExitLoop
				If Not StringInStr($sFile, "unins") And Not StringInStr($sFile, "install") And Not StringInStr($sFile, "unwise") And Not StringInStr($sFile, "setup") And _WinAPI_ExtractIcon($aInstallLocation & "\" & $sFile, -1, 0, 0, 0) Then
					GuiCtrlSetImage($hWnd, $aInstallLocation & "\" & $sFile, -1)
					FileClose($hSearch)
					Return 1
				EndIf
			WEnd
		EndIf
	EndIf
		
	If FileExists($sPath) and _WinAPI_ExtractIcon($sPath, -1, 0, 0, 0) Then
		GuiCtrlSetImage($hWnd, $sPath, -1)
		Return 1
	EndIf
	
	GuiCtrlSetImage($hWnd, @ScriptFullPath, -1)
EndFunc

Func _InvertIndex($iIndex)
    If $iIndex < 0 Then
        $iIndex = -$iIndex
    Else
        $iIndex = -$iIndex - 1
    EndIf
    Return $iIndex
EndFunc

Func _OpenInExplorer($sFile)
	If $sFile <> "" and FileExists($sFile) Then Run("explorer.exe /select," & '"'& $sFile &'"')
EndFunc

Func _GetPath($sPath)
	If StringInStr($sPath, "msiexec") Then Return ""
	If StringInStr($sPath, "rundll32") Then Return ""
		
	Local $aPath = StringRegExp($sPath, '([^"]*\..{3}) *.*$', 1)

	If @error = 0 Then 
		Return $aPath[0]
	Else
		Return ""
	EndIf
EndFunc

Func _IsSystemComponent($regKey)
	Local $regPath = "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\" & $regKey
	If RegRead($regPath, "SystemComponent") = 1 Then Return 1
	Return ""
EndFunc

Func _IsSystemUpdate($regKey)
	Local $regPath = "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\" & $regKey
	If StringStripWS(RegRead($regPath, "ParentKeyName"), 3) <> "" Then Return 1
	Return ""
EndFunc 

Func _RegOpenKey($sRegKey, $hWnd = $main_dlg)
	Local $Computer, $CheckRegedit = RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableRegistryTools")
	
	If $CheckRegedit = 1 and $admin_status = 1 Then
		If MsgBox(32 + 4, "Ошибка", "Редактирование реестра запрещено администратором системы"&@CRLF&"Вы хотите включить редактор реестра для продолжения?", -1, $hWnd) = 6 Then
			RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System", "DisableRegistryTools", "REG_DWORD", 0)
		Else
			Return 0
		EndIf
	ElseIf $CheckRegedit = 1 and $admin_status = 0 Then
		MsgBox(16, "Ошибка", "Редактирование реестра запрещено администратором системы", -1, $hWnd)
		Return 0
	EndIf
	
	If @OSVersion = "WIN_2000" or "WIN_XP" or "WIN_2003" Then $Computer = "My Computer\"
	If @OSVersion = "WIN_7" or "WIN_VISTA" or "WIN_2008" or "WIN_2008R2" Then $Computer = "Computer\"
		
	ProcessClose("regedit.exe")
	RegWrite("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit", "LastKey", "REG_SZ", $Computer & $sRegKey)
	If @error Then Return 0
	Run("regedit.exe")
EndFunc

Func _RunWait($sCMD, $sEntry, $sRoot, $iNoGui = 0, $hWnd = $main_dlg)
	If $iNoGui = 0 Then
		GUISetState(@SW_DISABLE, $hWnd)
		Local $wait_dlg = GUICreate("", 250, 90, @DesktopWidth - 262, @DesktopHeight - 133, $WS_POPUP + $WS_DLGFRAME, -1, $hWnd)

		Local $app_icon = GUICtrlCreateIcon("", "", 10, 10, 32, 32) 
		_EntrySetIcon($app_icon, $sEntry, 1, $sRoot)
		Local $DisplayName = RegRead($sRoot &"\Software\Microsoft\Windows\CurrentVersion\Uninstall\" & $sEntry, "DisplayName")
		
		GUICtrlCreateLabel("Деинсталляция:", 52, 10, 185, 15)
		GUICtrlCreateLabel($DisplayName, 52, 30, 185, 30, $GUI_FOCUS)
		GUICtrlCreateLabel("Нажмите чтобы закрыть окно:", 10, 65, 160, 20, $SS_CENTERIMAGE)

		Local $close_dlg = GUICtrlCreateButton("Готово", 175, 65, 65, 20, -1, $WS_EX_STATICEDGE)
		GUICtrlSetState(-1, $GUI_DEFBUTTON)
		DllCall("UxTheme.dll", "int", "SetWindowTheme", "hwnd", GUICtrlGetHandle(-1), "wstr", "", "wstr", "")

		GUISetState(@SW_SHOW)
	EndIf
	
    Local $tProcess = DllStructCreate($tagPROCESS_INFORMATION)
    Local $tStartup = DllStructCreate($tagSTARTUPINFO)
    Local $tInfo = DllStructCreate($tagJOBOBJECT_BASIC_ACCOUNTING_INFORMATION)
    Local $hJob, $hProcess, $hThread

    $hJob = _WinAPI_CreateJobObject()
    If @error Then
        Return SetError(1, 0, 0)
    EndIf
    DllStructSetData($tStartup, 'Size', DllStructGetSize($tStartup))
    If Not _WinAPI_CreateProcess('', $sCMD, 0, 0, 0, 0x01000004, 0, 0, DllStructGetPtr($tStartup), DllStructGetPtr($tProcess)) Then
        Return SetError(1, _WinAPI_FreeHandle($hJob), 0)
    EndIf
    $hProcess = DllStructGetData($tProcess, 'hProcess')
    $hThread = DllStructGetData($tProcess, 'hThread')
    _WinAPI_AssignProcessToJobObject($hJob, $hProcess)
    _WinAPI_ResumeThread($hThread)
    _WinAPI_FreeHandle($hThread)
    Do
		Local $sMsg = GUIGetMsg()
		If $sMsg = $close_dlg or $sMsg = $GUI_EVENT_CLOSE Then
			GUISetState(@SW_ENABLE, $hWnd)
			GUISetState(@SW_RESTORE, $main_dlg)
			If $iNoGui = 0 Then GUIDelete($wait_dlg)
			ExitLoop
		EndIf
        If Not _WinAPI_QueryInformationJobObject($hJob, 1, $tInfo) Then
            ExitLoop
        EndIf
        Sleep(100)
    Until Not DllStructGetData($tInfo, 'ActiveProcesses')
	
	GUISetState(@SW_ENABLE, $hWnd)
	GUISetState(@SW_RESTORE, $main_dlg)
	If $iNoGui = 0 Then GUIDelete($wait_dlg)
		
    _WinAPI_FreeHandle($hProcess)
    _WinAPI_FreeHandle($hJob)
    Return 1
EndFunc

Func _Mutex($sMutex)
    Local $handle, $lastError
    $handle = DllCall("kernel32.dll", "int", "CreateMutex", "int", 0, "long", 1, "str", $sMutex)
    $lastError = DllCall("kernel32.dll", "int", "GetLastError")
    Return $lastError[0] = 183
EndFunc

Func WM_FINDREPLACE($hWnd, $iMsg, $iwParam, $ilParam)
	Local $sFindWhat, $fReverse = False, $fMatchCase = False, $iFlags = DllStructGetData($tFINDREPLACE, "Flags")
	$sFindWhat = DllStructGetData($tFindBuffer, 1)
	If BitAND($iFlags, $FR_FINDNEXT) Then
		If Not BitAND($iFlags, $FR_DOWN) Then $fReverse = True
		If BitAND($iFlags, $FR_MATCHCASE) Then $fMatchCase = True
		$find_text = $sFindWhat
		_FindSoftware($sFindWhat, $fReverse, $fMatchCase)
	EndIf
EndFunc

Func _FindSoftware($sText, $iReverse, $iMatchCase)
	Local $iStart = 0, $selected, $iFind
	If $sText = "" Then Return

	$selected = _GUICtrlListView_GetSelectedIndices($uninstall_lv, 1)

	If $selected[0] <> 0 Then
		$iStart = $selected[1]
	EndIf

	$iFind = _GUICtrlListView_FindInText($uninstall_lv, $sText, $iStart, 0, $iReverse)
	If $iFind = -1 Then
		MsgBox(64, "Поиск", "Поиск завершён", 0, $main_dlg)
	Else
		_GUICtrlListView_ClickItem($uninstall_lv, $iFind)
	EndIf
EndFunc 

Func WM_NOTIFY($hWnd, $iMsg, $iwParam, $ilParam)
    Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR, $hUninstall_lv
    $hUninstall_lv = $uninstall_lv
    If Not IsHWnd($uninstall_lv) Then $hUninstall_lv = GUICtrlGetHandle($uninstall_lv)

    $tNMITEMACTIVATE = DllStructCreate($tagNMITEMACTIVATE, $ilParam)
    $tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
    $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
    $Index = DllStructGetData($tNMITEMACTIVATE, 'Index')
    $iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
    $iCode = DllStructGetData($tNMHDR, "Code")
	$tInfo = DllStructCreate($tagNMLISTVIEW, $ilParam)
	$iItem = DllStructGetData($tInfo, "Item")
	
    Switch $hWndFrom
        Case $hUninstall_lv
            Switch $iCode
				 Case $NM_DBLCLK
					If $iItem <> -1 Then
						Local $sel = _GUICtrlListView_GetItemTextArray($uninstall_lv, $iItem)
						If $sel[0] <> 0 Then
							_PropertiesDlg($sel[5], $sel[7], $main_dlg)
						EndIf
					EndIf
                Case $NM_RCLICK
                    GUICtrlSendToDummy($Dummy, $Index)
			EndSwitch
	EndSwitch
    Return $GUI_RUNDEFMSG
EndFunc

Func WM_SIZE($hWnd, $iMsg, $iwParam, $ilParam)
	_GUICtrlListView_Arrange($uninstall_lv)
	_GUICtrlStatusBar_Resize($main_status)
	Local $aPos = WinGetClientSize($main_dlg)
	If not @error Then GUICtrlSetPos($uninstall_lv, 0, 0, $aPos[0] + 1, $aPos[1] - 28)
	Return $GUI_RUNDEFMSG
EndFunc