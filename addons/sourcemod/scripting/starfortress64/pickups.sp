#if defined _sf64_pickups_included
  #endinput
#endif
#define _sf64_pickups_included

#define PICKUP_LASER_MODEL "models/tokens/laser-up.mdl"
#define PICKUP_LASER_SOUND "arwing/pickups/laser/laser_pickup.mp3"

#define PICKUP_BOMB_MODEL "models/tokens/bomb.mdl"
#define PICKUP_BOMB_SOUND "arwing/pickups/smartbomb/smartbomb_pickup.mp3"

#define PICKUP_RING_MODEL "models/tokens/ring1.mdl"
#define PICKUP_RING_SOUND "arwing/pickups/smartbomb/smartbomb_pickup.mp3"

#define PICKUP_RING2_MODEL "models/tokens/ring2.mdl"
#define PICKUP_RING2_SOUND "arwing/pickups/smartbomb/smartbomb_pickup.mp3"


PrecachePickups()
{
	PrecacheModel2(PICKUP_LASER_MODEL);
	PrecacheSound2(PICKUP_LASER_SOUND);
	AddFileToDownloadsTable("materials/models/tokens/laser-up_texture.vtf");
	AddFileToDownloadsTable("materials/models/tokens/laser-up_texture.vmt");
	
	PrecacheModel2(PICKUP_BOMB_MODEL);
	PrecacheSound2(PICKUP_BOMB_SOUND);
	AddFileToDownloadsTable("materials/models/tokens/bomb_texture.vtf");
	AddFileToDownloadsTable("materials/models/tokens/bomb_texture.vmt");
	
	PrecacheModel2(PICKUP_RING_MODEL);
	PrecacheSound2(PICKUP_RING_SOUND);
	AddFileToDownloadsTable("materials/models/tokens/ring_texture.vtf");
	AddFileToDownloadsTable("materials/models/tokens/ring_texture.vmt");
	
	PrecacheModel2(PICKUP_RING2_MODEL);
	PrecacheSound2(PICKUP_RING2_SOUND);
}

