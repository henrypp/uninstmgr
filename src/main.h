// Uninstall Manager
// Copyright (c) 2010-2025 Henry++

#pragma once

#include "routine.h"

#include "resource.h"
#include "app.h"

// ui
#define LANG_SUBMENU 2
#define LANG_MENU 5

#define REBAR_TOOLBAR_ID 0
#define REBAR_SEARCH_ID 1

#define LV_HIDDEN_GROUP_ID 666

// default colors
#define LV_COLOR_UPDATE RGB(0, 108, 208)
#define LV_COLOR_SYSTEM_COMPONENT RGB(255, 208, 208)

typedef enum _INSTALLER
{
	InstallerUnknown,
	WindowsInstaller,
	InnoSetupInstaller,
	NsisInstaller,
	CreateInstallInstaller,
	AstrumInstaller,
	AgentixInstaller,
	SmartInstallMakerInstaller,
	SetupFactoryInstaller,
	ExcelsiorInstaller,
	GhostInstaller,
	WixInstaller,
} INSTALLER, *PINSTALLER;

typedef enum _INSTALLER_TYPE
{
	Installer,
	SystemComponent,
	SystemUpdate,
} INSTALLER_TYPE, *PINSTALLER_TYPE;

typedef struct _STATIC_DATA
{
	PR_STRING search_string;
	SC_HANDLE hsvcmgr;
	HIMAGELIST himg_listview;
	HIMAGELIST himg_toolbar;
	HBITMAP hbitmap_uac;
	HFONT wnd_font;
	HWND hrebar;
	HWND htoolbar;
	HWND hsearchbar;
	LONG icon_id;
} STATIC_DATA, *PSTATIC_DATA;

typedef struct _ITEM_CONTEXT
{
	PR_STRING install_location;
	PR_STRING uninstall_string;
	PR_STRING uninstaller_path;
	PR_STRING file_path;
	PR_STRING icon_path;
	PR_STRING name;
	PR_STRING version;
	PR_STRING key_path;
	HANDLE hroot;
	LONG64 timestamp;
	LONG icon_id;
	INSTALLER installer;
	INSTALLER_TYPE type;
	BOOLEAN is_hidden;
} ITEM_CONTEXT, *PITEM_CONTEXT;
