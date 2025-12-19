// Uninstall Manager
// Copyright (c) 2010-2025 Henry++

#include <global.h>

VOID NTAPI _app_dereferencecontext (
	_In_ PVOID entry
)
{
	PITEM_CONTEXT ptr_item;

	ptr_item = entry;

	if (ptr_item->file_path)
		_r_obj_dereference (ptr_item->file_path);

	if (ptr_item->display_icon)
		_r_obj_dereference (ptr_item->display_icon);

	if (ptr_item->install_location)
		_r_obj_dereference (ptr_item->install_location);

	if (ptr_item->key_path)
		_r_obj_dereference (ptr_item->key_path);

	if (ptr_item->name)
		_r_obj_dereference (ptr_item->name);
}

VOID _app_displayinfoapp_callback (
	_In_ PITEM_CONTEXT ptr_item,
	_Inout_ LPNMLVDISPINFOW lpnmlv
)
{
	// set text
	if (lpnmlv->item.mask & LVIF_TEXT)
	{
		switch (lpnmlv->item.iSubItem)
		{
			case 0:
			{
				_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, _r_obj_getstringordefault (ptr_item->name, L"n/a"));
				break;
			}

			case 1:
			{
				_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, _r_obj_getstringordefault (ptr_item->version, L"n/a"));
				break;
			}

			case 2:
			{
				PR_STRING string;

				string = _r_format_unixtime (ptr_item->timestamp, 0);

				_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, _r_obj_getstringordefault (string, L"n/a"));

				if (string)
					_r_obj_dereference (string);

				break;
			}

			case 3:
			{
				switch (ptr_item->installer)
				{
					case AdobeInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"Adobe Installer");

						break;
					}

					case AgentixInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"Agentix Installer");

						break;
					}

					case AstrumInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"Astrum Installer");

						break;
					}

					case BitrockInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"Bitrock Installer");

						break;
					}

					case ExcelsiorInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"Excelsior Installer");

						break;
					}

					case GhostInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"Ghost Installer");

						break;
					}

					case InnoSetupInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"Inno Setup");

						break;
					}

					case MicrosoftEdgeInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"Edge Installer");

						break;
					}

					case MssInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"Mss Installer");

						break;
					}

					case NsisInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"NSIS");

						break;
					}

					case SetupFactoryInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"Setup Factory");

						break;
					}

					case SmartInstallMakerInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"SmartInstallMaker");

						break;
					}

					case VisualStudioInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"Visual Studio Installer");

						break;
					}

					case WindowsInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"Windows Installer");

						break;
					}

					case WixInstaller:
					{
						_r_str_copy (lpnmlv->item.pszText, lpnmlv->item.cchTextMax, L"Wix Installer");

						break;
					}
				}

				break;
			}
		}
	}

	// set image
	if (lpnmlv->item.mask & LVIF_IMAGE)
	{
		lpnmlv->item.iImage = ptr_item->icon_id;
	}

	// set group id
	if (lpnmlv->item.mask & LVIF_GROUPID)
	{
		lpnmlv->item.iGroupId = ptr_item->is_hidden ? LV_HIDDEN_GROUP_ID : 0;
	}
}

INT CALLBACK _app_listviewcompare_callback (
	_In_ LPARAM lparam1,
	_In_ LPARAM lparam2,
	_In_ LPARAM lparam
)
{
	WCHAR config_name[128];
	PR_STRING item_text_1;
	PR_STRING item_text_2;
	HWND hlistview;
	HWND hwnd;
	INT listview_id;
	INT column_id;
	INT result = 0;
	INT item1;
	INT item2;
	BOOLEAN is_descend;

	item1 = (INT)(INT_PTR)lparam1;
	item2 = (INT)(INT_PTR)lparam2;

	if (item1 == INT_ERROR || item2 == INT_ERROR)
		return 0;

	hlistview = (HWND)lparam;

	hwnd = GetParent (hlistview);
	listview_id = GetDlgCtrlID (hlistview);

	_r_str_printf (config_name, RTL_NUMBER_OF (config_name), L"listview\\%04" TEXT (PRIX32), listview_id);

	column_id = _r_config_getlong (L"SortColumn", 0, config_name);

	item_text_1 = _r_listview_getitemtext (hwnd, listview_id, item1, column_id);
	item_text_2 = _r_listview_getitemtext (hwnd, listview_id, item2, column_id);

	is_descend = _r_config_getboolean (L"SortIsDescending", FALSE, config_name);

	if (item_text_1 && item_text_2)
	{
		if (!result)
			result = _r_str_compare_logical (item_text_1->buffer, item_text_2->buffer);
	}

	if (item_text_1)
		_r_obj_dereference (item_text_1);

	if (item_text_2)
		_r_obj_dereference (item_text_2);

	return is_descend ? -result : result;
}

VOID _app_listviewsort (
	_In_ HWND hwnd,
	_In_ INT listview_id,
	_In_ INT column_id,
	_In_ BOOLEAN is_notifycode
)
{
	WCHAR config_name[128];
	INT column_count;
	BOOLEAN is_descend;

	column_count = _r_listview_getcolumncount (hwnd, listview_id);

	if (!column_count)
		return;

	_r_str_printf (config_name, RTL_NUMBER_OF (config_name), L"listview\\%04" TEXT (PRIX32), listview_id);

	is_descend = _r_config_getboolean (L"SortIsDescending", FALSE, config_name);

	if (is_notifycode)
		is_descend = !is_descend;

	if (column_id == INT_ERROR)
		column_id = _r_config_getlong (L"SortColumn", 0, config_name);

	column_id = _r_calc_clamp (column_id, 0, column_count - 1); // set range

	if (is_notifycode)
	{
		_r_config_setboolean (L"SortIsDescending", is_descend, config_name);
		_r_config_setlong (L"SortColumn", column_id, config_name);
	}

	for (INT i = 0; i < column_count; i++)
		_r_listview_setcolumnsortindex (hwnd, listview_id, i, 0);

	_r_listview_setcolumnsortindex (hwnd, listview_id, column_id, is_descend ? -1 : 1);

	_r_listview_sort (hwnd, listview_id, &_app_listviewcompare_callback, (WPARAM)GetDlgItem (hwnd, listview_id));
}