SpawnPickup(iType, iQuantity, const Float:flPos[3], const Float:flAng[3], bool:bCanRespawn=false, &iIndex=-1)
{
	new iPickup = CreateEntityByName("prop_dynamic_override");
	if (iPickup != -1)
	{
		switch (iType)
		{
			case PickupType_Laser: 
			{
				SetEntPropFloat(iPickup, Prop_Send, "m_flModelScale", 1.5);
				SetEntityModel(iPickup, PICKUP_LASER_MODEL);
			}
			case PickupType_SmartBomb: 
			{
				SetEntPropFloat(iPickup, Prop_Send, "m_flModelScale", 1.5);
				SetEntityModel(iPickup, PICKUP_BOMB_MODEL);
			}
			case PickupType_Ring: 
			{
				SetEntPropFloat(iPickup, Prop_Send, "m_flModelScale", 2.5);
				SetEntityModel(iPickup, PICKUP_RING_MODEL);
			}
			case PickupType_Ring2: 
			{
				SetEntPropFloat(iPickup, Prop_Send, "m_flModelScale", 2.5);
				SetEntityModel(iPickup, PICKUP_RING2_MODEL);
			}
		}
		
		DispatchKeyValue(iPickup, "solid", "2");
		DispatchSpawn(iPickup);
		ActivateEntity(iPickup);
		SetEntityMoveType(iPickup, MOVETYPE_NOCLIP);
		SetEntProp(iPickup, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER);
		SetEntProp(iPickup, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
		
		// Attach trail to enable movement.
		new iTrailEnt = CreateEntityByName("env_spritetrail");
		if (iTrailEnt != -1)
		{
			DispatchKeyValue(iTrailEnt, "spritename", ARWING_LASER_TRAIL_MATERIAL);
			DispatchKeyValue(iTrailEnt, "renderamt", "0");
			DispatchKeyValue(iTrailEnt, "rendermode", "5");
			DispatchKeyValueFloat(iTrailEnt, "lifetime", 1.0);
			DispatchKeyValueFloat(iTrailEnt, "startwidth", 0.5);
			DispatchKeyValueFloat(iTrailEnt, "endwidth", 0.5);
			DispatchSpawn(iTrailEnt);
			ActivateEntity(iTrailEnt);
			SetVariantString("!activator");
			AcceptEntityInput(iTrailEnt, "SetParent", iPickup);
		}
		
		iIndex = PushArrayCell(g_hPickups, EntIndexToEntRef(iPickup));
		SetArrayCell(g_hPickups, iIndex, iType, Pickup_Type);
		SetArrayCell(g_hPickups, iIndex, iQuantity, Pickup_Quantity);
		SetArrayCell(g_hPickups, iIndex, true, Pickup_Enabled);
		SetArrayCell(g_hPickups, iIndex, bCanRespawn, Pickup_CanRespawn);
		SetArrayCell(g_hPickups, iIndex, INVALID_HANDLE, Pickup_RespawnTimer);
		
		TeleportEntity(iPickup, flPos, flAng, NULL_VECTOR);
		SDKHook(iPickup, SDKHook_StartTouchPost, Hook_PickupStartTouchPost);
		new Handle:hTimer = CreateTimer(0.25, Timer_PickupThink, EntIndexToEntRef(iPickup), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		TriggerTimer(hTimer, true);
		
		switch (iType)
		{
			case PickupType_Laser, PickupType_SmartBomb:
			{
				SetEntPropVector(iPickup, Prop_Data, "m_vecAngVelocity", Float:{ 0.0, 360.0, 0.0 });
			}
			case PickupType_Ring:
			{
				SetEntPropVector(iPickup, Prop_Data, "m_vecAngVelocity", Float:{ 180.0, 0.0, 0.0 });
			}
			case PickupType_Ring2:
			{
				SetEntPropVector(iPickup, Prop_Data, "m_vecAngVelocity", Float:{ 0.0, 0.0, 180.0 });
			}
		}
	}
	
	return iPickup;
}

SpawnPickupGet(iPickup, iTarget, &iIndex=-1)
{
	if (!IsValidEntity(iPickup)) return -1;
	
	new iPickupIndex = FindValueInArray(g_hPickups, EntIndexToEntRef(iPickup));
	if (iPickupIndex == -1) return -1;

	new iPickupGet = CreateEntityByName("prop_dynamic_override");
	if (iPickupGet != -1)
	{
		decl Float:flPos[3], Float:flAng[3];
		GetEntPropVector(iPickup, Prop_Data, "m_vecAbsOrigin", flPos);
		GetEntPropVector(iPickup, Prop_Data, "m_angAbsRotation", flAng);
	
		decl String:sModelName[PLATFORM_MAX_PATH];
		GetEntPropString(iPickup, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
		
		SetEntPropFloat(iPickupGet, Prop_Send, "m_flModelScale", GetEntPropFloat(iPickup, Prop_Send, "m_flModelScale"));
		SetEntityModel(iPickupGet, sModelName);
		
		DispatchSpawn(iPickupGet);
		ActivateEntity(iPickupGet);
		
		SetEntityMoveType(iPickupGet, MOVETYPE_NOCLIP);
		SetEntProp(iPickupGet, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID | FSOLID_TRIGGER);
		SetEntProp(iPickupGet, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
		
		// Attach trail to enable movement.
		new iTrailEnt = CreateEntityByName("env_spritetrail");
		if (iTrailEnt != -1)
		{
			DispatchKeyValue(iTrailEnt, "spritename", ARWING_LASER_TRAIL_MATERIAL);
			DispatchKeyValue(iTrailEnt, "renderamt", "0");
			DispatchKeyValue(iTrailEnt, "rendermode", "5");
			DispatchKeyValueFloat(iTrailEnt, "lifetime", 1.0);
			DispatchKeyValueFloat(iTrailEnt, "startwidth", 0.5);
			DispatchKeyValueFloat(iTrailEnt, "endwidth", 0.5);
			DispatchSpawn(iTrailEnt);
			ActivateEntity(iTrailEnt);
			SetVariantString("!activator");
			AcceptEntityInput(iTrailEnt, "SetParent", iPickupGet);
		}
		
		TeleportEntity(iPickupGet, flPos, flAng, NULL_VECTOR);
		
		new iType = GetArrayCell(g_hPickups, iPickupIndex, Pickup_Type);
		
		iIndex = PushArrayCell(g_hPickupsGet, EntIndexToEntRef(iPickupGet));
		SetArrayCell(g_hPickupsGet, iIndex, GetGameTime(), PickupGet_LastSpawnTime);
		SetArrayCell(g_hPickupsGet, iIndex, iType, PickupGet_Type);
		SetArrayCell(g_hPickupsGet, iIndex, IsValidEntity(iTarget) ? EntIndexToEntRef(iTarget) : INVALID_ENT_REFERENCE, PickupGet_Target);
		
		new Handle:hTimer = CreateTimer(0.01, Timer_PickupGetThink, EntIndexToEntRef(iPickupGet), TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		TriggerTimer(hTimer, true);
		
		RemoveEntity(iPickupGet, 1.0);
		
		switch (iType)
		{
			case PickupType_Laser, PickupType_SmartBomb:
			{
				SetEntPropVector(iPickupGet, Prop_Data, "m_vecAngVelocity", Float:{ 0.0, 520.0, 0.0 });
			}
			case PickupType_Ring:
			{
				SetEntPropVector(iPickupGet, Prop_Data, "m_vecAngVelocity", Float:{ 520.0, 0.0, 0.0 });
			}
			case PickupType_Ring2:
			{
				SetEntPropVector(iPickupGet, Prop_Data, "m_vecAngVelocity", Float:{ 0.0, 0.0, 520.0 });
			}
		}
	}
	
	return iPickupGet;
}

public Hook_PickupStartTouchPost(iPickup, other)
{
	new iIndex = FindValueInArray(g_hPickups, EntIndexToEntRef(iPickup));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hPickups, iIndex, Pickup_Enabled)) return;
	
	new iOtherIndex = FindValueInArray(g_hArwings, EntIndexToEntRef(other));
	if (iOtherIndex != -1)
	{
		if (bool:GetArrayCell(g_hArwings, iOtherIndex, Arwing_Enabled))
		{
			new iPilot = EntRefToEntIndex(GetArrayCell(g_hArwings, iOtherIndex, Arwing_Pilot));
			new iType = GetArrayCell(g_hPickups, iIndex, Pickup_Type);
			new iQuantity = GetArrayCell(g_hPickups, iIndex, Pickup_Quantity);
			
			DisablePickup(iPickup);
			SpawnPickupGet(iPickup, other);
			
			switch (iType)
			{
				case PickupType_Laser:
				{
					if (IsValidClient(iPilot)) EmitSoundToClient(iPilot, PICKUP_LASER_SOUND, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
					
					new iUpgradeLevel = GetArrayCell(g_hArwings, iOtherIndex, Arwing_LaserUpgradeLevel);
					new iMaxUpgradeLevel = GetArrayCell(g_hArwings, iOtherIndex, Arwing_LaserMaxUpgradeLevel);
					
					if (iUpgradeLevel < iMaxUpgradeLevel)
					{
						iUpgradeLevel += iQuantity;
						if (iUpgradeLevel > iMaxUpgradeLevel) iUpgradeLevel = iMaxUpgradeLevel;
					
						SetArrayCell(g_hArwings, iOtherIndex, iUpgradeLevel, Arwing_LaserUpgradeLevel);
					}
				}
				case PickupType_SmartBomb:
				{
					if (IsValidClient(iPilot)) EmitSoundToClient(iPilot, PICKUP_BOMB_SOUND, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
					
					new iNum = GetArrayCell(g_hArwings, iOtherIndex, Arwing_SmartBombNum);
					new iMaxNum = GetArrayCell(g_hArwings, iOtherIndex, Arwing_SmartBombMaxNum);
					
					if (iNum < iMaxNum)
					{
						iNum += iQuantity;
						if (iNum > iMaxNum) iNum = iMaxNum;
						
						SetArrayCell(g_hArwings, iOtherIndex, iNum, Arwing_SmartBombNum);
					}
				}
				case PickupType_Ring, PickupType_Ring2:
				{
					if (IsValidClient(iPilot)) 
					{
						if (iType == PickupType_Ring) EmitSoundToClient(iPilot, PICKUP_RING_SOUND, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
						else EmitSoundToClient(iPilot, PICKUP_RING2_SOUND, _, SNDCHAN_STATIC, SNDLEVEL_NONE);
					}
					
					new iHealth = GetArrayCell(g_hArwings, iOtherIndex, Arwing_Health);
					new iMaxHealth = GetArrayCell(g_hArwings, iOtherIndex, Arwing_MaxHealth);
					
					if (iHealth < iMaxHealth)
					{
						iHealth += iQuantity;
						if (iHealth > iMaxHealth) iHealth = iMaxHealth;
						
						ArwingSetHealth(other, iHealth);
					}
				}
			}
			
			if (bool:GetArrayCell(g_hPickups, iIndex, Pickup_CanRespawn))
			{
				new Handle:hTimer = CreateTimer(30.0, Timer_EnablePickup, EntIndexToEntRef(iPickup), TIMER_FLAG_NO_MAPCHANGE);
				SetArrayCell(g_hPickups, iIndex, hTimer, Pickup_RespawnTimer);
			}
			else
			{
				RemoveEntity(iPickup, 5.0);
			}
		}
	}
}

public Action:Timer_PickupThink(Handle:timer, any:entref)
{
	new iPickup = EntRefToEntIndex(entref);
	if (!iPickup || iPickup == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	new iIndex = FindValueInArray(g_hPickups, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	decl Float:flPickupAng[3], Float:flNewAng[3];
	GetEntPropVector(iPickup, Prop_Data, "m_angAbsRotation", flPickupAng);
	CopyVectors(flPickupAng, flNewAng);
	
	new iType = GetArrayCell(g_hPickups, iIndex, Pickup_Type);
	switch (iType)
	{
		case PickupType_Laser, PickupType_SmartBomb:
		{
			if (flPickupAng[1] >= 180000.0)
			{
				flNewAng[1] = 0.0;
				TeleportEntity(iPickup, NULL_VECTOR, flNewAng, NULL_VECTOR);
			}
		}
		case PickupType_Ring:
		{
			if (flPickupAng[0] >= 180000.0)
			{
				flNewAng[0] = 0.0;
				TeleportEntity(iPickup, NULL_VECTOR, flNewAng, NULL_VECTOR);
			}
		}
		case PickupType_Ring2:
		{
			if (flPickupAng[2] >= 180000.0)
			{
				flNewAng[2] = 0.0;
				TeleportEntity(iPickup, NULL_VECTOR, flNewAng, NULL_VECTOR);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_PickupGetThink(Handle:timer, any:entref)
{
	new iPickupGet = EntRefToEntIndex(entref);
	if (!iPickupGet || iPickupGet == INVALID_ENT_REFERENCE) return Plugin_Stop;
	
	new iIndex = FindValueInArray(g_hPickupsGet, entref);
	if (iIndex == -1) return Plugin_Stop;
	
	new Float:flModelScale = GetEntPropFloat(iPickupGet, Prop_Send, "m_flModelScale");
	if (flModelScale > 0.1)
	{
		SetEntPropFloat(iPickupGet, Prop_Send, "m_flModelScale", flModelScale - 0.1);
	}
	
	new iTarget = EntRefToEntIndex(GetArrayCell(g_hPickupsGet, iIndex, PickupGet_Target));
	if (iTarget && iTarget != INVALID_ENT_REFERENCE)
	{
		decl Float:flPickupPos[3], Float:flTargetPos[3];
		GetEntPropVector(iPickupGet, Prop_Data, "m_vecAbsOrigin", flPickupPos);
		GetEntPropVector(iTarget, Prop_Data, "m_vecAbsOrigin", flTargetPos);
		
		decl Float:flPickupVelocity[3], Float:flGoalVelocity[3];
		GetEntPropVector(iPickupGet, Prop_Data, "m_vecAbsVelocity", flPickupVelocity);
		SubtractVectors(flTargetPos, flPickupPos, flGoalVelocity);
		NormalizeVector(flGoalVelocity, flGoalVelocity);
		ScaleVector(flGoalVelocity, 2000.0);
		
		decl Float:flMoveVelocity[3];
		LerpVectors(flPickupVelocity, flGoalVelocity, flMoveVelocity, 0.25);
		TeleportEntity(iPickupGet, NULL_VECTOR, NULL_VECTOR, flMoveVelocity);
	}
	
	return Plugin_Continue;
}

public Action:Timer_EnablePickup(Handle:timer, any:entref)
{
	new iPickup = EntRefToEntIndex(entref);
	if (!iPickup || iPickup == INVALID_ENT_REFERENCE) return;
	
	new iIndex = FindValueInArray(g_hPickups, entref);
	if (iIndex == -1) return;
	
	if (timer != Handle:GetArrayCell(g_hPickups, iIndex, Pickup_RespawnTimer)) return;
	
	EnablePickup(iPickup);
}

EnablePickup(iPickup)
{
	new iIndex = FindValueInArray(g_hPickups, EntIndexToEntRef(iPickup));
	if (iIndex == -1) return;
	
	if (bool:GetArrayCell(g_hPickups, iIndex, Pickup_Enabled)) return;
	
	SetArrayCell(g_hPickups, iIndex, true, Pickup_Enabled);
	SetEntityRenderMode(iPickup, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iPickup, 255, 255, 255, 255);
	
	decl Float:flPickupAng[3], Float:flNewAng[3];
	GetEntPropVector(iPickup, Prop_Data, "m_angAbsRotation", flPickupAng);
	CopyVectors(flPickupAng, flNewAng);
	
	new iType = GetArrayCell(g_hPickups, iIndex, Pickup_Type);
	switch (iType)
	{
		case PickupType_Laser, PickupType_SmartBomb:
		{
			flNewAng[1] = 0.0;
			TeleportEntity(iPickup, NULL_VECTOR, flNewAng, NULL_VECTOR);
		}
		case PickupType_Ring:
		{
			flNewAng[0] = 0.0;
			TeleportEntity(iPickup, NULL_VECTOR, flNewAng, NULL_VECTOR);
		}
		case PickupType_Ring2:
		{
			flNewAng[2] = 0.0;
			TeleportEntity(iPickup, NULL_VECTOR, flNewAng, NULL_VECTOR);
		}
	}
}

DisablePickup(iPickup)
{
	new iIndex = FindValueInArray(g_hPickups, EntIndexToEntRef(iPickup));
	if (iIndex == -1) return;
	
	if (!bool:GetArrayCell(g_hPickups, iIndex, Pickup_Enabled)) return;
	
	SetArrayCell(g_hPickups, iIndex, false, Pickup_Enabled);
	SetEntityRenderMode(iPickup, RENDER_TRANSCOLOR);
	SetEntityRenderColor(iPickup, 0, 0, 0, 1);
}