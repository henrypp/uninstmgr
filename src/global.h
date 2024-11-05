// Uninstall Manager
// Copyright (c) 2010-2025 Henry++

#pragma once

#include "routine.h"

#include <aclapi.h>
#include <subauth.h>
#include <mscat.h>

#include "app.h"
#include "rapp.h"

#include "main.h"
#include "search.h"

#include "resource.h"

DECLSPEC_SELECTANY STATIC_DATA config = {0};

DECLSPEC_SELECTANY R_WORKQUEUE workqueue = {0};