BOOLEAN _app_isadminrigtsrequired (
	_In_ PITEM_CONTEXT context
)
{
	return (context->hroot == HKEY_LOCAL_MACHINE);
}

BOOLEAN _app_issystemcomponent (
	_In_ HANDLE hkey
)
{
	ULONG value;

	_r_reg_queryulong (hkey, L"SystemComponent", &value);

	return (value != 0);
}

BOOLEAN _app_issystemupdate (
	_In_ HANDLE hkey
)
{
	PR_STRING string;

	_r_reg_querystring (hkey, L"ParentKeyName", &string, NULL);

	if (string)
		_r_obj_dereference (string);

	return (string != NULL);
}

VOID NTAPI _app_getinfo (
	_In_ PVOID arglist
)
{
	PITEM_CONTEXT context;
	R_STORAGE storage;
	PR_STRING string;
	R_STRINGREF sr1;
	R_STRINGREF sr2;
	R_STRINGREF sr;
	HICON hicon = NULL;
	PVOID hinst;
	LCID lcid;
	ULONG_PTR pos;
	NTSTATUS status;

	context = arglist;

	if (context->display_icon)
	{
		_r_path_parsecommandlinefuzzy (&context->display_icon->sr, &sr, NULL, NULL);

		if (_r_fs_isdirectory (&sr) && context->uninstaller_path)
			_r_obj_initializestringref2 (&sr, &context->uninstaller_path->sr);

		pos = _r_str_findchar (&sr, L',', FALSE);

		if (pos != SIZE_MAX)
		{
			if (_r_str_splitatchar (&sr, L',', &sr1, &sr2))
				hicon = _r_sys_extracticon (&sr1, _r_str_tolong (&sr2), 16);
		}
		else
		{
			_r_path_geticon (&sr, &hicon, NULL);
		}

		if (hicon)
		{
			_r_imagelist_addicon (config.himg_listview, hicon, &context->icon_id);

			DestroyIcon (hicon);
		}
	}
	else
	{
		context->icon_id = config.icon_id;
	}

	if (context->installer == InstallerUnknown && context->uninstaller_path)
	{
		status = _r_sys_loadlibraryasresource (&context->uninstaller_path->sr, &hinst);

		if (NT_SUCCESS (status))
		{
			status = _r_res_loadresource (hinst, RT_VERSION, MAKEINTRESOURCE (VS_VERSION_INFO), 0, &storage);

			if (NT_SUCCESS (status))
			{
				lcid = _r_res_querytranslation (storage.buffer);

				// get file description
				string = _r_res_querystring (storage.buffer, L"FileDescription", lcid);

				if (string)
				{
					if (_r_str_isequal2 (&string->sr, L"Microsoft Edge Installer", FALSE))
					{
						context->installer = MicrosoftEdgeInstaller;
					}
					else if (_r_str_isequal2 (&string->sr, L"Visual Studio Installer", FALSE))
					{
						context->installer = VisualStudioInstaller;
					}

					_r_obj_dereference (string);
				}
			}

			if (context->installer == InstallerUnknown)
			{
				status = _r_res_loadresource (hinst, RT_MANIFEST, MAKEINTRESOURCE (1), 0, &storage);

				if (NT_SUCCESS (status))
				{
					status = _r_str_multibyte2unicode ((PR_BYTEREF)&storage, &string);

					if (NT_SUCCESS (status))
					{
						if (_r_str_findstring2 (&string->sr, L"Inno Setup", TRUE) != SIZE_MAX)
						{
							context->installer = InnoSetupInstaller;
						}
						else if (_r_str_findstring2 (&string->sr, L"Nullsoft Install System", TRUE) != SIZE_MAX)
						{
							context->installer = NsisInstaller;
						}
						else if (_r_str_findstring2 (&string->sr, L"WiX Toolset Bootstrapper", TRUE) != SIZE_MAX)
						{
							context->installer = WixInstaller;
						}

						_r_obj_dereference (string);
					}
				}
			}

			_r_sys_freelibrary (hinst);
		}
	}
}

VOID _app_additem (
	_In_ HWND hwnd,
	_In_ HANDLE hroot,
	_In_ LPWSTR key_path,
	_In_ PR_STRING name,
	_In_ HANDLE hkey,
	_In_ LONG64 timestamp
)
{
	PITEM_CONTEXT context;
	PR_STRING uninstall_string;
	PR_STRING install_location;
	PR_STRING display_version;
	PR_STRING display_name;
	PR_STRING display_icon;
	R_STRINGREF sr;
	ULONG value;
	NTSTATUS status;

	if (_app_issystemcomponent (hkey) && !_r_config_getboolean (L"IsShowComponents", FALSE, NULL))
		return;

	if (_app_issystemupdate (hkey) && !_r_config_getboolean (L"IsShowUpdates", FALSE, NULL))
		return;

	status = _r_reg_querystring (hkey, L"DisplayName", &display_name, NULL);

	if (!NT_SUCCESS (status))
		return;

	_r_reg_querystring (hkey, L"DisplayIcon", &display_icon, NULL);
	_r_reg_querystring (hkey, L"DisplayVersion", &display_version, NULL);
	_r_reg_querystring (hkey, L"InstallLocation", &install_location, NULL);
	_r_reg_querystring (hkey, L"UninstallString", &uninstall_string, NULL);

	context = _r_obj_allocate (sizeof (ITEM_CONTEXT), &_app_dereferencecontext);

	context->hroot = hroot;
	context->key_path = _r_format_string (L"%s\\%s", key_path, name->buffer);

	context->name = display_name;
	context->version = display_version;
	context->display_icon = display_icon;
	context->install_location = install_location;
	context->uninstall_string = uninstall_string;
	context->timestamp = timestamp;

	if (context->uninstall_string)
	{
		if (_r_path_parsecommandlinefuzzy (&context->uninstall_string->sr, &sr, NULL, NULL))
			context->uninstaller_path = _r_obj_createstring2 (&sr);
	}

	if (context->install_location)
		_r_str_trimstring2 (&context->install_location->sr, L"\"", 0);

	status = _r_reg_queryulong (hkey, L"WindowsInstaller", &value);

	if (NT_SUCCESS (status) && value != 0)
		context->installer = WindowsInstaller;

	_r_listview_additem (hwnd, IDC_LISTVIEW, INT_ERROR, LPSTR_TEXTCALLBACK, I_IMAGECALLBACK, I_GROUPIDCALLBACK, (LPARAM)context);

	_r_workqueue_queueitem (&workqueue, &_app_getinfo, context);
}

