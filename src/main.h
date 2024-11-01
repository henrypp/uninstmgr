// Uninstall Manager
// Copyright (c) 2010-2025 Henry++

#pragma once

#include "routine.h"

#include "resource.h"
#include "app.h"

// ui
#define LANG_MENU 5

#define LV_HIDDEN_GROUP_ID 13

// default colors
#define LV_COLOR_SIGNED RGB (175, 228, 163)
#define LV_COLOR_SYSTEM RGB(151, 196, 251)

typedef enum _INSTALLER
{
	InstallerUnknown = 1,
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
} INSTALLER, *PINSTALLER;

typedef enum _INSTALLER_TYPE
{
	Installer,
	SystemComponent,
	SystemUpdate,
} INSTALLER_TYPE, *PINSTALLER_TYPE;

typedef struct _STATIC_DATA
{
	HIMAGELIST himg;
	LONG icon_id;
} STATIC_DATA, *PSTATIC_DATA;

typedef struct _ITEM_CONTEXT
{
	PR_STRING file_path;
	PR_STRING install_location;
	PR_STRING uninstall_string;
	PR_STRING uninstaller_path;
	PR_STRING icon_path;
	PR_STRING name;
	PR_STRING version;
	PR_STRING key_path;
	HANDLE hroot;
	LONG64 timestamp;
	LONG icon_id;
	INSTALLER_TYPE installer;
	BOOLEAN is_hidden;
} ITEM_CONTEXT, *PITEM_CONTEXT;