VOID _app_resizecolumns (
	_In_ HWND hwnd
)
{
	_r_listview_setcolumn (hwnd, IDC_LISTVIEW, 0, NULL, -50);
	_r_listview_setcolumn (hwnd, IDC_LISTVIEW, 1, NULL, -15);
	_r_listview_setcolumn (hwnd, IDC_LISTVIEW, 2, NULL, -20);
	_r_listview_setcolumn (hwnd, IDC_LISTVIEW, 3, NULL, -15);
}

VOID _app_scansubkeys (
	_In_ HWND hwnd,
	_In_ HANDLE hroot,
	_In_ LPWSTR key_path
)
{
	HANDLE hsubkey;
	HANDLE hkey;
	PR_STRING name;
	LONG64 timestamp;
	ULONG index = 0;
	NTSTATUS status;

	status = _r_reg_openkey (hroot, key_path, 0, KEY_READ, &hkey);

	if (NT_SUCCESS (status))
	{
		while (TRUE)
		{
			status = _r_reg_enumkey (hkey, index, &name, &timestamp);

			// STATUS_NO_MORE_ENTRIES
			if (status != STATUS_SUCCESS)
				break;

			status = _r_reg_openkey (hkey, name->buffer, 0, KEY_READ, &hsubkey);

			if (NT_SUCCESS (status))
			{
				_app_additem (hwnd, hroot, key_path, name, hsubkey, timestamp);

				_r_obj_dereference (name);

				NtClose (hsubkey);
			}

			index += 1;
		}

		NtClose (hkey);
	}
}

VOID _app_refreshitems (
	_In_ HWND hwnd
)
{
	_app_scansubkeys (hwnd, HKEY_CURRENT_USER, L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall");
	_app_scansubkeys (hwnd, HKEY_CURRENT_USER, L"SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall");
	_app_scansubkeys (hwnd, HKEY_LOCAL_MACHINE, L"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall");
	_app_scansubkeys (hwnd, HKEY_LOCAL_MACHINE, L"SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall");

	_app_listviewsort (hwnd, IDC_LISTVIEW, 0, false);
}

VOID _app_toolbar_resize (
	_In_ HWND hwnd
)
{
	REBARBANDINFOW rbi;
	SIZE ideal_size = {0};
	ULONG button_size;
	ULONG rebar_count;
	LONG dpi_value;

	_r_toolbar_resize (config.htoolbar, 0);

	rebar_count = _r_rebar_getcount (config.hrebar, 0);

	dpi_value = _r_dc_getdpivalue (hwnd, NULL);

	for (ULONG i = 0; i < rebar_count; i++)
	{
		RtlZeroMemory (&rbi, sizeof (REBARBANDINFOW));

		rbi.cbSize = sizeof (REBARBANDINFOW);
		rbi.fMask = RBBIM_ID | RBBIM_CHILD | RBBIM_IDEALSIZE | RBBIM_CHILDSIZE;

		if (!_r_rebar_getinfo (config.hrebar, 0, i, &rbi))
			continue;

		if (rbi.wID == REBAR_TOOLBAR_ID)
		{
			if (!_r_toolbar_getidealsize (config.htoolbar, 0, FALSE, &ideal_size))
				continue;

			button_size = _r_toolbar_getbuttonsize (config.hrebar, IDC_TOOLBAR);

			rbi.cxIdeal = (UINT)ideal_size.cx;
			rbi.cxMinChild = LOWORD (button_size);
			rbi.cyMinChild = HIWORD (button_size);
		}
		else if (rbi.wID == REBAR_SEARCH_ID)
		{
			if (_r_wnd_isvisible (rbi.hwndChild, FALSE))
			{
				rbi.cxIdeal = (UINT)_r_dc_getdpi (180, dpi_value);
			}
			else
			{
				rbi.cxIdeal = 0;
			}

			rbi.cxMinChild = rbi.cxIdeal;
			rbi.cyMinChild = 20;
		}
		else
		{
			continue;
		}

		_r_rebar_setinfo (config.hrebar, 0, i, &rbi);
	}

	_r_wnd_sendmessage (config.hrebar, 0, WM_SIZE, 0, 0);
}

VOID _app_window_resize (
	_In_ HWND hwnd,
	_In_ LPCRECT rect,
	_In_ LONG dpi_value
)
{
	HDWP hdefer;
	LONG statusbar_height;
	LONG rebar_height;

	_app_toolbar_resize (hwnd);

	_r_wnd_sendmessage (config.hrebar, 0, WM_SIZE, 0, 0);
	_r_wnd_sendmessage (hwnd, IDC_STATUSBAR, WM_SIZE, 0, 0);

	rebar_height = _r_rebar_getheight (hwnd, IDC_REBAR);
	statusbar_height = _r_status_getheight (hwnd, IDC_STATUSBAR);

	hdefer = BeginDeferWindowPos (2);

	if (hdefer)
	{
		hdefer = DeferWindowPos (
			hdefer,
			config.hrebar,
			NULL,
			0,
			0,
			rect->right,
			rebar_height,
			SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOOWNERZORDER
		);

		hdefer = DeferWindowPos (
			hdefer,
			GetDlgItem (hwnd, IDC_LISTVIEW),
			NULL,
			0,
			rebar_height,
			rect->right,
			rect->bottom - rebar_height - statusbar_height,
			SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOOWNERZORDER
		);

		EndDeferWindowPos (hdefer);
	}
}

VOID _app_toolbar_init (
	_In_ HWND hwnd
)
{
	ULONG images_id[] = {
		IDP_DELETE,
		IDP_REFRESH,
		IDP_DONATE,
	};

	NONCLIENTMETRICS ncm = {0};
	HBITMAP hbitmap;
	HICON hicon;
	ULONG button_size;
	ULONG dpi_value;
	ULONG width;
	NTSTATUS status;

	config.hrebar = GetDlgItem (hwnd, IDC_REBAR);

	config.htoolbar = CreateWindowExW (
		0,
		TOOLBARCLASSNAMEW,
		NULL,
		WS_CHILD | WS_VISIBLE | CCS_NOPARENTALIGN | CCS_NODIVIDER | TBSTYLE_FLAT | TBSTYLE_LIST | TBSTYLE_TRANSPARENT | TBSTYLE_TOOLTIPS | TBSTYLE_AUTOSIZE,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		config.hrebar,
		(HMENU)IDC_TOOLBAR,
		_r_sys_getimagebase (),
		NULL
	);

	ncm.cbSize = sizeof (NONCLIENTMETRICS);

	dpi_value = _r_dc_getwindowdpi (hwnd);

	if (_r_dc_getsystemparametersinfo (SPI_GETNONCLIENTMETRICS, ncm.cbSize, &ncm, dpi_value))
	{
		SAFE_DELETE_OBJECT (config.wnd_font);

		config.wnd_font = CreateFontIndirectW (&ncm.lfMessageFont);
	}

	if (config.htoolbar)
	{
		width = _r_dc_getsystemmetrics (SM_CXSMICON, dpi_value);

		_r_imagelist_create (width, width, ILC_COLOR32 | ILC_HIGHQUALITYSCALE, 0, 5, &config.himg_toolbar);

		for (ULONG_PTR i = 0; i < RTL_NUMBER_OF (images_id); i++)
		{
			status = _r_res_loadimage (_r_sys_getimagebase (), L"PNG", MAKEINTRESOURCE (images_id[i]), &GUID_ContainerFormatPng, width, width, &hbitmap);

			if (NT_SUCCESS (status))
			{
				hicon = _r_dc_bitmaptoicon (hbitmap, width, width);

				if (hicon)
					_r_imagelist_addicon (config.himg_toolbar, hicon, NULL);
			}
		}

		if (!_r_sys_iselevated ())
		{
			config.hbitmap_uac = _r_dc_getuacshield (dpi_value, 0, 0, FALSE);

			hicon = _r_dc_getuacshield (dpi_value, 0, 0, TRUE);

			if (hicon)
			{
				_r_imagelist_addicon (config.himg_toolbar, hicon, NULL);

				DestroyIcon (hicon);
			}
		}

		_r_toolbar_setstyle (config.hrebar, IDC_TOOLBAR, TBSTYLE_EX_MIXEDBUTTONS | TBSTYLE_EX_DOUBLEBUFFER | TBSTYLE_EX_HIDECLIPPEDBUTTONS);

		_r_ctrl_setfont (config.htoolbar, 0, config.wnd_font); // fix font

		_r_toolbar_setimagelist (config.htoolbar, 0, config.himg_toolbar);

		_r_toolbar_addbutton (config.hrebar, IDC_TOOLBAR, IDM_UNINSTALL, BTNS_BUTTON | BTNS_AUTOSIZE, NULL, TBSTATE_ENABLED, 0);

		_r_toolbar_addseparator (config.hrebar, IDC_TOOLBAR);

		_r_toolbar_addbutton (config.hrebar, IDC_TOOLBAR, IDM_REFRESH, BTNS_BUTTON | BTNS_AUTOSIZE, NULL, TBSTATE_ENABLED, 1);

		_r_toolbar_addseparator (config.hrebar, IDC_TOOLBAR);

		_r_toolbar_addbutton (config.hrebar, IDC_TOOLBAR, IDM_DONATE, BTNS_BUTTON | BTNS_AUTOSIZE, NULL, TBSTATE_ENABLED, 2);

		if (!_r_sys_iselevated ())
		{
			_r_toolbar_addseparator (config.hrebar, IDC_TOOLBAR);

			_r_toolbar_addbutton (config.hrebar, IDC_TOOLBAR, IDM_RUNASADMIN, BTNS_BUTTON | BTNS_AUTOSIZE, NULL, TBSTATE_ENABLED, 3);
		}

		_r_toolbar_resize (config.hrebar, IDC_TOOLBAR);

		// insert toolbar
		button_size = _r_toolbar_getbuttonsize (config.hrebar, IDC_TOOLBAR);

		_r_rebar_insertband (hwnd, IDC_REBAR, REBAR_TOOLBAR_ID, config.htoolbar, RBBS_VARIABLEHEIGHT | RBBS_NOGRIPPER | RBBS_USECHEVRON, LOWORD (button_size), HIWORD (button_size));
	}

	// insert searchbar
	config.hsearchbar = CreateWindowExW (
		WS_EX_CLIENTEDGE,
		WC_EDITW,
		NULL,
		WS_CHILD | WS_CLIPSIBLINGS | WS_CLIPCHILDREN | ES_LEFT | ES_AUTOHSCROLL,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		CW_USEDEFAULT,
		config.hrebar,
		(HMENU)IDC_SEARCH,
		_r_sys_getimagebase (),
		NULL
	);

	if (!config.hsearchbar)
		return;

	_r_ctrl_setfont (config.hsearchbar, 0, config.wnd_font); // fix font

	_app_search_create (config.hsearchbar);

	_app_search_setvisible (hwnd, config.hsearchbar, _r_dc_getdpivalue (hwnd, NULL));
}

VOID _app_initialize (
	_In_ HWND hwnd
)
{
	R_STRINGREF msiexec_sr = PR_STRINGREF_INIT (L"msiexec.exe");
	PR_STRING path;
	HICON hicon;
	LONG dpi_value;
	LONG icon_size;
	NTSTATUS status;

	_r_app_sethwnd (hwnd); // HACK!!!

	// initialize toolbar
	_app_toolbar_init (hwnd);

	// initialzie workqueue
	_r_workqueue_initialize (&workqueue, 12, NULL, L"InstallerInfoCatch");

	// create imagelist
	dpi_value = _r_dc_getwindowdpi (hwnd);

	icon_size = _r_dc_getsystemmetrics (SM_CXSMICON, dpi_value);

	_r_imagelist_create (icon_size, icon_size, ILC_COLOR32 | ILC_HIGHQUALITYSCALE, 0, 5, &config.himg_listview);

	_r_listview_setimagelist (hwnd, IDC_LISTVIEW, config.himg_listview);

	// initialize icon
	status = _r_path_search (NULL, &msiexec_sr, NULL, &path);

	if (NT_SUCCESS (status))
	{
		_r_path_geticon (&path->sr, &hicon, NULL);

		if (hicon)
		{
			_r_imagelist_addicon (config.himg_listview, hicon, &config.icon_id);

			DestroyIcon (hicon);
		}

		_r_obj_dereference (path);
	}

	// configure listview
	_r_listview_setstyle (hwnd, IDC_LISTVIEW, LVS_EX_DOUBLEBUFFER | LVS_EX_FULLROWSELECT | LVS_EX_INFOTIP | LVS_EX_LABELTIP, TRUE);

	_r_listview_addcolumn (hwnd, IDC_LISTVIEW, 0, NULL, 10, LVCFMT_LEFT);
	_r_listview_addcolumn (hwnd, IDC_LISTVIEW, 1, NULL, 10, LVCFMT_LEFT);
	_r_listview_addcolumn (hwnd, IDC_LISTVIEW, 2, NULL, 10, LVCFMT_LEFT);
	_r_listview_addcolumn (hwnd, IDC_LISTVIEW, 3, NULL, 10, LVCFMT_LEFT);

	_r_listview_addgroup (hwnd, IDC_LISTVIEW, 0, NULL, 0, LVGS_NOHEADER, LVGS_NOHEADER);
	_r_listview_addgroup (hwnd, IDC_LISTVIEW, LV_HIDDEN_GROUP_ID, L"", 0, LVGS_HIDDEN | LVGS_NOHEADER | LVGS_COLLAPSED, LVGS_HIDDEN | LVGS_NOHEADER | LVGS_COLLAPSED);

	_app_refreshitems (hwnd);

	_app_resizecolumns (hwnd);
}

INT_PTR CALLBACK DlgProc (
	_In_ HWND hwnd,
	_In_ UINT msg,
	_In_ WPARAM wparam,
	_In_ LPARAM lparam
)
{
	static R_LAYOUT_MANAGER layout_manager = {0};

	switch (msg)
	{
		case WM_INITDIALOG:
		{
			_app_initialize (hwnd);

			_r_layout_initializemanager (&layout_manager, hwnd);

			break;
		}

		case WM_DESTROY:
		{
			PostQuitMessage (0);
			break;
		}

		case RM_INITIALIZE:
		{
			HMENU hmenu;

			hmenu = GetMenu (hwnd);

			if (hmenu)
			{
				_r_menu_checkitem (hmenu, IDM_SHOW_UPDATES, 0, MF_BYCOMMAND, _r_config_getboolean (L"IsShowUpdates", FALSE, NULL));
				_r_menu_checkitem (hmenu, IDM_SHOW_SYSTEM_COMPONENTS, 0, MF_BYCOMMAND, _r_config_getboolean (L"IsShowComponents", FALSE, NULL));
				_r_menu_checkitem (hmenu, IDM_ALWAYSONTOP_CHK, 0, MF_BYCOMMAND, _r_config_getboolean (L"AlwaysOnTop", FALSE, NULL));
				_r_menu_checkitem (hmenu, IDM_DARKMODE_CHK, 0, MF_BYCOMMAND, _r_theme_isenabled ());
				_r_menu_checkitem (hmenu, IDM_SKIPUACWARNING_CHK, 0, MF_BYCOMMAND, _r_skipuac_isenabled ());
				_r_menu_checkitem (hmenu, IDM_CHECKUPDATES_CHK, 0, MF_BYCOMMAND, _r_update_isenabled (FALSE));
			}

			break;
		}

		case RM_LOCALIZE:
		{
			// localize menu
			HMENU hmenu;

			hmenu = GetMenu (hwnd);

			if (hmenu)
			{
				_r_menu_setitemtext (hmenu, 0, TRUE, _r_locale_getstring (IDS_FILE));
				_r_menu_setitemtext (hmenu, 1, TRUE, _r_locale_getstring (IDS_VIEW));
				_r_menu_setitemtext (hmenu, 2, TRUE, _r_locale_getstring (IDS_SETTINGS));
				_r_menu_setitemtext (hmenu, 3, TRUE, _r_locale_getstring (IDS_HELP));

				_r_menu_setitemtextformat (hmenu, IDM_SAVE_HTML, FALSE, L"%s...\tF2", _r_locale_getstring (IDS_SAVE_HTML));
				_r_menu_setitemtextformat (hmenu, IDM_SETTINGS, FALSE, L"%s...\tF2", _r_locale_getstring (IDS_SETTINGS));
				_r_menu_setitemtextformat (hmenu, IDM_EXIT, FALSE, L"%s...\tEsc", _r_locale_getstring (IDS_EXIT));
				_r_menu_setitemtext (hmenu, IDM_SHOW_UPDATES, FALSE, _r_locale_getstring (IDS_SHOW_UPDATES));
				_r_menu_setitemtext (hmenu, IDM_SHOW_SYSTEM_COMPONENTS, FALSE, _r_locale_getstring (IDS_SHOW_SYSTEM_COMPONENTS));
				_r_menu_setitemtextformat (hmenu, IDM_REFRESH, FALSE, L"%s...\tF5", _r_locale_getstring (IDS_REFRESH));
				_r_menu_setitemtext (hmenu, IDM_ALWAYSONTOP_CHK, FALSE, _r_locale_getstring (IDS_ALWAYSONTOP_CHK));
				_r_menu_setitemtext (hmenu, IDM_DARKMODE_CHK, FALSE, _r_locale_getstring (IDS_DARKMODE_CHK));
				_r_menu_setitemtext (hmenu, IDM_SKIPUACWARNING_CHK, FALSE, _r_locale_getstring (IDS_SKIPUACWARNING_CHK));
				_r_menu_setitemtext (hmenu, IDM_CHECKUPDATES_CHK, FALSE, _r_locale_getstring (IDS_CHECKUPDATES_CHK));
				_r_menu_setitemtextformat (GetSubMenu (hmenu, LANG_SUBMENU), LANG_MENU, TRUE, L"%s (Language)", _r_locale_getstring (IDS_LANGUAGE));
				_r_menu_setitemtext (hmenu, IDM_WEBSITE, FALSE, _r_locale_getstring (IDS_WEBSITE));
				_r_menu_setitemtext (hmenu, IDM_CHECKUPDATES, FALSE, _r_locale_getstring (IDS_CHECKUPDATES));
				_r_menu_setitemtextformat (hmenu, IDM_ABOUT, FALSE, L"%s\tF1", _r_locale_getstring (IDS_ABOUT));
			}

			_r_toolbar_setbutton (config.hrebar, IDC_TOOLBAR, IDM_UNINSTALL, _r_locale_getstring (IDS_UNINSTALL), BTNS_BUTTON | BTNS_AUTOSIZE | BTNS_SHOWTEXT, 0, I_IMAGENONE);
			_r_toolbar_setbutton (config.hrebar, IDC_TOOLBAR, IDM_REFRESH, _r_locale_getstring (IDS_REFRESH), BTNS_BUTTON | BTNS_AUTOSIZE | BTNS_SHOWTEXT, 0, I_IMAGENONE);
			_r_toolbar_setbutton (config.hrebar, IDC_TOOLBAR, IDM_DONATE, _r_locale_getstring (IDS_DONATE), BTNS_BUTTON | BTNS_AUTOSIZE, 0, I_IMAGENONE);
			_r_toolbar_setbutton (config.hrebar, IDC_TOOLBAR, IDM_RUNASADMIN, _r_locale_getstring (IDS_RUNASADMIN), BTNS_BUTTON | BTNS_AUTOSIZE, 0, I_IMAGENONE);

			_r_listview_setcolumn (hwnd, IDC_LISTVIEW, 0, _r_locale_getstring (IDS_NAME), 0);
			_r_listview_setcolumn (hwnd, IDC_LISTVIEW, 1, _r_locale_getstring (IDS_VERSION), 0);
			_r_listview_setcolumn (hwnd, IDC_LISTVIEW, 2, _r_locale_getstring (IDS_TIMESTAMP), 0);
			_r_listview_setcolumn (hwnd, IDC_LISTVIEW, 3, _r_locale_getstring (IDS_INSTALLER), 0);

			// enum localizations
			if (hmenu)
				_r_locale_enum (GetSubMenu (hmenu, LANG_SUBMENU), LANG_MENU, IDX_LANGUAGE);

			break;
		}

		case WM_SIZE:
		{
			RECT rect;
			LONG dpi_value;

			if (!GetClientRect (hwnd, &rect))
				break;

			dpi_value = _r_dc_getwindowdpi (hwnd);

			_app_window_resize (hwnd, &rect, dpi_value);

			break;
		}

		case WM_GETMINMAXINFO:
		{
			_r_layout_resizeminimumsize (&layout_manager, lparam);
			break;
		}

		case WM_DPICHANGED:
		{
			_app_resizecolumns (hwnd);
			break;
		}

		case WM_NOTIFY:
		{
			LPNMHDR nmlp;

			nmlp = (LPNMHDR)lparam;

			switch (nmlp->code)
			{
				case NM_RCLICK:
				{
					LPNMITEMACTIVATE lpnmlv;
					HMENU hmenu;
					HMENU hsubmenu;
					INT command_id;

					lpnmlv = (LPNMITEMACTIVATE)lparam;

					if (lpnmlv->hdr.idFrom != IDC_LISTVIEW || lpnmlv->iItem == INT_ERROR)
						break;

					// localize
					hmenu = LoadMenuW (NULL, MAKEINTRESOURCEW (IDM_LISTVIEW));

					if (!hmenu)
						break;

					hsubmenu = GetSubMenu (hmenu, 0);

					if (hsubmenu)
					{
						_r_menu_setitemtext (hsubmenu, IDM_UNINSTALL, FALSE, _r_locale_getstring (IDS_UNINSTALL));
						_r_menu_setitemtextformat (hsubmenu, IDM_DELETE, FALSE, L"%s\tDel", _r_locale_getstring (IDS_DELETE));
						_r_menu_setitemtextformat (hsubmenu, IDM_EXPLORE, FALSE, L"%s\tCtrl+E", _r_locale_getstring (IDS_EXPLORE));
						_r_menu_setitemtext (hsubmenu, IDM_OPEN, FALSE, _r_locale_getstring (IDS_OPEN));
						_r_menu_setitemtext (hsubmenu, IDM_COPY, FALSE, _r_locale_getstring (IDS_COPY));
						_r_menu_setitemtext (hsubmenu, IDM_COPY_VALUE, FALSE, _r_locale_getstring (IDS_COPY_VALUE));

						if (config.hbitmap_uac)
							_r_menu_setitembitmap (hsubmenu, IDM_OPEN, FALSE, config.hbitmap_uac);

						command_id = _r_menu_popup (hsubmenu, hwnd, NULL, FALSE);

						if (command_id)
							_r_ctrl_sendcommand (hwnd, command_id, (LPARAM)lpnmlv->iSubItem);
					}

					DestroyMenu (hmenu);

					break;
				}

				case NM_CUSTOMDRAW:
				{
					LPNMLVCUSTOMDRAW lpnmlv;
					LONG_PTR result = CDRF_DODEFAULT;

					if (nmlp->idFrom != IDC_LISTVIEW)
						break;

					lpnmlv = (LPNMLVCUSTOMDRAW)lparam;

					switch (lpnmlv->nmcd.dwDrawStage)
					{
						case CDDS_PREPAINT:
						{
							result = CDRF_NOTIFYITEMDRAW;
							break;
						}

						//case CDDS_ITEMPREPAINT:
						//{
						//	PITEM_CONTEXT ptr_item;
						//	COLORREF new_clr;
						//
						//	if (lpnmlv->dwItemType != LVCDI_ITEM)
						//		break;
						//
						//	if (!_r_config_getboolean (L"IsEnableHighlighting", TRUE, NULL))
						//		break;
						//
						//	ptr_item = (PITEM_CONTEXT)lpnmlv->nmcd.lItemlParam;
						//
						//	if (!ptr_item)
						//		break;
						//
						//	new_clr = ptr_item->clr;
						//
						//	lpnmlv->clrTextBk = new_clr;
						//	lpnmlv->clrText = _r_theme_isenabled () ? WND_TEXT_CLR : _r_dc_getcolorbrightness (new_clr);
						//
						//	result = CDRF_NEWFONT;
						//
						//	break;
						//}
					}

					SetWindowLongPtrW (hwnd, DWLP_MSGRESULT, result);

					return result;
				}

				case NM_DBLCLK:
				{
					LPNMITEMACTIVATE lpnmlv;

					lpnmlv = (LPNMITEMACTIVATE)lparam;

					if (lpnmlv->iItem == INT_ERROR)
						break;

					_r_ctrl_sendcommand (hwnd, IDM_EXPLORE, 0);

					break;
				}

				case LVN_COLUMNCLICK:
				{
					LPNMLISTVIEW lpnmlv;
					INT ctrl_id;

					lpnmlv = (LPNMLISTVIEW)lparam;
					ctrl_id = (INT)(INT_PTR)lpnmlv->hdr.idFrom;

					if (ctrl_id != IDC_LISTVIEW)
						break;

					_app_listviewsort (hwnd, ctrl_id, lpnmlv->iSubItem, TRUE);

					break;
				}

				case LVN_DELETEITEM:
				{
					LPNMLISTVIEW lpnmlv;

					lpnmlv = (LPNMLISTVIEW)lparam;

					if (lpnmlv->lParam)
						_r_obj_dereference ((PVOID)lpnmlv->lParam);

					_app_resizecolumns (hwnd);

					break;
				}

				case LVN_GETDISPINFO:
				{
					LPNMLVDISPINFOW lpnmlv;
					INT listview_id;

					lpnmlv = (LPNMLVDISPINFOW)lparam;
					listview_id = (INT)(INT_PTR)lpnmlv->hdr.idFrom;

					if (!lpnmlv->item.lParam)
						break;

					_app_displayinfoapp_callback ((PITEM_CONTEXT)lpnmlv->item.lParam, lpnmlv);

					break;
				}

				case LVN_GETEMPTYMARKUP:
				{
					NMLVEMPTYMARKUP* lpnmlv = (NMLVEMPTYMARKUP*)lparam;

					lpnmlv->dwFlags = EMF_CENTERED;

					_r_str_copy (lpnmlv->szMarkup, RTL_NUMBER_OF (lpnmlv->szMarkup), _r_locale_getstring (IDS_STATUS_EMPTY));

					SetWindowLongPtrW (hwnd, DWLP_MSGRESULT, TRUE);

					return TRUE;
				}
			}

			break;
		}

		case WM_COMMAND:
		{
			INT ctrl_id = LOWORD (wparam);
			INT notify_code = HIWORD (wparam);

			if (notify_code == EN_CHANGE)
			{
				PR_STRING string;

				if (ctrl_id != IDC_SEARCH)
					break;

				string = _r_ctrl_getstring (config.hrebar, IDC_SEARCH);

				_r_obj_movereference ((PVOID_PTR)&config.search_string, string);

				_app_search_applyfilter (hwnd, IDC_LISTVIEW, string);

				return 0;
			}
			else if (notify_code == 0 && ctrl_id >= IDX_LANGUAGE && ctrl_id <= IDX_LANGUAGE + (INT)(INT_PTR)_r_locale_getcount () + 1)
			{
				HMENU hsubmenu;
				HMENU hmenu;

				hmenu = GetMenu (hwnd);

				if (hmenu)
				{
					hsubmenu = GetSubMenu (GetSubMenu (hmenu, LANG_SUBMENU), LANG_MENU);

					if (hsubmenu)
						_r_locale_apply (hsubmenu, ctrl_id, IDX_LANGUAGE);
				}

				return FALSE;
			}

			switch (ctrl_id)
			{
				case IDCANCEL: // process Esc key
				case IDM_EXIT:
				{
					DestroyWindow (hwnd);
					break;
				}

				case IDM_SHOW_UPDATES:
				{
					BOOLEAN new_val;

					new_val = !_r_config_getboolean (L"IsShowUpdates", FALSE, NULL);

					_r_menu_checkitem (GetMenu (hwnd), ctrl_id, 0, MF_BYCOMMAND, new_val);
					_r_config_setboolean (L"IsShowUpdates", new_val, NULL);

					_app_refreshitems (hwnd);

					break;
				}

				case IDM_SHOW_SYSTEM_COMPONENTS:
				{
					BOOLEAN new_val;

					new_val = !_r_config_getboolean (L"IsShowComponents", FALSE, NULL);

					_r_menu_checkitem (GetMenu (hwnd), ctrl_id, 0, MF_BYCOMMAND, new_val);
					_r_config_setboolean (L"IsShowComponents", new_val, NULL);

					_app_refreshitems (hwnd);

					break;
				}

				case IDM_REFRESH:
				{
					_app_refreshitems (hwnd);
					break;
				}

				case IDM_ALWAYSONTOP_CHK:
				{
					BOOLEAN new_val;

					new_val = !_r_config_getboolean (L"AlwaysOnTop", FALSE, NULL);

					_r_menu_checkitem (GetMenu (hwnd), ctrl_id, 0, MF_BYCOMMAND, new_val);
					_r_config_setboolean (L"AlwaysOnTop", new_val, NULL);

					_r_wnd_top (hwnd, new_val);

					break;
				}

				case IDM_DARKMODE_CHK:
				{
					BOOLEAN is_enabled = !_r_theme_isenabled ();

					_r_menu_checkitem (GetMenu (hwnd), ctrl_id, 0, MF_BYCOMMAND, is_enabled);
					_r_theme_enable (hwnd, is_enabled);

					break;
				}

				case IDM_SKIPUACWARNING_CHK:
				{
					BOOLEAN new_val;

					new_val = !_r_skipuac_isenabled ();

					_r_skipuac_enable (hwnd, new_val);
					_r_menu_checkitem (GetMenu (hwnd), ctrl_id, 0, MF_BYCOMMAND, _r_skipuac_isenabled ());

					break;
				}

				case IDM_CHECKUPDATES_CHK:
				{
					BOOLEAN new_val;

					new_val = !_r_update_isenabled (FALSE);

					_r_menu_checkitem (GetMenu (hwnd), ctrl_id, 0, MF_BYCOMMAND, new_val);
					_r_update_enable (new_val);

					break;
				}

				case IDM_DONATE:
				{
					_r_shell_opendefault (_r_app_getdonate_url ());
					break;
				}

				case IDM_RUNASADMIN:
				{
					_r_app_runasadmin ();
					break;
				}

				//case IDM_SETTINGS:
				//case IDM_TRAY_SETTINGS:
				//{
				//	_r_settings_createwindow (hwnd, &SettingsProc, 0);
				//	break;
				//}

				case IDM_WEBSITE:
				{
					_r_shell_opendefault (_r_app_getwebsite_url ());
					break;
				}

				case IDM_CHECKUPDATES:
				{
					_r_update_check (hwnd);
					break;
				}

				case IDM_ABOUT:
				{
					_r_show_aboutmessage (hwnd);
					break;
				}

				case IDM_EXPLORE:
				{
					PITEM_CONTEXT ptr_item;
					INT item_id = INT_ERROR;

					while ((item_id = _r_listview_getnextselected (hwnd, IDC_LISTVIEW, item_id)) != INT_ERROR)
					{
						ptr_item = (PITEM_CONTEXT)_r_listview_getitemlparam (hwnd, IDC_LISTVIEW, item_id);

						if (ptr_item)
						{
							if (ptr_item->install_location)
								_r_shell_showfile (&ptr_item->install_location->sr);
						}
					}

					break;
				}

				case IDM_OPEN:
				{
					PITEM_CONTEXT ptr_item;
					HANDLE hkey;
					INT item_id = INT_ERROR;
					NTSTATUS status;

					while ((item_id = _r_listview_getnextselected (hwnd, IDC_LISTVIEW, item_id)) != INT_ERROR)
					{
						ptr_item = (PITEM_CONTEXT)_r_listview_getitemlparam (hwnd, IDC_LISTVIEW, item_id);

						if (ptr_item)
						{
							status = _r_reg_openkey (ptr_item->hroot, ptr_item->key_path->buffer, 0, KEY_READ, &hkey);

							if (NT_SUCCESS (status))
							{
								_r_shell_openkey (hwnd, hkey);

								NtClose (hkey);
							}
						}
					}

					break;
				}

				case IDM_COPY:
				{
					R_STRINGBUILDER sb;
					PR_STRING string;
					INT column_count;
					INT item_id = INT_ERROR;

					_r_obj_initializestringbuilder (&sb, 256);

					column_count = _r_listview_getcolumncount (hwnd, IDC_LISTVIEW);

					while ((item_id = _r_listview_getnextselected (hwnd, IDC_LISTVIEW, item_id)) != INT_ERROR)
					{
						for (INT i = 0; i < column_count; i++)
						{
							string = _r_listview_getitemtext (hwnd, IDC_LISTVIEW, item_id, i);

							if (string)
							{
								_r_obj_appendstringbuilder2 (&sb, &string->sr);

								if ((i + 1) != column_count)
									_r_obj_appendstringbuilder (&sb, L", ");

								_r_obj_dereference (string);
							}
						}

						_r_obj_appendstringbuilder (&sb, L"\r\n");
					}

					string = _r_obj_finalstringbuilder (&sb);

					_r_str_trimstring2 (&string->sr, L"\r\n ", 0);

					_r_clipboard_set (hwnd, &string->sr);

					_r_obj_dereference (string);

					break;
				}

				case IDM_COPY_VALUE:
				{
					R_STRINGBUILDER sb;
					PR_STRING string;
					INT column_id;
					INT item_id = INT_ERROR;

					column_id = (INT)lparam;

					_r_obj_initializestringbuilder (&sb, 256);

					while ((item_id = _r_listview_getnextselected (hwnd, IDC_LISTVIEW, item_id)) != INT_ERROR)
					{
						string = _r_listview_getitemtext (hwnd, IDC_LISTVIEW, item_id, column_id);

						if (string)
						{
							_r_obj_appendstringbuilder2 (&sb, &string->sr);

							_r_obj_dereference (string);
						}

						_r_obj_appendstringbuilder (&sb, L"\r\n");
					}

					string = _r_obj_finalstringbuilder (&sb);

					_r_str_trimstring2 (&string->sr, L"\r\n ", 0);

					_r_clipboard_set (hwnd, &string->sr);

					_r_obj_dereference (string);

					break;
				}

				case IDM_SELECT_ALL:
				{
					if (GetFocus () != GetDlgItem (hwnd, IDC_LISTVIEW))
						break;

					_r_listview_setitemstate (hwnd, IDC_LISTVIEW, INT_ERROR, LVIS_SELECTED, LVIS_SELECTED);

					break;
				}
			}

			break;
		}
	}

	return FALSE;
}

INT APIENTRY wWinMain (
	_In_ HINSTANCE hinst,
	_In_opt_ HINSTANCE prev_hinst,
	_In_ LPWSTR cmdline,
	_In_ INT show_cmd
)
{
	HWND hwnd;

	if (!_r_app_initialize (NULL))
		return ERROR_APP_INIT_FAILURE;

	hwnd = _r_app_createwindow (hinst, MAKEINTRESOURCEW (IDD_MAIN), MAKEINTRESOURCEW (IDI_MAIN), &DlgProc);

	if (!hwnd)
		return ERROR_APP_INIT_FAILURE;

	return _r_wnd_message_callback (hwnd, MAKEINTRESOURCEW (IDA_MAIN));
}
