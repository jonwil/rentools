-----------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------
--                                                                                                                                                 --
--                                                            W3D Importer Plug-in  v1.16b                                                         --
--                                                                                                                                                 --
--                                                          By Eric Morin (eWs-Clone / Abjab)                                                      --
--                                                                                                                                                 --
-----------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------

CurrentScreenWidth = systemTools.GetScreenWidth()
CurrentScreenHeight = systemTools.GetScreenHeight()
global mostRecentPath
global notFoundString
global ObjectsW3DFlags
global UserClickedOnImportButton = false
global MixFilesArray = #()
global IsHModel = false
global Materials = #()

fileIn "RenX-WME.ms"

fn SetW3DXRayTool=
(
	select $boundingbox
	$boundingbox.xray = on
	select $worldbox
	$worldbox.xray = on
)

fn setW3DAppTitle=
(
	local fname = if maxFileName == "" then "Untitled" else maxFileName
	local str = fname + " - RenX - W3D Modeler Edition"
	cui.setAppTitle str
)

setW3DAppTitle()

fn clearW3DFlags=
(
	if not UserClickedOnImportButton do return false
	local FlagsToClear = #("isMesh", "Type", "Flags", "BoneID", "BoneLOD", "DazzleType", "isBone")

	ObjectsW3DFlags = stringStream ""

	for o in objects do
	(
		local KeepStream = stringStream ""
		local tmpStream = stringStream ""
		local val
		local propval

		format "NodeName=$'%'\n" o.name to:ObjectsW3DFlags

		format "%" (getUserPropBuffer o) to:tmpStream

		seek tmpStream 0

		While not eof tmpStream do
		(
			val = readDelimitedString tmpStream "="
			if val[val.count] == " " do val = trimRight val " "
			propval = readDelimitedString tmpStream (bit.intAsChar 0)
			if propval[1] == " " do propval = trimLeft propval " "

			if findItem FlagsToClear val == 0 do format "% = %\n" val propval to:KeepStream

			if propval[propval.count] == "\n" do propval = trimRight propval "\n"
			format "%=%\n" val propval to:ObjectsW3DFlags
		)

		setUserPropBuffer o KeepStream
	)
	format "EndProps=true\n" to:ObjectsW3DFlags
)

fn restoreW3DFlags=
(
	if not UserClickedOnImportButton do return false
	seek ObjectsW3DFlags 0

	While not eof ObjectsW3DFlags do
	(
		local CurrentNode
		local val
		local propval
		local tmpOffset

		val = readDelimitedString ObjectsW3DFlags "="
		propval = readDelimitedString ObjectsW3DFlags "\n"

		if val == "EndProps" then exit;

		if val == "NodeName" then CurrentNode = execute propval
		else
		(
			while val != "NodeName" do
			(
				setUserProp CurrentNode val propval
				tmpOffset = filePos ObjectsW3DFlags
				val = readDelimitedString ObjectsW3DFlags "="
				propval = readDelimitedString ObjectsW3DFlags "\n"
				if val == "EndProps" then exit;
			)

			seek ObjectsW3DFlags tmpOffset
		)
	)
)

newInitText = ""

rollout TmpInitUpdateDlg "Temporary Dialog For W3D-Importer.ini Update" width:600 height:500 silentErrors:false
(
	groupBox NoteGroup "Note:" width:592 height:110 pos:[4,4]
	label Str1 "  Gmax does not allow file writing, so untill I write some work around code, probably using Flash 5 plugin," pos:[40,25]
	label Str2 "changes made in the preferences will remains effective untill Gmax is closed. That is unless you replace the" pos:[40,41]
	label Str3 "content of W3D-Importer.ini by the text bellow, simply copy and paste this text over the text in the ini file." pos:[40,57]
	label Str4 "  Also make sure you select everything since Gmax does not have scroll bars for text boxes :(" pos:[40,89]
	edittext newInitFile text:newInitText width:596 height:380 pos:[0,120]

	fn Open=
	(
		createDialog TmpInitUpdateDlg style:#(#style_titlebar, #style_sysmenu) \
			modal:true
	)
)

struct W3D_Importer_Init
(
	ImporterInitFile = getdir #maxroot + "Plugins\W3D-Importer.ini",
	Initialized = false,
	InitStream,
	CurrentProfile,
	UseOneProfile,
	CharProfile,
	VehicleProfile,
	recentFiles = #(),
	W3DPaths = #(),
	MixPath,
	ProfilesList = #(),
	UserProfiles = #(),
	ProfilesDefaults = #(),

	fn open=
	(
		if doesFileExist ImporterInitFile then
		(
			InitStream = openFile ImporterInitFile
			return true;
		)
		else return false;
	),

	fn close=
	(
		fclose InitStream
	),
	
	fn getProfileDefaults profile value:"all"=
	(
		if profile < 1 or profile > 3 do profile = 1
		local index = (13 * profile) - 12

		if value == "all" then
		(
			local tmpDefaults = #()
			for i = 0 to 12 do append tmpDefaults ProfilesDefaults[index+i]
			return tmpDefaults
		)
		else
		(
			case value of
			(
				"BoneShape": return ProfilesDefaults[index]
				"BoneSize": return ProfilesDefaults[index+1]
				"BoneColor": return ProfilesDefaults[index+2]
				"ProxyShape": return ProfilesDefaults[index+3]
				"ProxySize": return ProfilesDefaults[index+4]
				"ProxyColor": return ProfilesDefaults[index+5]
				"AggregateShape": return ProfilesDefaults[index+6]
				"AggregateSize": return ProfilesDefaults[index+7]
				"AggregateColor": return ProfilesDefaults[index+8]
				"DazzleShape": return ProfilesDefaults[index+9]
				"DazzleSize": return ProfilesDefaults[index+10]
				"DazzleColor": return ProfilesDefaults[index+11]
				"CreateMeshesBones": return ProfilesDefaults[index+12]
			)
		)
	),

	fn ColorToString val=
	(
		val = val as color
		local r = (val.r as integer) as string
		local g = (val.g as integer) as string
		local b = (val.b as integer) as string
		local str = r + "," + g + "," + b

		str
	),

	fn valToShape val=
	(
		case val of
		(
			1: return "box";
			2: return "sphere";
			3: return "cylinder";
		)
	),

	fn NewLine=
	(
		newInitText = newInitText + (bit.intAsChar 13) + (bit.intAsChar 10)
	),

	fn AddLine str=
	(
		newInitText = newInitText + str
		NewLine()
	),

	fn UpdateInitFile=
	(
		AddLine "[W3D_Importer]"
		AddLine ("CurrentProfile=" + CurrentProfile as string)
		AddLine ("UseOneProfile=" + (if UseOneProfile then "1" else "0"))
		AddLine ("CharProfile=" + CharProfile as string)
		AddLine ("VehicleProfile=" + VehicleProfile as string)
		for i = 1 to 5 do
			if W3DPaths[i] != undefined do AddLine ("W3DPath_" + i as string + "=" + W3DPaths[i])
		AddLine ("MixPath=" + MixPath)
		NewLine()

		AddLine "[Profiles_List]"
		for i = 1 to ProfilesList.count do AddLine (i as string + "=" + ProfilesList[i])
		NewLine()

		for i = 1 to ProfilesList.count do
		(
			local index = (13 * i) - 12

			AddLine ("[" + ProfilesList[i] + "]")
			AddLine ("BoneShape=" + ValToShape UserProfiles[index])
			AddLine ("BoneSize=" + UserProfiles[index+1] as string)
			AddLine ("BoneColor=" + ColorToString UserProfiles[index+2])
			AddLine ("ProxyShape=" + ValToShape UserProfiles[index+3])
			AddLine ("ProxySize=" + UserProfiles[index+4] as string)
			AddLine ("ProxyColor=" + ColorToString UserProfiles[index+5])
			AddLine ("AggregateShape=" + ValToShape UserProfiles[index+6])
			AddLine ("AggregateSize=" + UserProfiles[index+7] as string)
			AddLine ("AggregateColor=" + ColorToString UserProfiles[index+8])
			AddLine ("DazzleShape=" + ValToShape UserProfiles[index+9])
			AddLine ("DazzleSize=" + UserProfiles[index+10] as string)
			AddLine ("DazzleColor=" + ColorToString UserProfiles[index+11])
			AddLine ("CreateMeshesBones=" + ( if UserProfiles[index+12] then "1" else "0"))
			NewLine()
		)

		TmpInitUpdateDlg.open()
		edit ImporterInitFile
		newInitText = ""
	),

	fn init=
	(
		if Initialized then return false;

		ProfilesDefaults = #(1,0.4,(color 0 0 255),1,1.0,(color 255 255 0),1,1.0,(color 255 155 247),2,1.0,(color 255 0 0),false, \
					   1,0.1,(color 0 0 255),1,0.2,(color 255 255 0),1,0.2,(color 255 155 247),2,0.3,(color 255 0 0),true, \
					   1,0.2,(color 0 0 255),1,1.0,(color 255 255 0),1,0.3,(color 255 155 247),2,0.5,(color 255 0 0),true)

		local ProfileValNames = #("BoneShape","ProxyShape","AggregateShape","DazzleShape","BoneSize","ProxySize", \
			"DazzleSize","AggregateSize","BoneColor","ProxyColor","AggregateColor","DazzleColor","CreateMeshesBones")

		local Shapes = #("box", "sphere", "cylinder")

		CurrentProfile = (getINISetting ImporterInitFile "W3D_Importer" "CurrentProfile") as integer
		UseOneProfile = ((getINISetting ImporterInitFile "W3D_Importer" "UseOneProfile") as integer) == 1
		CharProfile = (getINISetting ImporterInitFile "W3D_Importer" "CharProfile") as integer
		VehicleProfile = (getINISetting ImporterInitFile "W3D_Importer" "VehicleProfile") as integer

		for i = 1 to 5 do
		(
			W3DPaths[i] = getINISetting ImporterInitFile "W3D_Importer" ("W3DPath_" + i as string)
			recentFiles[i] = getINISetting ImporterInitFile "W3D_Importer" ("RecentW3DFile_" + i as string)
		)
		
		MixPath = getINISetting ImporterInitFile "W3D_Importer" "MixPath" 
		
		if CurrentProfile == 0 do CurrentProfile = 1
		if CharProfile == 0 do CharProfile = 2
		if VehicleProfile == 0 do VehicleProfile = 3
		if W3DPaths[1] == "" do W3DPaths[1] = getdir #maxroot

		local i = 5

		while i > 1 do
		(
			if W3DPaths[i] == "" do deleteItem W3DPaths i
			i -= 1
		)

		local profileID = 1
		while val != "" do
		(
			val = getINISetting ImporterInitFile "Profiles_List" (profileID as string)
			if val != "" do ProfilesList[profileID] = val
			profileID += 1
		)
			
		if ProfilesList[1] == undefined do ProfilesList[1] = "Default"
		if ProfilesList[2] == undefined do ProfilesList[2] = "Default Characters"
		if ProfilesList[3] == undefined do ProfilesList[3] = "Default Vehicles"

		for i = 1 to ProfilesList.count do
		(
			local val

			for j = 0 to 12 do
			(
				local settingIndex
				val = getINISetting ImporterInitFile ProfilesList[i] ProfileValNames[j+1]

				if j < 4 do
				(
					settingIndex = ((3 * (j+1)) - 3) + ((13 * i) - 12)
					if val == "" then UserProfiles[settingIndex] = getProfileDefaults i value:ProfileValNames[j+1]
					else UserProfiles[settingIndex] = findItem Shapes val
				)
				if j > 3 and j < 8 do
				(
					settingIndex = ((3 * (j-3)) - 2) + ((13 * i) - 12)
					if val == "" then UserProfiles[settingIndex] = getProfileDefaults i value:ProfileValNames[j+1]
					else UserProfiles[settingIndex] = val as float
				)
				if j > 7 and j < 12 do
				(
					settingIndex = ((3 * (j-7)) - 1) + ((13 * i) - 12)
					if val == "" then UserProfiles[settingIndex] = getProfileDefaults i value:ProfileValNames[j+1]
					else
					(
						local tmpXYZ = filterString val ","
						UserProfiles[settingIndex] = color (tmpXYZ[1] as float) (tmpXYZ[2] as float) (tmpXYZ[3] as float)
					)
				)
				if j == 12 do
				(
					settingIndex = 13 * i
					if val == "" then UserProfiles[settingIndex] = getProfileDefaults i value:ProfileValNames[j+1]
					else UserProfiles[settingIndex] = (val as integer) == 1
				)
			)
		)

		Initialized = true
	)
)

W3DImporterInit = W3D_Importer_Init()

rollout W3DImportProgressDlg "Importing W3D..." width:400 height:80 silentErrors:false
(
	label Stage "" pos:[13,20] width:250 align:#left
	progressBar Progress pos:[14,40] height:20 width:372 align:#left
	label Percent "0 %" pos:[185,67] width:50 align:#left

	fn fOpen=
	(
		createDialog W3DImportProgressDlg style:#(#style_titlebar)

		setFocus W3DImportProgressDlg
	)

	fn fClose=
	(
		destroyDialog W3DImportProgressDlg
	)
)

rollout W3DImportAboutDlg "About W3D Importer" width:250 height:70 silentErrors:false
(
	label appLabel "W3D Importer v1.16b"
	label byLabel "by"
	label authorLabel "Scripting: Eric Morin (eWs-Clone / Abjab)"
	label helpAuthorLabel "Help File: Thomas Anderson (Dante)" 

	fn Open XYPos=
	(
		createDialog W3DImportAboutDlg style:#(#style_titlebar, #style_toolwindow, #style_sysmenu) \
			modal:true
	)
)

rollout W3DNewProfile "New Profile" width:323 height:85 silentErrors:false
(
	local NewName

	edittext ProfileName "Profile Name : " pos:[27,20] fieldWidth:195 text:"New Profile" align:#left
	button OKButton "OK" pos:[159,60] width:75
	button CancelButton "Cancel" pos:[240,60] width:75

	fn Open XYPos=
	(
		createDialog W3DNewProfile style:#(#style_titlebar, #style_sysmenu) \
			modal:true
	)

	on OKButton pressed do
	(
		if ProfileName.text.count > 0 do
		(
			NewName = ProfileName.text
			destroyDialog W3DNewProfile
		)
	)

	on CancelButton pressed do destroyDialog W3DNewProfile
)

rollout W3DMergePrompt "Keep Current Scene ?" width:165 height:90 silentErrors:false
(
	button OKButton "OK" pos:[45,65] width:75
	radioButtons actionRadio labels:#( "Import as new scene", "Add to current scene") default:1 columns:1 pos:[23,20]

	fn Open=
	(
		createDialog W3DMergePrompt style:#(#style_titlebar) modal:true
	)

	on OKButton pressed do
	(
		if actionRadio.state == 1 then
		(
			destroyDialog W3DMergePrompt
			if getSaveRequired() do checkForSave()
			resetMaxFile #noPrompt
		)

		else destroyDialog W3DMergePrompt

	)
)

rollout W3DNotFound "File Not Found" width:400 height:120 silentErrors:false
(
	label message "" pos:[200,20] align:#center
	button browseButon "Browse" pos:[230,80] width:75
	button cancelButton "Cancel" pos:[315,80] width:75

	fn Open XYpos=
	(
		createDialog W3DNotFound style:#(#style_titlebar, #style_sysmenu) \
			modal:true
	)

	on W3DNotFound open do message.text = notFoundString
	on CancelButton pressed do destroyDialog W3DNotFound
)

rollout SelectFromMixDlg "Select W3D File" width:300 height:400 silentErrors:true
(
	local FileSelected

	listBox W3DList height:27 items:MixFilesArray
	button SelectButton "Select" pos:[127,375] width:75
	button CancelButton "Cancel" pos:[217,375] width:75

	fn open=
	(
		createDialog SelectFromMixDlg style:#(#style_titlebar, #style_sysmenu) \
			modal:true

		return FileSelected;
	)

	on CancelButton pressed do
	(
		FileSelected = undefined
		destroyDialog SelectFromMixDlg
	)

	on SelectButton pressed do
	(
		FileSelected = W3DList.selected
		destroyDialog SelectFromMixDlg
	)
)

rollout W3DImportDlg "W3D Importer" width:718 height:575 silentErrors:false
(
	local DefaultW3DPath
	local W3DFileName, W3DFileOffset, W3DSOF, W3DEOF, PropW3DName
	local MeshesCount, LODCount, BonesCount, AggregatesCount, ProxiesCount, BoxesCount, DazzlesCount, SubObjectsCount
	local AnimFrameCount, AnimFrameRate, AnimChannelCount, AnimBones = #(), AnimInfo = #()
	local BitChannelCount, BitBones = #(), BitInfo = #()
	local DazzleArray = #(), AggregateArray = #(), ProxyArray = #(), BoxesArray = #(), BonesArray = #(), PivotFixups = #(), BoundingBoxesArray = #()
	local MeshesSelected = #(), ProxiesSelected = #(), AggregatesSelected = #(), DazzlesSelected = #()
	local ExportedMeshes = #(), UnsuportedMeshes = #(), MeshesNames = #(), DazzlesNames = #()
	local LODModelsArray = #(), CurrentLODRange = #(0,0)
	local ImportSelectedOnly = false
	local ItemSelected = 0
	local OriginBone = #(), OriginNeeded = #()
	local W3DMeshes = #(), W3DMeshParents = #(), W3DBones = #()
	local CreateLODBones = false, DepBonesOnly = false, CreateOrigin = false, ImportBonesOnly = false
	local isHierarchical = false, isAnimated = false, MeshExported = false, isSingleMesh = false, isBitAnimated = false
	local isVehicle = false, isCharacter = false
	local CurrentProfile = W3DImporterInit.CurrentProfile
	local UseOneProfile = W3DImporterInit.UseOneProfile
	local VehiclesBones = #("*wheelc*", "*wheelp*", "*rotor*", "*taillight*", "*headlight*", "*turret*", "*seat*", "v_*")
	local CharsBones = #("*pelvis*", "*spine*", "*neck*", "*clavicle*", "*gunbone*", "*backgunbone*")
	local DazzleINI = getdir #maxroot + "Plugins\dazzle.ini"
	local W3DHierarchyFile, W3DAnimationFile, W3DHLODFile, W3DObjectsFile = #()
	local MeshIndex, MultipleLODFiles, numImportedMesh
	local MeshVertsBindArray = #()
	local PercentDone = 0, OldPercentDone = 0
	local W3DMin = [0,0,0], W3DMax = [0,0,0], WWSkinCreated = false
	local MixFileName, MixW3DFileName, MixW3DFileOffset, MixW3DFileSize, MixW3DIndex, MixFilesList = #()
	local ImportFromMix = false

	groupBox BonesPropBox "Bones List:" pos:[401,465] width:184 height:98
	listBox BonesPropList pos:[410,483] height:5 items:#("N/A") width:168 selection:0

	groupBox ImportOptions "Import Options:" pos:[4,5] width:710 height:431

	groupBox MeshSelection "Meshes Selection:" width:226 height:261 pos:[13,25]
	MultiListBox MeshToImport pos:[22,43] width:208 height:15
	button mAllButton "All" pos:[23,254] width:64
	button mInvertButton "Invert" pos:[94,254] width:64
	button mClearButton "Clear" pos:[165,254] width:64

	groupBox ProxySelection "Proxies Selection:" width:226 height:261 pos:[246,25]
	MultiListBox ProxyToImport pos:[255,43] width:208 height:15
	button pAllButton "All" pos:[256,254] width:64
	button pInvertButton "Invert" pos:[327,254] width:64
	button pClearButton "Clear" pos:[398,254] width:64

	groupBox AggregateSelection "Aggregates Selection:" width:226 height:192 pos:[479,25]
	MultiListBox AggregateToImport pos:[488,43] width:208 height:10
	button aAllButton "All" pos:[489,187] width:64
	button aInvertButton "Invert" pos:[560,187] width:64
	button aClearButton "Clear" pos:[631,187] width:64

	groupBox DazzleSelection "Dazzles Selection:" width:226 height:200 pos:[479,227]
	MultiListBox DazzleToImport pos:[488,246] width:208 height:10
	button dAllButton "All" pos:[489,395] width:64
	button dInvertButton "Invert" pos:[560,395] width:64
	button dClearButton "Clear" pos:[631,395] width:64

	groupBox FramesOptions "Animation:" width:226 height:61 pos:[13,296]
	checkBox checkAnim "Import Animation Frames" checked:true pos:[23,314]
	radioButtons radioFrames labels:#(" All   ", "") default:1 pos:[23,332]
	spinner fromFrameSpin "From" type:#integer pos:[90,332] fieldwidth:36
	spinner toFrameSpin "To" type:#integer pos:[168,332] fieldwidth:36

	groupBox LODOptions "Level Of Details:" width:226 height:60 pos:[13,367]
	radioButtons radioLOD labels:#("Import All Level Of Details", "Select Range:") default:1 columns:1 pos:[23,386]
	spinner fromLODSpin "From" type:#integer pos:[114,402] fieldwidth:24
	spinner toLODSpin "To" type:#integer pos:[180,402] fieldwidth:24

	groupBox BonesOptions "Bones:" width:226 height:131 pos:[246,296]
	checkBox checkBones "Import Bones" checked:true pos:[256,314]
	checkBox checkDepBones "Bones in Selection's Hierarchy Only" checked:false pos:[256,333]
  	checkBox checkOrigin "Create Origin Bone" checked:false pos:[256,352]
	checkBox checkLODBones "Create A Set Of Bones For Each LOD" checked:false pos:[256,371]
	button BonesOnlyButton "Import Bones Only" pos:[281,395] width:156

	groupBox W3DProperties "W3D File Properties:" pos:[4,446] width:590 height:126

	label NameProplbl "Name :" pos:[23,465]
	label NameProptxt "N/A" width:200 pos:[65,465] align:#left

	label TypeProplbl "Type :" pos:[27,485]
	label TypeProptxt "N/A" width:200 pos:[65,485] align:#left

	label LODProplbl "LOD :" pos:[29,505]
	label LODProptxt "N/A" width:37 pos:[65,505] align:#left

	label MeshProplbl "Meshes :" pos:[14,525]
	label MeshProptxt "N/A" width:37 pos:[65,525] align:#left

	label FramesProplbl "Frames :" pos:[17,545]
	label FramesProptxt "N/A" width:37 pos:[65,545] align:#left

	label BonesProplbl "Bones :" pos:[155,505]
	label BonesProptxt "N/A" width:37 pos:[200,505] align:#left

	label AggProplbl "Aggregates :" pos:[131,525]
	label AggProptxt "N/A" widht:37 pos:[200,525] align:#left

	label FrameRateProplbl "Frame Rate :" pos:[130,545]
	label FrameRateProptxt "N/A" width:37 pos:[200,545] align:#left

	label ProxiesProplbl "Proxies :" pos:[287,505]
	label ProxiesProptxt "N/A" width:37 pos:[336,505] align:#left

	label DazzlesProplbl "Dazzles :" pos:[284,525]
	label DazzlesProptxt "N/A" width:37 pos:[336,525] align:#left

	label BoxesProplbl "Boxes :" pos:[292,545]
	label BoxesProptxt "N/A" width:37 pos:[336,545] align:#left

	button ModelOptionsButton "Model Options" pos:[265,466] width:110

	button ImportButton "Import" pos:[610,501] width:100
	button ImportSelButton "Import Selected" pos:[610,472] width:100
	button CancelButton "Cancel" pos:[610,530] width:100


	fn UpdatePropText lbl state text=
	(
		case lbl of
		(
			"Name":
			(
				NameProplbl.enabled = state
				NameProptxt.enabled = state
				NameProptxt.text = text
			)
			"Type":
			(
				TypeProplbl.enabled = state
				TypeProptxt.enabled = state
				TypeProptxt.text = text
			)
			"LOD":
			(
				LODProplbl.enabled = state
				LODProptxt.enabled = state
				LODProptxt.text = text
			)
			"Meshes":
			(
				MeshProplbl.enabled = state
				MeshProptxt.enabled = state
				MeshProptxt.text = text
			)
			"Frames":
			(
				FramesProplbl.enabled = state
				FramesProptxt.enabled = state
				FramesProptxt.text = text
			)
			"Proxies":
			(
				ProxiesProplbl.enabled = state
				ProxiesProptxt.enabled = state
				ProxiesProptxt.text = text
			)
			"Aggregates":
			(
				AggProplbl.enabled = state
				AggProptxt.enabled = state
				AggProptxt.text = text
			)
			"Boxes":
			(
				BoxesProplbl.enabled = state
				BoxesProptxt.enabled = state
				BoxesProptxt.text = text
			)
			"Rate":
			(
				FrameRateProplbl.enabled = state
				FrameRateProptxt.enabled = state
				FrameRateProptxt.text = text
			)
			"Bones":
			(
				BonesProplbl.enabled = state
				BonesProptxt.enabled = state
				BonesProptxt.text = text
			)
			"Dazzles":
			(
				DazzlesProplbl.enabled = state
				DazzlesProptxt.enabled = state
				DazzlesProptxt.text = text
			)
		)
	)

	fn UpdatePropList list state array=
	(
		case list of
		(
			"Bones":
			(
				BonesPropBox.enabled = state
				BonesPropList.enabled = state
				BonesPropList.items = array
			)
			"Meshes":
			(
				MeshToImport.items = array
				MeshSelection.enabled = state
				MeshToImport.enabled = state
				mAllButton.enabled = state
				mInvertButton.enabled = state
				mClearButton.enabled = state
			)
			"Proxies":
			(
				ProxyToImport.items = array
				ProxySelection.enabled = state
				ProxyToImport.enabled = state
				pAllButton.enabled = state
				pInvertButton.enabled = state
				pClearButton.enabled = state
			)
			"Aggregates":
			(
				AggregateToImport.items = array
				AggregateSelection.enabled = state
				AggregateToImport.enabled = state
				aAllButton.enabled = state
				aInvertButton.enabled = state
				aClearButton.enabled = state
			)
			"Dazzles":
			(
				DazzleToImport.items = array
				DazzleSelection.enabled = state
				DazzleToImport.enabled = state
				dAllButton.enabled = state
				dInvertButton.enabled = state
				dClearButton.enabled = state
			)
		)
	)

	fn UpdateImportSelection list cleared=
	(
		case list of
		(
			"Meshes":
			(
				MeshesSelected = #()
				if cleared == false do
				(
					for i = 1 to MeshToImport.items.count do
						if MeshToImport.selection[i] == true do append MeshesSelected MeshToImport.items[i]
				)

				if MeshesSelected.count > 0 then ItemSelected = bit.or ItemSelected 1
				else ItemSelected = bit.and ItemSelected 14
			)

			"Proxies":
			(
				ProxiesSelected = #()
				if cleared == false do
				(
					for i = 1 to ProxyToImport.items.count do
						if ProxyToImport.selection[i] == true do append ProxiesSelected ProxyToImport.items[i]
				)

				if ProxiesSelected.count > 0 then ItemSelected = bit.or ItemSelected 2
				else ItemSelected = bit.and ItemSelected 13
			)

			"Aggregates":
			(
				AggregatesSelected = #()
				if cleared == false do
				(
					for i = 1 to AggregateToImport.items.count do
						if AggregateToImport.selection[i] == true do append AggregatesSelected AggregateToImport.items[i]
				)

				if AggregatesSelected.count > 0 then ItemSelected = bit.or ItemSelected 4
				else ItemSelected = bit.and ItemSelected 11
			)

			"Dazzles":
			(
				DazzlesSelected = #()
				if cleared == false do
				(
					for i = 1 to DazzleToImport.items.count do
						if DazzleToImport.selection[i] == true do append DazzlesSelected DazzleToImport.items[i]
				)

				if DazzlesSelected.count > 0 then ItemSelected = bit.or ItemSelected 8
				else ItemSelected = bit.and ItemSelected 7
			)
		)

		if bit.and ItemSelected 15 > 0 then
		(
			ImportSelButton.enabled = true
			checkDepBones.enabled = checkBones.enabled
		)
		else
		(
			ImportSelButton.enabled = false
			checkDepBones.enabled = false
		)
	)

	fn UpdateLODRange fromLOD toLOD=
	(
		local MeshTmpArray = #(), DazzleTmpArray = #()

		if fromLOD != CurrentLODRange[1] or toLOD != CurrentLODRange[2] do
		(
			for i = 1 to MeshesNames.count by 5 do
				if MeshesNames[i] >= fromLOD and MeshesNames[i] <= toLOD do append MeshTmpArray MeshesNames[i+2]

			MeshToImport.selection = #{}
			UpdatePropList "Meshes" true MeshTmpArray
			UpdateImportSelection "Meshes" true

			for i = 1 to DazzlesNames.count by 5 do
				if DazzlesNames[i] >= fromLOD and DazzlesNames[i] <= toLOD do append DazzleTmpArray DazzlesNames[i+2]

			DazzleToImport.selection = #{}
			UpdatePropList "Dazzles" true DazzleTmpArray
			UpdateImportSelection "Dazzles" true

			CurrentLODRange = #(fromLOD, toLOD)
		)
	)

	fn UpdatePropCheck check state flags=
	(
		local MaxRange

		case check of
		(
			"Bones":
			(
				BonesOptions.enabled = state
				checkBones.enabled = state
				if bit.and flags 1 == 1 then
				(
					checkBones.checked = true
					checkDepBones.enabled = false
					checkDepBones.checked = false
					checkOrigin.enabled = true
					checkLODBones.enabled = if LODCount > 1 then true else false
					checkLODBones.checked = checkLODBones.enabled
					BonesOnlyButton.enabled = true
				)
				else
				(
					checkBones.checked = false
					checkDepBones.enabled = false
					checkDepBones.checked = false
					checkOrigin.enabled = false
					checkOrigin.checked = false
					checkLODBones.enabled = false
					checkLODBones.checked = false
					BonesOnlyButton.enabled = false
				)
			)
			"Frames":
			(
				FramesOptions.enabled = state
				checkAnim.enabled = state

				if bit.and flags 1 == 1 then
				(
					checkAnim.checked = true
					radioFrames.enabled = true
					if radioFrames.state == 2 do flags = bit.or flags 4
				)
				else
				(
					checkAnim.checked = false
					radioFrames.enabled = false
					fromFrameSpin.enabled = false
					toFrameSpin.enabled = false
				)
				if bit.and flags 2 == 2 do
				(
					radioFrames.state = 1
					fromFrameSpin.enabled = false
					toFrameSpin.enabled = false
				)
				if bit.and flags 4 == 4 do
				(
					radioFrames.state = 2
					fromFrameSpin.enabled = true
					toFrameSpin.enabled = true
				)
				if bit.and flags 8 == 8 do
				(
					MaxRange = AnimFrameCount - 1
					fromFrameSpin.range = [0,MaxRange,0]
					toFrameSpin.range = [0,MaxRange, MaxRange]
				)
				if bit.and flags 16 == 16 do
				(
					fromFrameSpin.range = [0,100,0]
					toFrameSpin.range = [0,100,100]
				)
			)
			"LOD":
			(
				LODOptions.enabled = state
				radioLOD.enabled = state

				if bit.and flags 1 == 1 then
				(
					radioLOD.state = 1
					fromLODSpin.enabled = false
					toLODSpin.enabled = false
					UpdateLODRange 0 (LODCount-1)
				)
				if bit.and flags 2 == 2 do
				(
					radioLOD.state = 2
					fromLODSpin.enabled = true
					toLODSpin.enabled = true
					UpdateLODRange fromLODSpin.value toLODSpin.value
				)
				if bit.and flags 4 == 4 do
				(
					fromLODSpin.range = [0,LODCount-1,0]
					toLODSpin.range = [0,LODCount-1,LODCount-1]
				)
				if bit.and flags 8 == 8 do
				(
					radioLOD.state = 1
					fromLODSpin.enabled = false
					toLODSpin.enabled = false
					fromLODSpin.range = [0,3,0]
					toLODSpin.range = [0,3,0]
				)
			)
		)
	)

	fn UpdatePropSpinner spin SpinValue=
	(
		local MaxRange, val

		case spin of
		(
			"FromFrames":
			(
				MaxRange = AnimFrameCount - 1
				val = if toFrameSpin.value < SpinValue then MaxRange else toFrameSpin.value
				toFrameSpin.range = [SpinValue,MaxRange,val]
			)

			"ToFrames":
			(
				val = if fromFrameSpin.value > SpinValue then 0 else fromFrameSpin.value
				fromFrameSpin.range = [0,SpinValue,val]
			)

			"FromLOD":
			(
				val = if toLODSpin.value < SpinValue then LODCount-1 else toLODSpin.value
				toLODSpin.range = [SpinValue,LODCount-1,val]
				UpdateLODRange fromLODSpin.value toLODSpin.value
			)

			"ToLOD":
			(
				val = if fromLODSpin.value > SpinValue then 1 else fromLODSpin.value
				fromLODSpin.range = [0,SpinValue,val]
				UpdateLODRange fromLODSpin.value toLODSpin.value
			)
		)
	)

	fn ResetImporterDlg=
	(
		local propArray = #("Bones", "Meshes", "Proxies", "Aggregates", "Dazzles", "Name", "Type", "LOD", "Frames", "Boxes", "Rate")

		MeshExported = false
		isHierarchical = false
		isAnimated = false
		isBitAnimated = false
		isSingleMesh = false
		isVehicle = false
		isCharacter = false

		MeshesCount = 0
		MeshIndex = 0
		numImportedMesh = 0
		LODCount = 0 
		BonesCount = 0
		ProxiesCount = 0
		AggregatesCount = 0
		BoxesCount = 0
		DazzlesCount = 0
		SubObjectsCount = 0
		AnimFrameCount = 0
		AnimChannelCount = 0
		BitChannelCount = 0
		DazzleArray = #()
		AggregateArray = #()
		ProxyArray = #()
		BoxesArray = #()
		BoundingBoxesArray = #()
		BonesArray = #()
		ExportedMeshes = #()
		UnsuportedMeshes = #()
		MeshesNames = #()
		DazzlesNames = #()
		LODModelsArray = #()
		CurrentLODRange = #(0,0)
		W3DHierarchyFile = ""
		W3DAnimationFile = ""
		W3DHLODFile = ""
		W3DObjectsFile = #()
		MultipleLODFiles = false
		MeshVertexBindArray = #()

		for i = 1 to propArray.count do
		(
			UpdatePropText propArray[i] false "N/A"
			if i <= 5 do UpdatePropList propArray[i] false #("N/A")
		)

		UpdatePropCheck "Bones" false 0
		UpdatePropCheck "LOD" false 8
		UpdatePropCheck "Frames" false 18

		ImportSelButton.enabled = false
		ImportButton.enabled = false
		ModelOptionsButton.enabled = false
	)

	fn AddRecentFile fname fromMix:false=
	(
		local recentsCount = 5

		if findItem W3DImporterInit.recentFiles fname > 0 then
		(
			local tmpRecents = #()
			local recentIndex = findItem W3DImporterInit.recentFiles fname

			if recentsCount > 1 do
			(
				join tmpRecents W3DImporterInit.recentFiles

				while recentsCount > 1 do
				(
					if recentsCount <= recentIndex do tmpRecents[recentsCount] = tmpRecents[recentsCount-1]
					recentsCount -= 1
				)
				tmpRecents[1] = if fromMix then (fname + " (" + MixFileName + ")") else fname
				W3DImporterInit.recentFiles = tmpRecents
			)
		)

		else
		(
			while recentsCount > 1 do
			(
				W3DImporterInit.recentFiles[recentsCount] = W3DImporterInit.recentFiles[recentsCount-1]
				recentsCount -= 1
			)

			W3DImporterInit.recentFiles[1] = if fromMix then (fname + " (" + MixFileName + ")") else fname
		)

		if not fromMix do	mostRecentPath = getFileNamePath fname

		ok
	)
	
	fn GetMostRecentPath=
	(
		DefaultW3DPath = W3DImporterInit.W3DPaths[1]
		if mostRecentPath != undefined then return mostRecentPath;
		else return DefaultW3DPath;
	)

	fn ShowFileNotFound fname W3Dfile:"file:  "=
	(
		messageBox (W3Dfile + (getFileNameFile fname) + ".w3d  not found.")
	)

	fn SkipBytes W3Dstream count=
	(
		local unknown
		case count of
		(
			1: unknown = ReadByte W3Dstream #unsigned
			2: unknown = ReadShort W3Dstream #unsigned
			4: unknown = ReadLong W3Dstream #unsigned
			default:
			(
				for i = 1 to count do
				(
					unknown = ReadByte W3Dstream #unsigned
				)
			)
		)
	)

	fn toLower ch=
	(
		local upper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		local lower = "abcdefghijklmnopqrstuvwxyz"
		local pos = findString upper ch

		if pos != undefined do ch = lower[pos]
		ch
	)
		
	fn ReadW3DNameLen W3Dstream ContainerName:false=
	(
		local ch
		local str = ""
		local containerStr = ""
		local len = if ContainerName then 32 else 16
		local container = false

		for i = 1 to len do
		(
			ch = ReadByte W3Dstream #unsigned

			if ContainerName and (bit.intAsChar ch) == "." then
			(
				if container == false then
				(
					container = true
					containerStr = str
					str = ""
				)
			)
			else str += toLower (bit.intAsChar ch)


			if ch == 0 then
			(
				SkipBytes W3Dstream (len - i)
				exit
			)
		)

		if ContainerName then return #(str, containerStr)
		else return str
	)

	fn ReadNullTerminatedString W3Dstream lower:false=
	(
		local str = ""
		local ch = 1
		while ch != 0 do
		(
			ch = ReadByte W3Dstream #unsigned
			str += if lower then toLower (bit.intAsChar ch) else bit.intAsChar ch
		)

		str
	)

	fn ReadVersion W3Dstream=
	(
		local Min = ReadShort W3Dstream #unsigned
		local Maj = ReadShort W3Dstream #unsigned
		return (Maj as string + "." + Min as string)
	)

	fn ReadPoint3 W3Dstream=
	(
		Local X = ReadFloat W3Dstream
		Local Y = ReadFloat W3Dstream
		Local Z = ReadFloat W3Dstream
		return [X, Y, Z]
	)

	fn ReadColor W3Dstream Alpha:false=
	(
		local R = ReadByte W3Dstream #unsigned
		local G = ReadByte W3Dstream #unsigned
		local B = ReadByte W3Dstream #unsigned
		local A = ReadByte W3Dstream #unsigned

		if Alpha then return (color R G B A) else return (color R G B)
	)

	fn ReadColor2 W3Dstream=
	(
		local R = ReadByte W3Dstream #unsigned
		local G = ReadByte W3Dstream #unsigned
		local B = ReadByte W3Dstream #unsigned

		return (color R G B)
	)

	fn ReadEuler W3Dstream=
	(
		local X = ReadFloat W3Dstream
		local Y = ReadFloat W3Dstream
		local Z = ReadFloat W3Dstream
		return (eulerangles X Y Z)
	)

	fn ReadQuat W3Dstream=
	(
		local X = ReadFloat W3Dstream
		local Y = ReadFloat W3Dstream
		local Z = ReadFloat W3Dstream
		local W = ReadFloat W3Dstream
		return (quat X Y Z W)
	)

	fn ReadMatrix3 W3Dstream=
	(
		local x = ReadFloat W3DStream
		local y = ReadFloat W3DStream
		local z = ReadFloat W3DStream
		local Row0 = [x,y,z]
		x = ReadFloat W3DStream
		y = ReadFloat W3DStream
		z = ReadFloat W3DStream
		local Row1 = [x,y,z]
		x = ReadFloat W3DStream
		y = ReadFloat W3DStream
		z = ReadFloat W3DStream
		local Row2 = [x,y,z]
		x = ReadFloat W3DStream
		y = ReadFloat W3DStream
		z = ReadFloat W3DStream
		local Row3 = [x,y,z]
		return (matrix3 Row0 Row1 Row2 Row3)
	)

	fn CreateBone Type Name CenterPos=
	(
		local Bone, Shape, Size, Color
		local Settings = #()
		local index = (13 * CurrentProfile) - 12

		case Type of
		(
			"Bone":
			(
				Shape = W3DImporterInit.UserProfiles[index]
				Size = W3DImporterInit.UserProfiles[index+1]
				Color = W3DImporterInit.UserProfiles[index+2]
			)

			"Proxy":
			(
				Shape = W3DImporterInit.UserProfiles[index+3]
				Size = W3DImporterInit.UserProfiles[index+4]
				Color = W3DImporterInit.UserProfiles[index+5]
			)

			"Aggregate":
			(
				Shape = W3DImporterInit.UserProfiles[index+6]
				Size = W3DImporterInit.UserProfiles[index+7]
				Color = W3DImporterInit.UserProfiles[index+8]
			)

			"Dazzle":
			(
				Shape = W3DImporterInit.UserProfiles[index+9]
				Size = W3DImporterInit.UserProfiles[index+10]
				Color = W3DImporterInit.UserProfiles[index+11]
			)

			"Origin":
			(
				Shape = 1
				Size = 0.4
				CenterPos = [0.0,0.0,0.0]
				Color = [0,255,0]
			)
		)

		case Shape of
		(
			1: Bone = Box name:Name width:Size height:Size length:Size pos:(CenterPos - [0.0,0.0,(Size/2)]) pivot:CenterPos 
			2: Bone = Sphere name:Name radius:(Size/2) pos:CenterPos pivot:CenterPos 
			3: Bone = Cylinder name:Name radius:(Size/2) height:Size pos:(CenterPos - [0.0,0.0,(Size/2)]) pivot:CenterPos
		)

		Bone.wireColor = Color
		Bone.mapCoords = true

		Bone
	)

	fn getW3DBoneParent parentID lodID=
	(
		local parentW3DBone = 0

		for j = 1 to W3DBones.count by 6 do
		(
			if W3DBones[j+1] != parentID do continue

			if not CreateLODBones then
			(
				if W3DBones[j+3] != "Mesh" and W3DBones[j+4] == 0 then parentW3DBone = j
				else if W3DBones[j+3] == "Mesh" and W3DBones[j+4] == lodID then parentW3DBone = j
			)

			else if W3DBones[j+4] == lodID do parentW3DBone = j
		)

		parentW3DBone
	)

	fn ReadAnimVector W3Dstream isQuat:false=
	(
		if isQuat then return (ReadQuat W3Dstream)
		else return (ReadFloat W3Dstream)
	)

	fn ReadBitAnimVector W3Dstream=
	(
		return (ReadByte W3Dstream)
	)

------------------------------------------- Chunks Structures Definition ---------------------------------------

	

	struct W3D_Chunk_Header
	(
		ID,
		Size,
		Start,
		FlagPresent,

		fn ReadW3D W3Dstream=
		(
			ID = ReadLong W3Dstream #unsigned
			Size = bit.and (ReadLong W3Dstream #unsigned) 0x7fffffff

			W3DFileOffset = ftell W3Dstream
			Start = W3DFileOffset			
		),

		fn getChunkID W3Dstream=
		(
			ID = ReadLong W3Dstream #unsigned
			Size = ReadLong W3Dstream #unsigned
			if (bit.and Size 0x80000000) > 0 do FlagPresent = true
			Size = bit.and Size 0x7fffffff
			Start = ftell W3Dstream
			W3DFileOffset = Start

			ID
		),

		fn FindChunk W3Dstream ChunkID ChunkStart ChunkSize resetOffset:false=
		(
			ID = 0xffffffff
			FlagPresent = false
			Start = ChunkStart

			if resetOffset do W3DFileOffset = ChunkStart

			while ID != ChunkID do
			(
				fseek W3Dstream W3DFileOffset #seek_set

				ID = ReadLong W3Dstream #unsigned
				Size = ReadLong W3Dstream #unsigned
				if (bit.and Size 0x80000000) > 0 do FlagPresent = true
				Size = bit.and Size 0x7fffffff

				W3DFileOffset = ftell W3DStream			

				if ID != ChunkID do W3DFileOffset += Size
				
				if W3DFileOffset > (ChunkStart + (ChunkSize - 1)) then
				(
					W3DFileOffset = ChunkStart
					return false;
				)
			)
			if ID == nothing  then
			(
				return false;
			) else 
			(
				Start = W3DFileOffset			
				return true;
			)
		)		
	)

	struct W3D_Hierarchy
	(
		ID,
		Size,
		Start,
		IsValid,

		fn ReadW3D W3Dstream=
		(
			ID = ReadLong W3Dstream #unsigned
			Size = bit.and (ReadLong W3Dstream #unsigned) 0x7fffffff
			IsValid= if ID == 0x100 then true else false

			W3DFileOffset = ftell W3Dstream
			Start = W3DFileOffset
		),

		IsValid
	)

	Struct W3D_Hierarchy_Header
	(
		Version,
		Name,
		NumBones,
		Origin,

		fn ReadW3D W3Dstream=
		(
			Version = ReadVersion W3Dstream
			Name = ReadW3DNameLen W3Dstream
			NumBones = ReadLong W3Dstream #unsigned
			Origin = ReadPoint3 W3Dstream

			W3DFileOffset = ftell W3Dstream			
		)
	)

	Struct W3D_Pivots
	(
		Name,
		ParentID,
		Translation,
		Euler,
		Rotation,

		fn ReadW3D W3Dstream=
		(
			Name = ReadW3DNameLen W3Dstream
			ParentID = ReadLong W3Dstream #unsigned
			Translation = ReadPoint3 W3Dstream
			Euler = ReadEuler W3Dstream
			Rotation = ReadQuat W3Dstream

			W3DFileOffset = ftell W3Dstream
		)
	)

	Struct W3D_Pivot_Fixups
	(
		PivotMatrix3,

		fn ReadW3D W3Dstream=
		(
			PivotMatrix3 = ReadMatrix3 W3Dstream

			W3DFileOffset = ftell W3Dstream
		)
	)

	Struct W3D_Animation_Header
	(
		Version,
		Name,
		HierarchyName,
		NumFrames,
		FrameRate,

		fn ReadW3D W3Dstream=
		(
			Version = ReadVersion W3Dstream
			Name = ReadW3DNameLen W3Dstream
			HierarchyName = ReadW3DNameLen W3Dstream
			NumFrames = ReadLong W3Dstream #unsigned
			FrameRate = ReadLong W3Dstream #unsigned

			W3DFileOffset = ftell W3Dstream
		)
	)
	
	Struct W3D_Animation_Channel
	(
		FirstFrame,
		LastFrame,
		ChannelType,
		Pivot,
		VectorLen,
		Pad,

		fn ReadW3D W3Dstream=
		(
			FirstFrame = ReadShort W3Dstream #unsigned
			LastFrame = ReadShort W3Dstream #unsigned
			VectorLen = ReadShort W3Dstream #unsigned
			ChannelType = ReadShort W3Dstream #unsigned
			Pivot = ReadShort W3Dstream #unsigned
			Pad = ReadShort W3Dstream #unsigned

			W3DFileOffset = ftell W3Dstream
		)
	)

	Struct W3D_Bit_Channel
	(
		FirstFrame,
		LastFrame,
		ChannelType,
		Pivot,
		DefaultVal,

		fn ReadW3D W3Dstream=
		(
			FirstFrame = ReadShort W3Dstream #unsigned
			LastFrame = ReadShort W3Dstream #unsigned
			ChannelType = ReadShort W3Dstream #unsigned
			Pivot = ReadShort W3Dstream #unsigned
			DefaultVal = ReadByte W3Dstream #unsigned

			W3DFileOffset = ftell W3Dstream
		)
	)

	Struct W3D_Compressed_Animation_Header
	(
		Version,
		Name,
		HierarchyName,
		NumFrames,
		FrameRate,
		Type,

		fn ReadW3D W3Dstream=
		(
			Version = ReadVersion W3Dstream
			Name = ReadW3DNameLen W3Dstream
			HierarchyName = ReadW3DNameLen W3Dstream
			NumFrames = ReadLong W3Dstream #unsigned
			FrameRate = ReadShort W3Dstream #unsigned
			Type = ReadShort W3Dstream #unsigned

			W3DFileOffset = ftell W3Dstream
		)
	)

	Struct W3D_TimeCoded_Animation_Channel
	(
		NumTimeCodes,
		Pivot,
		VectorLen,
		ChannelType,

		fn ReadW3D W3Dstream=
		(
			NumTimeCodes = ReadShort W3Dstream #unsigned
			Pivot = ReadShort W3Dstream #unsigned
			VectorLen = ReadByte W3Dstream #unsigned
			ChannelType = ReadByte W3Dstream #unsigned

			W3DFileOffset = ftell W3Dstream
		)
	)

	Struct W3D_TimeCoded_Bit_Channel
	(
		NumTimeCodes,
		Pivot,
		ChannelType,
		DefaultVal,

		fn ReadW3D W3Dstream=
		(
			NumTimeCodes = ReadLong W3Dstream #unsigned
			Pivot = ReadShort W3Dstream #unsigned
			ChannelType = ReadByte W3Dstream #unsigned
			DefaultVal = ReadByte W3Dstream #unsigned

			W3DFileOffset = ftell W3Dstream
		)
	)

	Struct W3D_AdaptiveDelta_Animation_Channel
	(
		NumFrames,
		Pivot,
		VectorLen,
		ChannelType,
		Scale,

		fn ReadW3D W3Dstream=
		(
			NumFrames = ReadLong W3Dstream #unsigned
			Pivot = ReadShort W3Dstream #unsigned
			VectorLen = ReadByte W3Dstream #unsigned
			ChannelType = ReadByte W3Dstream #unsigned
			Scale = ReadFloat W3Dstream

			W3DFileOffset = ftell W3Dstream
		)
	)

	Struct W3D_Mesh_Header3
	(
		Version,
		Flags,
		Name,
		Container,
		NumTris,
		NumVert,
		NumMat,
		NumDam,
		SortLevel,
		PrelitVer,
		FutureCnt,
		VertexChan,
		FaceChan,
		MMin,
		MMax,
		SphCenter,
		SphRadius,

		fn ReadW3D W3Dstream=
		(
			Version = ReadVersion W3Dstream
			Flags = ReadLong W3Dstream #unsigned
			Name = ReadW3DNameLen W3Dstream
			Container = ReadW3DNameLen W3Dstream
			NumTris = ReadLong W3Dstream #unsigned
			NumVert = ReadLong W3Dstream #unsigned
			NumMat = ReadLong W3Dstream #unsigned
			NumDam = ReadLong W3Dstream #unsigned
			SortLevel = ReadLong W3Dstream #unsigned
			PrelitVer = ReadLong W3Dstream #unsigned
			FutureCnt = ReadLong W3Dstream #unsigned
			VertexChan = ReadLong W3Dstream #unsigned
			FaceChan = ReadLong W3Dstream #unsigned
			MMin = ReadPoint3 W3Dstream
			MMax = ReadPoint3 W3Dstream
			SphCenter = ReadPoint3 W3Dstream
			SphRadius = ReadFloat W3Dstream

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_Vertices
	(
		Position,

		fn ReadW3D W3Dstream=
		(
			Position = ReadPoint3 W3Dstream

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_Vertex_Normals
	(
		Normal,

		fn ReadW3D W3Dstream=
		(
			Normal = ReadPoint3 W3Dstream

			W3DFileOffset = ftell W3Dstream			
		)
	)
		
	struct W3D_Triangles
	(
		TriIndices,
		Flags,
		Normal,
		Dist,

		fn ReadW3D W3Dstream=
		(
			Local v1 = ReadLong W3Dstream #unsigned
			Local v2 = ReadLong W3Dstream #unsigned
			Local v3 = ReadLong W3Dstream #unsigned
			TriIndices = [v1 + 1, v2 + 1, v3 + 1]
			Flags = ReadLong W3Dstream #unsigned
			Normal = ReadPoint3 W3Dstream
			Dist = ReadFloat W3Dstream

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_Vertex_Influence
	(
		BoneIndex,
		Pad = #(),

		fn ReadW3D W3Dstream=
		(
			local p
			BoneIndex = ReadShort W3Dstream #unsigned
			for i = 1 to 6 do
			(
				p = ReadByte W3Dstream #unsigned
				append Pad p
			)

			W3DFileOffset = ftell W3Dstream
		)
	)

	struct W3D_Vertex_Shades_Indices
	(
		Index,

		fn ReadW3D W3Dstream=
		(
			Index = ReadLong W3Dstream #unsigned

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_Material_Info
	(
		PassCount,
		VMaterialCount,
		ShaderCount,
		TextureCount,

		fn ReadW3D W3Dstream=
		(
			PassCount = ReadLong W3Dstream #unsigned
			VMaterialCount = ReadLong W3Dstream #unsigned
			ShaderCount = ReadLong W3Dstream #unsigned
			TextureCount = ReadLong W3Dstream #unsigned

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_Texture_Info
	(
		Attrib,
		AnimType,
		FrameCount,
		FrameRate,

		fn ReadW3D W3Dstream=
		(
			Attrib = ReadShort W3Dstream #unsigned
			AnimType = ReadShort W3Dstream #unsigned
			FrameCount = ReadLong W3Dstream #unsigned
			FrameRate = ReadFloat W3Dstream

			W3DFileOffset = ftell W3Dstream
		)
	)

	struct W3D_Vertex_Material_Name
	(
		Name,

		fn ReadW3D W3Dstream=
		(
			Name = ReadNullTerminatedString W3Dstream

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_Vertex_Material_Info
	(
		Flags,
		Ambient,
		Diffuse,
		Specular,
		Emissive,
		Shininess,
		Opacity,
		Translucency,

		fn ReadW3D W3Dstream=
		(
			Flags = ReadLong W3Dstream #unsigned
			Ambient = ReadColor W3Dstream
			Diffuse = ReadColor W3Dstream
			Specular = ReadColor W3Dstream
			Emissive = ReadColor W3Dstream
			Shininess = ReadFloat W3Dstream
			Opacity = ReadFloat W3Dstream
			Translucency = ReadFloat W3Dstream

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_Shader_Info
	(
		DepthCompare,
		DepthMask,
		ColorMask,
		DestBlend,
		FogFunc,
		PriGradient,
		SecGradient,
		SrcBlend,
		Texturing,
		DetailColorFunc,
		DetailAlphaFunc,
		ShaderPreset,
		AlphaTest,
		PostDetailColorFunc,
		PostDetailAlphaFunc,
		pad,

		fn ReadW3D W3Dstream=
		(
			DepthCompare = ReadByte W3Dstream #unsigned
			DepthMask = ReadByte W3Dstream #unsigned
			ColorMask = ReadByte W3Dstream #unsigned
			DestBlend = ReadByte W3Dstream #unsigned
			FogFunc = ReadByte W3Dstream #unsigned
			PriGradient = ReadByte W3Dstream #unsigned
			SecGradient = ReadByte W3Dstream #unsigned
			SrcBlend = ReadByte W3Dstream #unsigned
			Texturing = ReadByte W3Dstream #unsigned
			DetailColorFunc = ReadByte W3Dstream #unsigned
			DetailAlphaFunc = ReadByte W3Dstream #unsigned
			ShaderPreset = ReadByte W3Dstream #unsigned
			AlphaTest = ReadByte W3Dstream #unsigned
			PostDetailColorFunc = ReadByte W3Dstream #unsigned
			PostDetailAlphaFunc = ReadByte W3Dstream #unsigned
			pad = ReadByte W3Dstream
			W3DFileOffset = ftell W3Dstream
		)
	)

	struct W3D_Texture_Name
	(
		Name,

		fn ReadW3D W3Dstream=
		(
			Name = ReadNullTerminatedString W3Dstream

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_Texture_ID
	(
		ID,

		fn ReadW3D W3Dstream=
		(
			ID = ReadLong W3Dstream #unsigned
			ID += 1

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_Stage_TextCoords
	(
		UVW,

		fn ReadW3D W3Dstream=
		(
			Local X = ReadFloat W3Dstream
			Local Y = ReadFloat W3Dstream
			UVW = [X, Y, 0]

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_Vertex_DCG
	(
		VertexColor,
		VertexAlpha,
		VertexIsAlpha,

		fn ReadW3D W3Dstream=
		(
			VertexIsAlpha = true
			VertexColor = ReadColor2 W3Dstream
			VertexAlpha = ReadByte W3Dstream
			if VertexColor.r != 255 do
			(
				VertexIsAlpha = false
			)
			if VertexColor.g != 255 do
			(
				VertexIsAlpha = false
			)
			if VertexColor.b != 255 do
			(
				VertexIsAlpha = false
			)
			W3DFileOffset = ftell W3Dstream
		)
	)

	struct W3D_HLod_Header
	(
		Version,
		LodCount,
		Name,
		HTreeName,

		fn ReadW3D W3Dstream=
		(
			Version = ReadVersion W3Dstream
			LodCount = ReadLong W3Dstream #unsigned
			Name = ReadW3DNameLen W3Dstream
			HTreeName = ReadW3DNameLen W3Dstream

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_HModel_Header
	(
		Version,
		Name,
		HTreeName,
		NumConnections,

		fn ReadW3D W3Dstream=
		(
			Version = ReadVersion W3Dstream
			Name = ReadW3DNameLen W3Dstream
			HTreeName = ReadW3DNameLen W3Dstream
			NumConnections = ReadShort W3DStream #unsigned 
			local temp = ReadShort W3DStream #unsigned 
			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_HLod_Array_Header
	(
		ModelCount,
		MaxScreenSize,

		fn ReadW3D W3Dstream=
		(
			ModelCount = ReadLong W3Dstream #unsigned
			MaxScreenSize = ReadFloat W3Dstream

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_HLod_Sub_Object
	(
		BoneIndex,
		Name,
		Container,

		fn ReadW3D W3Dstream=
		(
			BoneIndex = ReadLong W3Dstream #unsigned
			local W3DName = ReadW3DNameLen W3Dstream ContainerName:true
			Name = W3DName[1]
			Container = W3DName[2]

			W3DFileOffset = ftell W3Dstream
		)
	)

	struct W3D_HModel_Node
	(
		Name,
		BoneIndex,

		fn ReadW3D W3Dstream=
		(
			Name = ReadW3DNameLen W3Dstream
			BoneIndex = ReadShort W3Dstream #unsigned
			W3DFileOffset = ftell W3Dstream
		)
	)

	struct W3D_Box
	(
		Version,
		Flags,
		Name,
		Container,
		BoxColor,
		Pos,
		Extent,

		fn ReadW3D W3Dstream=
		(
			Version = ReadVersion W3Dstream
			Flags = ReadLong W3Dstream #unsigned
			local W3DName = ReadW3DNameLen W3Dstream ContainerName:true
			Name = W3DName[1]
			Container = W3DName[2]
			BoxColor = ReadColor W3Dstream
			Pos = ReadPoint3 W3Dstream
			Extent = ReadPoint3 W3Dstream

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_Null_Object
	(
		Version,
		Flags,
		Pad,
		Name,
		Container,

		fn ReadW3D W3Dstream=
		(
			Version = ReadVersion W3Dstream
			Flags = ReadLong W3Dstream #unsigned
			Pad = ReadLong W3Dstream #unsigned
			local W3DName = ReadW3DNameLen W3Dstream ContainerName:true
			Name = W3DName[1]
			Container = W3DName[2]

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_Dazzle_Name
	(
		Name,
		Container,

		fn ReadW3D W3Dstream=
		(
			local W3DName = ReadW3DNameLen W3Dstream ContainerName:true
			Name = W3DName[1]
			Container = W3DName[2]

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct W3D_Dazzle_TypeName
	(
		Name,

		fn ReadW3D W3Dstream=
		(
			Name = ReadNullTerminatedString W3Dstream lower:false

			W3DFileOffset = ftell W3Dstream			
		)
	)

	struct Mix_File
	(
		MixID,
		MixFilesOffset,
		MixNamesOffset,
		MixNumFilesNames,
		MixNumFiles,
		MixFileID,
		MixFileOffset,
		MixFileSize,

		fn ReadMix MixStream=
		(
			local mixStr = ""

			for i = 1 to 4 do	mixStr += bit.IntAsChar (readByte MixStream #unsigned)
			MixID = mixStr
			if MixID != "MIX1" then return false;

			MixFilesOffset = (ReadLong MixStream #unsigned)
			MixNamesOffset = ReadLong MixStream #unsigned

			return true;
		),

		fn getMixFilesNames MixStream=
		(
			local filesNames = #()

			fseek MixStream MixNamesOffset #seek_Set

			MixNumFilesNames = ReadLong MixStream #unsigned

			for i = 1 to MixNumFilesNames do
			(
				local nameStr = ""
				local NameLen = ReadByte MixStream #unsigned

				for j = 1 to NameLen do nameStr += bit.IntAsChar (readByte MixStream #unsigned)
				append filesNames nameStr
			)

			return filesNames
		),
			
		fn getMixFile MixStream FileIndex=
		(
			local fileIndexOffset

			fseek MixStream MixFilesOffset #seek_Set

			MixNumFiles = ReadLong MixStream #unsigned
			if MixNumFiles != MixNumFilesNames then
			(
				print "Error: Num Files doesnt match Num Files Names !"
				format "MixNumFiles = %, MixNumFilesNames = %\n" MixNumFiles MixNumFilesNames
				return false;
			)
			fileIndexOffset = ftell MixStream

			fileIndexOffset += (12 * (FileIndex-1))
			fseek MixStream fileIndexOffset #seek_Set

			MixFileID = ReadLong MixStream #unsigned
			MixFileOffset = ReadLong MixStream #unsigned
			MixFileSize = ReadLong MixStream #unsigned

			return true;
		)
	)
		


-------------------------------------------------- W3D Importer ------------------------------------------------

	struct W3D_Importer
	(
		W3Dchunk = W3D_Chunk_Header(),
		W3Dheader = W3D_Hierarchy(),
		W3DHierarchyHeader = W3D_Hierarchy_Header(),
		W3DAnimChannel = W3D_Animation_Channel(),
		W3DBitChannel = W3D_Bit_Channel(),
		W3DPivots = W3D_Pivots(),
		W3DPivotFixups = W3D_Pivot_Fixups(),
		W3DBox = W3D_Box(),
		W3DDazzleName = W3D_Dazzle_Name(),
		W3DDazzleType = W3D_Dazzle_TypeName(),
		W3DAnimHeader = W3D_Animation_Header(),
		W3DCompressedAnimHeader = W3D_Compressed_Animation_Header(),
		W3DHLodHeader = W3D_HLod_Header(),
		W3DHLodArrayHeader = W3D_HLod_Array_Header(),
		W3DHLodSubObject = W3D_HLod_Sub_Object(),
		W3DHModelHeader = W3D_HModel_Header(),
		W3DHModelNode = W3D_HModel_Node(),
		W3DMeshHeader = W3D_Mesh_Header3(),
		W3Dvert = W3D_Vertices(),
		W3DvNormal = W3D_Vertex_Normals(),
		W3Dtriangle = W3D_Triangles(),
		W3DVertInf = W3D_Vertex_Influence(),
		W3Dtvert = W3D_Stage_TextCoords(),
		W3DVMaterialName = W3D_Vertex_Material_Name(),
		W3DVMatInfo = W3D_Vertex_Material_Info(),
		W3DShaderInfo = W3D_Shader_Info(),
		W3DMaterialInfo = W3D_Material_Info(),
		W3DTextureInfo = W3D_Texture_Info(),
		W3DTextureName = W3D_Texture_Name(),
		W3DTextureID = W3D_Texture_ID(),
		W3DDCG = W3D_Vertex_DCG(),
		MixFile = Mix_File(),
		W3Dstream,

		fn getMix=
		(
			local MixStream = fopen MixFileName "rb"

			MixFile.ReadMix MixStream
			MixFilesList = MixFile.getMixFilesNames MixStream

			fclose MixStream
		),

		fn OpenW3D fname=
		(
			if ImportFromMix then
			(
				W3Dstream = fopen MixFileName "rb"
				MixW3DIndex = findItem MixFilesList fname

				MixFile.getMixFile W3Dstream MixW3DIndex
				W3DSOF = MixFile.MixFileOffset
				W3DEOF = MixFile.MixFileOffset + MixFile.MixFileSize
			)

			else
			(
				W3Dstream = fopen fname "rb"

				W3DSOF = 0
				fseek W3Dstream 0 #seek_end
				W3DEOF = ftell W3Dstream
			)

			W3DFileOffset = W3DSOF
			fseek W3Dstream W3DFileOffset #seek_set

			ok
		),
		
		fn CloseW3D=
		(
			fclose W3Dstream
			ok
		),
		
		fn CheckSelectedW3D filename=
		(
			local ChunkHeaderStart, ChunkHeaderSize
			local	FileDontMatchHName = false

			OpenW3D filename
			if W3Dchunk.FindChunk W3Dstream 0x00000600 W3DSOF W3DEOF do 
			(
				MessageBox "Nothing To Import"
				return false
			)

			if W3Dchunk.FindChunk W3Dstream 0x00000100 W3DSOF W3DEOF do
			(
				W3Dchunk.FindChunk W3Dstream 0x00000101 W3DSOF W3DEOF

				W3DHierarchyHeader.ReadW3D W3Dstream
				if not matchPattern W3DHierarchyHeader.Name pattern:(getFileNameFile filename) do FileDontMatchHName = true

				W3DHierarchyFile = filename
				PropW3DName = W3DHierarchyHeader.Name + "." + W3DHierarchyHeader.Name
			)

			if W3Dchunk.FindChunk W3Dstream 0x00000200 W3DSOF W3DEOF resetOffset:true do
			(
				ChunkHeaderStart = W3Dchunk.Start
				ChunkHeaderSize = W3Dchunk.Size
				W3DAnimationFile = filename

				if W3DHierarchyFile != filename do
				(
					W3Dchunk.FindChunk W3Dstream 0x00000201 ChunkHeaderStart ChunkHeaderSize
					W3DAnimHeader.ReadW3D W3Dstream

					if ImportFromMix then W3DHierarchyFile = W3DAnimHeader.HierarchyName + ".W3D"
					else W3DHierarchyFile = (getFileNamePath filename) + W3DAnimHeader.HierarchyName + ".w3d"
					PropW3DName = W3DAnimHeader.HierarchyName + "." + W3DAnimHeader.Name
				)
			)

			if W3Dchunk.FindChunk W3Dstream 0x00000700 W3DSOF W3DEOF resetOffset:true do
			(
				ChunkHeaderStart = W3Dchunk.Start
				ChunkHeaderSize = W3Dchunk.Size
				W3DHLODFile = filename
				IsHModel = false

				if W3DHierarchyFile != filename then
				(
					W3Dchunk.FindChunk W3Dstream 0x00000701 ChunkHeaderStart ChunkHeaderSize
					W3DHLODHeader.ReadW3D W3Dstream

					if ImportFromMix then W3DHLODHeader.HTreeName + ".W3D"
					else W3DHierarchyFile = (getFileNamePath filename) + W3DHLODHeader.HTreeName + ".w3d"
					PropW3DName = W3DHLODHeader.HTreeName + "." + W3DHLODHeader.Name
				)
				else if FileDontMatchHName do
				(
					W3Dchunk.FindChunk W3Dstream 0x00000701 ChunkHeaderStart ChunkHeaderSize
					W3DHLODHeader.ReadW3D W3Dstream

					if not matchPattern W3DHLODHeader.Name pattern:(getFileNameFile filename) then
					(
						messageBox ("Error: File name does not match w3d name     \n\n   File Name :  " + \
							(getFileNameFile filename) + ".W3D\nW3D Name :  " + W3DHLODHeader.Name)
						return false;
					)

					PropW3DName = W3DHLODHeader.HTreeName + "." + W3DHLODHeader.Name
				)
			)

			if W3Dchunk.FindChunk W3Dstream 0x00000300 W3DSOF W3DEOF resetOffset:true do
			(
				ChunkHeaderStart = W3Dchunk.Start
				ChunkHeaderSize = W3Dchunk.Size
				W3DHLODFile = filename
				IsHModel = true

				if W3DHierarchyFile != filename then
				(
					W3Dchunk.FindChunk W3Dstream 0x00000301 ChunkHeaderStart ChunkHeaderSize
					W3DHModelHeader.ReadW3D W3Dstream

					if ImportFromMix then W3DHModelHeader.HTreeName + ".W3D"
					else W3DHierarchyFile = (getFileNamePath filename) + W3DHModelHeader.HTreeName + ".w3d"
					PropW3DName = W3DHModelHeader.HTreeName + "." + W3DHModelHeader.Name
				)
				else if FileDontMatchHName do
				(
					W3Dchunk.FindChunk W3Dstream 0x00000301 ChunkHeaderStart ChunkHeaderSize
					W3DHModelHeader.ReadW3D W3Dstream

					if not matchPattern W3DHModelHeader.Name pattern:(getFileNameFile filename) then
					(
						messageBox ("Error: File name does not match w3d name     \n\n   File Name :  " + \
							(getFileNameFile filename) + ".W3D\nW3D Name :  " + W3DHModelHeader.Name)
						return false;
					)

					PropW3DName = W3DHModelHeader.HTreeName + "." + W3DHModelHeader.Name
				)
			)

			CloseW3D
			
			if ImportFromMix then
			(
				if findItem MixFilesList W3DHierarchyFile > 0 then return true;
				else
				(
					ShowFileNotFound W3DHierarchyFile W3Dfile:"Skeleton file:  "
					return false
				)
			)

			else
			(
				if DoesFileExist W3DHierarchyFile then return true
				else
				(
					ShowFileNotFound W3DHierarchyFile W3Dfile:"Skeleton file:  "
					return false
				)
			)

		),

		fn GetW3DHierarchy=
		(
			local ChunkID, ChunkHeaderStart, ChunkHeaderSize

			OpenW3D W3DHierarchyFile

			W3Dchunk.FindChunk W3Dstream 0x00000100 W3DSOF W3DEOF

			ChunkHeaderStart = W3Dchunk.Start
			ChunkHeaderSize = W3Dchunk.Size


			while W3DFileOffset < (ChunkHeaderStart + ChunkHeaderSize) do
			(
				fseek W3Dstream W3DFileOffset #seek_set
				ChunkID = W3Dchunk.getChunkID W3Dstream

				case ChunkID of
				(
					0x00000101:
					(
						W3DHierarchyHeader.ReadW3D W3Dstream
						wwSetBoneCount W3DHierarchyHeader.NumBones
					)
					0x00000102:
					(
						local bPos

						for i = 1 to W3DHierarchyHeader.NumBones do
						(
							W3DPivots.ReadW3D W3Dstream
							if i > 1 do
							(
								bPos = W3DPivots.Translation
								j = (6 * W3DPivots.ParentID) - 5
								if W3DPivots.ParentID > 0 then
								(
									bPos = bPos + BonesArray[j+2]
								)
								wwSetBone W3DPivots.Translation W3DPivots.Rotation (i - 1) W3DPivots.ParentID
								join BonesArray #(W3DPivots.Name, W3DPivots.ParentID, bPos, W3DPivots.Rotation, W3DPivots.Rotation, undefined)
							)
						)
					)
					0x00000103:
					(
						for i = 1 to W3DHierarchyHeader.NumBones do
						(
							W3DPivotFixups.ReadW3D W3DStream
							if i > 1 do append PivotFixups W3DPivotFixups.PivotMatrix3
						)
					)

					default: W3DFileOffset = W3Dchunk.Start + W3Dchunk.Size
				)
			)

			CloseW3D

			return true;
		),

		fn GetW3DAnimation=
		(
			local ChunkID, ChunkHeaderStart, ChunkHeaderSize, NextChunk

			if ImportFromMix then
			(
				if findItem MixFilesList W3DAnimationFile == 0 then
				(
					ShowFileNotFound W3DAnimationFile W3DFile:"Animation File:  "
					return false;
				)
			)

			else
			(
				if not DoesFileExist W3DAnimationFile then
				(
					ShowFileNotFound W3DAnimationFile W3DFile:"Animation File:  "
					return false;
				)
			)

			OpenW3D W3DAnimationFile

			if (W3Dchunk.FindChunk W3Dstream 0x00000200 W3DSOF W3DEOF) or (W3Dchunk.FindChunk W3Dstream 0x00000280 W3DSOF W3DEOF resetOffset:true) do
			(
				ChunkHeaderStart = W3Dchunk.Start
				ChunkHeaderSize = W3Dchunk.Size
				NextChunk = ChunkHeaderStart + ChunkHeaderSize
			)

			while W3DFileOffset < NextChunk do
			(
				fseek W3Dstream W3DFileOffset #seek_set
				ChunkID = W3Dchunk.getChunkID W3Dstream

				case ChunkID of
				(
					0x00000201:
					(
						W3DAnimHeader.ReadW3D W3Dstream
					
						AnimFrameCount = W3DAnimHeader.NumFrames
						AnimFrameRate = W3DAnimHeader.FrameRate
					)
					0x00000202:
					(
						AnimChannelCount += 1
						W3DAnimChannel.ReadW3D W3Dstream
						join AnimBones #(W3DAnimChannel.Pivot, W3DAnimChannel.VectorLen, W3DFileOffset)
						join AnimInfo #(W3DAnimChannel.ChannelType, W3DAnimChannel.FirstFrame, W3DAnimChannel.LastFrame)
						W3DFileOffset = W3Dchunk.Start + W3Dchunk.Size
					)
					0x00000203:
					(
						BitChannelCount += 1
						W3DBitChannel.ReadW3D W3Dstream
						join BitBones #(W3DBitChannel.Pivot, W3DFileOffset)
						join BitInfo #(W3DBitChannel.DefaultVal, W3DBitChannel.FirstFrame, W3DBitChannel.LastFrame)
						W3DFileOffset = W3Dchunk.Start + W3Dchunk.Size
					)
					0x00000281:
					(
						W3DCompressedAnimHeader.ReadW3D W3Dstream
					
						AnimFrameCount = W3DCompressedAnimHeader.NumFrames
						AnimFrameRate = W3DCompressedAnimHeader.FrameRate
						W3DFileOffset = ChunkHeaderStart + ChunkHeaderSize
					)
					default: W3DFileOffset = NextChunk
				)
			)

			CloseW3D
			return true;
		),

		fn GetW3DHLOD=
		(
			local	HLODArrayStart, HLODArraySize, AggregateArrayStart
			local AggregateArraySize, ProxyArrayStart, i, ProxyArraySize
			local ChunkID, ChunkHeaderStart, ChunkHeaderSize

			if ImportFromMix then
			(
				if findItem MixFilesList W3DHLODFile == 0 then
				(
					ShowFileNotFound W3DHLODFile W3DFile:"LOD Hierarchy file:  "
					return false;
				)
			)

			else
			(
				if not DoesFileExist W3DHLODFile then
				(
					ShowFileNotFound W3DHLODFile W3DFile:"LOD Hierarchy file:  "
					return false;
				)
			)

			OpenW3D W3DHLODFile
			if not IsHModel then
			(
				W3Dchunk.FindChunk W3Dstream 0x00000700 W3DSOF W3DEOF

				ChunkHeaderStart = W3Dchunk.Start
				ChunkHeaderSize = W3Dchunk.Size
	
				while W3DFileOffset < (ChunkHeaderStart + ChunkHeaderSize) do
				(
					fseek W3Dstream W3DFileOffset #seek_set
					ChunkID = W3Dchunk.getChunkID W3Dstream
	
					case ChunkID of
					(
						0x00000701:
						(
							W3DHLODHeader.ReadW3D W3dstream
							LODCount = W3DHLODHeader.LODCount
	
							local i = LODCount
							local numObjectsFiles = 0
							while i > 0 do
							(
								i -= 1
	
								W3Dchunk.FindChunk W3Dstream 0x00000702 ChunkHeaderStart ChunkHeaderSize
	
								HLODArrayStart = W3Dchunk.Start
								HLODArraySize = W3Dchunk.Size
	
								W3Dchunk.FindChunk W3Dstream 0x00000703 HLODArrayStart HLODArraySize
								W3DHLODArrayHeader.ReadW3D W3Dstream
	
								for j = 1 to W3DHLODArrayHeader.ModelCount do
								(
									W3Dchunk.FindChunk W3Dstream 0x00000704 HLODArrayStart HLODArraySize
	
									W3DHLODSubObject.ReadW3D W3Dstream
									join LODModelsArray #(i, W3DHLODSubObject.Name, W3DHLODSubObject.BoneIndex) 
								)
	
								local ObjectFile
	
								if W3DHLODArrayHeader.ModelCount == 0 then ObjectFile = W3DHLODFile
	
								else
								(
									if ImportFromMix then ObjectFile = W3DHLODSubObject.Container + ".w3d"
									else ObjectFile = (getFileNamePath W3DHLODFile) + W3DHLODSubObject.Container + ".w3d"
								)
								if findItem W3DObjectsFile ObjectFile > 0 then W3DObjectsFile[i+1] = ""
								else
								(
									numObjectsFiles += 1
									W3DObjectsFile[i+1] = ObjectFile
									if numObjectsFiles > 1 do MultipleLODFiles = true
								)
							)
						)

						0x00000705:
						(
							AggregateArrayStart = W3Dchunk.Start
							AggregateArraySize = W3Dchunk.Size

							W3DFileOffset = W3Dchunk.Start
	
							W3Dchunk.FindChunk W3Dstream 0x00000703 AggregateArrayStart AggregateArraySize
							W3DHLODArrayHeader.ReadW3D W3Dstream
							AggregatesCount = W3DHLODArrayHeader.ModelCount

							for i = 1 to AggregatesCount do
							(
								W3Dchunk.FindChunk W3Dstream 0x00000704 AggregateArrayStart AggregateArraySize
								W3DHLODSubObject.ReadW3D W3Dstream

								join AggregateArray #(W3DHLODSubObject.Name, W3DHLODSubObject.BoneIndex)
							)
						)
	
						0x00000706:
						(
							local ProxyArrayStart = W3Dchunk.Start
							local ProxyArraySize = W3Dchunk.Size
	
							W3DFileOffset = W3Dchunk.Start
	
							W3Dchunk.FindChunk W3Dstream 0x00000703 ProxyArrayStart ProxyArraySize
							W3DHLODArrayHeader.ReadW3D W3Dstream
							ProxiesCount = W3DHLODArrayHeader.ModelCount
	
							for i = 1 to ProxiesCount do
							(
								W3Dchunk.FindChunk W3Dstream 0x00000704 ProxyArrayStart ProxyArraySize
								W3DHLODSubObject.ReadW3D W3Dstream
								if W3DHLODSubObject.BoneIndex > 0 do
								(
									j = (6 * W3DHLODSubObject.BoneIndex) - 5
									append ProxyArray BonesArray[j]
								)
							)
						)

						default: W3DFileOffset = W3Dchunk.Start + W3Dchunk.Size
					)
				)
			)
			else
			(
				W3Dchunk.FindChunk W3Dstream 0x00000300 W3DSOF W3DEOF

				ChunkHeaderStart = W3Dchunk.Start
				ChunkHeaderSize = W3Dchunk.Size
				while W3DFileOffset < (ChunkHeaderStart + ChunkHeaderSize) do
				(
					fseek W3Dstream W3DFileOffset #seek_set
					ChunkID = W3Dchunk.getChunkID W3Dstream
	
					case ChunkID of
					(
						0x00000301:
						(
							W3DHModelHeader.ReadW3D W3dstream
							LODCount = 1
						)
						0x00000302:
						(
							W3DHModelNode.ReadW3D W3Dstream
							join LODModelsArray #(1, W3DHModelNode.Name, W3DHModelNode.BoneIndex)
						)
						0x00000303:
						(
							W3DHModelNode.ReadW3D W3Dstream
							join LODModelsArray #(1, W3DHModelNode.Name, W3DHModelNode.BoneIndex)
						)
						0x00000304:
						(
							W3DHModelNode.ReadW3D W3Dstream
							join LODModelsArray #(1, W3DHModelNode.Name, W3DHModelNode.BoneIndex)
						)
						default: W3DFileOffset = W3Dchunk.Start + W3Dchunk.Size
					)
				)
				local ObjectFile
				if W3DHModelHeader.NumConnections == 0 then ObjectFile = W3DHLODFile
				else
				(
					if ImportFromMix then ObjectFile = W3DHModelHeader.HTreeName + ".w3d"
					else ObjectFile = (getFileNamePath W3DHLODFile) + W3DHModelHeader.HTreeName + ".w3d"
				)
				local numObjectsFiles = 0
				if findItem W3DObjectsFile ObjectFile > 0 then 
				(
					W3DObjectsFile[1] = ""
				)
				else
				(
					numObjectsFiles += 1
					W3DObjectsFile[1] = ObjectFile
					if numObjectsFiles > 1 do MultipleLODFiles = true
				)
			)
			CloseW3D
			return true;
		),

		fn GetW3DObjects filename=
		(
			local ChunkID

			if ImportFromMix then
			(
				if findItem MixFilesList filename == 0 then
				(
					local fileStr = if MultipleLODFiles then "LOD File:  " else "File:  "
					ShowFileNotFound filename W3DFile:fileStr
					return false;
				)
			)

			else
			(
				if not DoesFileExist filename then
				(
					local fileStr = if MultipleLODFiles then "LOD File:  " else "File:  "
					ShowFileNotFound filename W3DFile:fileStr
					return false;
				)
			)
		
			OpenW3D filename

			while W3DFileOffset < W3DEOF do
			(
				fseek W3Dstream W3DFileOffset #seek_set
				ChunkID = W3Dchunk.getChunkID W3Dstream

				case ChunkID of
				(
					0x00000000:
					(
						W3DFileOffset = W3Dchunk.Start
						NextObjectOffset = W3Dchunk.Start + W3Dchunk.Size
					)
					0x0000001f:
					(
						W3DMeshHeader.ReadW3D W3Dstream
						append ExportedMeshes W3DMeshHeader.Name
						W3DFileOffset = NextObjectOffset
					)

					0x00000740:
					(
						W3DBox.ReadW3D W3DStream

						join BoxesArray #(W3DBox.Name, W3DBox.BoxColor, W3DBox.Pos, W3DBox.Extent, W3DBox.Flags)
						BoxesCount += 1
					)

					0x00000900: W3DFileOffset = W3Dchunk.Start
					0x00000901:
					(
						W3DDazzleName.ReadW3D W3Dstream
						append DazzleArray W3DDazzleName.Name
						W3DFileOffset = W3Dchunk.Start + W3Dchunk.size
					)
					0x00000902:
					(
						W3DDazzleType.ReadW3D W3Dstream
						append DazzleArray W3DDazzleType.Name
						W3DFileOffset = W3Dchunk.Start + W3Dchunk.size
					)

					default: W3DFileOffset = W3Dchunk.Start + W3Dchunk.Size
				)
			)

			CloseW3D
			return true;
		),


		fn UpdateImporterDlg=
		(
			local MeshTmpArray = #(), DazzleTmpArray = #(), BoneTmpArray = #()

			if PropW3DName != Undefined then UpdatePropText "Name" true PropW3DName
			else UpdatePropText "Name" true fname

			if LODCount > 1 then
			(
				UpdatePropCheck "LOD" true 5
				UpdatePropText "LOD" true (LODCount as string)
			)
			else
			(
				UpdatePropCheck "LOD" false 9
				UpdatePropText "LOD" true (LODCount as string)
			)


			if AnimFrameCount > 0 then
			(
				UpdatePropCheck "Frames" true 11
				UpdatePropText "Frames" true (AnimFrameCount as string)
				UpdatePropText "Rate" true (AnimFrameRate as string)
				isAnimated = true
			)
			else
			(
				UpdatePropCheck "Frames" false 18
				UpdatePropText "Frames" true "N/A"
				UpdatePropText "Rate" true "N/A"
			)
			if BitChannelCount > 0 then
			(
				isBitAnimated = true
			)
			if LODModelsArray.count > 0 then
			(
				local ObjectName, ObjectNameFixed, RealObjectName, CurrentLOD, ParentBone
				local ExistInAnotherLOD, SeparateLODFile

				for i = 1 to LODModelsArray.count by 3 do
				(
					CurrentLOD = LODModelsArray[i]
					ObjectName = LODModelsArray[i+1]
					ParentBone = LODModelsArray[i+2]

					ExistsInOtherLOD = false
					individualLODFile = false

					if findItem BoxesArray ObjectName > 0 do continue

					if LODCount > 1 then
					(
						if ObjectName[ObjectName.count] == (CurrentLOD as string) then
						(
							local TestLOD = LODCount - 1
 
							While TestLOD >= 0 do
							(
								if TestLOD != CurrentLOD and ExistsInOtherLOD == false do
								(
									local TestName = substring ObjectName 1 (ObjectName.count - 1) + TestLOD as string 
									j = findItem LODModelsArray TestName

									if j > 0 do
										if TestName[TestName.count] == LODModelsArray[j-1] as string do
											ExistsInOtherLOD = true
								)

								TestLOD -= 1
							)
						)

						else if W3DObjectsFile[CurrentLOD+1] != "" do individualLODFile = true
					)

					else
					(
						if W3DObjectsFile[1] == W3DHLODFile do
						(
							local TestPattern = substring W3DHLODFile 1 (W3DHLODFile.count-7) + "_l?.W3D"
							if matchPattern W3DHLODFile pattern:TestPattern do
							(
								CurrentLOD = W3DHLODFile[W3DHLODFile.count-4] as integer
								individualLODFile = true
							)
						)
					)

					if ExistsInOtherLOD then
					(
						RealObjectName = substring ObjectName 1 (ObjectName.count - 1)
						ObjectNameFixed = RealObjectName + ".0" + CurrentLOD as string
					)

					else
					(
						RealObjectName = ObjectName
						ObjectNameFixed = if individualLODFile then RealObjectName + ".0" + CurrentLOD as string else ObjectName
					)
					
					local MeshNameExists = findItem MeshesNames ObjectNameFixed
					local DazzleNameExists = findItem DazzlesNames ObjectNameFixed
					if MeshNameExists == 0 and DazzleNameExists == 0 then
					(
						if findItem ExportedMeshes ObjectName > 0 do
						(
							join MeshesNames #(CurrentLOD, ObjectName, ObjectNameFixed, RealObjectName, ParentBone)
							append MeshTmpArray ObjectNameFixed
						)
						if findItem DazzleArray ObjectName > 0 do
						(
							join DazzlesNames #(CurrentLOD, ObjectName, ObjectNameFixed, RealObjectName, ParentBone)
							append DazzleTmpArray ObjectNameFixed
						)
					)

					else format "Mesh % already exists\n" ObjectNameFixed
				)
			)


			if MeshTmpArray.count > 0 then
			(
				MeshesCount = MeshTmpArray.count

				UpdatePropList "Meshes" true MeshTmpArray
				UpdatePropText "Meshes" true (MeshesCount as string)

				MeshExported = true
				if MeshesCount == 1 do isSingleMesh = true 

				MeshTmpArray = #()
			)
			else
			(
				UpdatePropList "Meshes" false #("N/A")
				UpdatePropText "Meshes" true "0"
			)

			if DazzleTmpArray.count > 0 then
			(
				UpdatePropList "Dazzles" true DazzleTmpArray
				UpdatePropText "Dazzles" true (DazzleTmpArray.count as string)
				DazzleTmpArray = #()
			)
			else
			(
				UpdatePropList "Dazzles" false #("N/A")
				UpdatePropText "Dazzles" true "0"
			)

			if AggregatesCount > 0 then
			(
				local AggtmpArray = #()

				for i = 1 to AggregateArray.count by 2 do append AggTmpArray AggregateArray[i]

				UpdatePropList "Aggregates" true AggTmpArray
				UpdatePropText "Aggregates" true (AggTmpArray.count as string)
			)
			else
			(
				UpdatePropText "Aggregates" true "0"
				UpdatePropList "Aggregates" false #("N/A")
			)

			if ProxiesCount > 0 then 
			(
				local ProxyTmpArray = #()

				for i = 1 to ProxyArray.count do append ProxyTmpArray ProxyArray[i]

				UpdatePropList "Proxies" true ProxyTmpArray
				UpdatePropText "Proxies" true (ProxiesCount as string)
			)

			else
			(
				UpdatePropList "Proxies" false #("N/A")
				UpdatePropText "Proxies" true "0"
			)

			if BoxesCount > 0 then UpdatePropText "Boxes" true (BoxesCount as string)
			else UpdatePropText "Boxes" true "0"

			for i = 1 to BonesArray.count by 6 do
			(
				for j = 1 to VehiclesBones.count do if matchPattern BonesArray[i] pattern:VehiclesBones[j] do isVehicle = true
				for j = 1 to CharsBones.count do if matchPattern BonesArray[i] pattern:CharsBones[j] do isCharacter = true

				if findstring BonesArray[i] "~" == undefined and findItem DazzlesNames BonesArray[i] == 0 do
					append BoneTmpArray BonesArray[i]
			)

			if BoneTmpArray.count > 0 then
			(

				UpdatePropList "Bones" true BoneTmpArray
				UpdatePropCheck "Bones" true 1
				UpdatePropText "Bones" true (BoneTmpArray.count as string)

				for i = 1 to BonesArray.count by 6 do if (BonesArray[i+1] as integer) > 0 do isHierarchical = true
				BoneTmpArray = #()
			)
			else
			(
				UpdatePropList "Bones" false #("N/A")
				UpdatePropCheck "Bones" false 0
				UpdatePropText "Bones" true "0"
			)

			local ExportType = "N/A"

			if MeshExported then
			(
				if isHierarchical then
				(
					if isAnimated or isBitAnimated then ExportType = "Hierarchical Animated Model"
					else ExportType = "Hierarchical Model"

					if isVehicle do ExportType += " (Vehicle)"
					if isCharacter do ExportType += " (Character)"
				)
				else
				(
					if isAnimated or isBitAnimated then ExportType = "Hierarchical Animated Model"
					else if isSingleMesh then ExportType = "Single Mesh"
					else ExportType = "Renegade Terrain"
				)
			)

			else 
			(
				if isAnimated or isBitAnimated then ExportType = "Pure Animation"
				else ExportType = "Skeleton"

				if isCharacter do ExportType += " (Character)"
			)

			UpdatePropText "Type" true ExportType
			ImportButton.enabled = true
		),

		fn ConvertW3D currentLOD=
		(
			local SelMeshToImport = #()
			local W3DMesh, MeshParent
			local MeshChunkStart, MeshChunkSize
			local MeshVertices, MeshFaces, MeshSurfaceType, MeshVertsNormals, MeshFacesNormals, MeshTVerts, VertsBones
			local MaterialNames, MapperArgs0, MapperArgs1, TextureNames, TextureIDs, VerticesColor, VerticesAlpha, VerticesIsAlpha, ShaderIDs, MaterialIDs
			local CurMat, CurTex, CurPass, Stages
			local VertexMaterial, VertexMaterialInfo, VMatInfos, ShaderInfo, ShaderInfos, TextureInfo, TextureInfos, vmTexture, vmInfo, tInfo, sInfo
			local vmPassCount, vmCount, vmShaderCount, vmTextureCount
			local ChunkID
			local UnknownMat = 0


			OpenW3D W3DObjectsFile[currentLOD+1]

			W3DImportProgressDlg.Stage.text = ("Building Meshes...")

			if not UseOneProfile do
			(
				if IsVehicle do CurrentProfile = W3DImporterInit.VehicleProfile
				if IsCharacter do CurrentProfile = W3DImporterInit.CharProfile
			)

			if checkBones.checked do
			(
				if checkOrigin.checked and checkOrigin.enabled do CreateOrigin = true
				if checkLODBones.checked and checkLODBones.enabled do CreateLODBones = true
			)

			if MeshExported and not ImportBonesOnly do
			(

			if checkDepBones.checked and checkDepBones.enabled do DepBonesOnly = true

			if ImportSelectedOnly do
			(
				local profileIndex = (13 * CurrentProfile) - 12
				local CreateMeshesBones = W3DImporterInit.UserProfiles[profileIndex+12] 

				for i = 1 to MeshesSelected.count do
				(
					local MeshName = MeshesSelected[i]
					local m_Index = 0, ParentBone

					for j = 1 to MeshesNames.count by 5 do
					(
						if MeshesNames[j+2] == MeshName then
						(
							append SelMeshToImport MeshesNames[j+1]
							m_Index = j
							exit;
						)
					)

					if checkBones.checked and DepBonesOnly and m_Index > 0 and not CreateMeshesBones do
					(
						local ParentBone = MeshesNames[m_Index+4]

						while ParentBone > 0 do
						(
							j = (6 * ParentBone) - 5
							local BoneName = BonesArray[j]
							ParentBone = BonesArray[j+1]

							for j = 1 to MeshesNames.count by 5 do
							(
								if MeshesNames[j+3] == BoneName then
								(
									append SelMeshToImport MeshesNames[j+1]
									exit
								)
							)
						)
					)
				)

				if checkBones.checked and not DepBonesOnly and not CreateMeshesBones do
				(
					for i = 1 to MeshesNames.count by 5 do
					(
						if findItem BonesArray MeshesNames[i+3] > 0 then
						(
							append SelMeshToImport MeshesNames[i+1]
						)
					)
				)
			)

			for i = 1 to MeshesCount do
			(
				local MeshLOD, LODSelected = true, SkipMesh = false, SkinVertsOffset

				MeshParent = 0
				MeshVertices = #()
				MeshFaces = #()
				MeshSurfaceType = 0
				MeshVertsNormals = #()
				MeshFacesNormals = #()
				MeshTVerts = #()
				VertsBones = #()
				VerticesColor = #()
				VerticesAlpha = #()
				VerticesIsAlpha = #()
				MaterialNames = #()
				CurMat = 0
				CurTex = 0
				CurPass = 0
				Stages = #()
				VMatInfos = #()
				ShaderInfos = #()
				MapperArgs0 = #()
				MapperArgs1 = #()
				TextureInfos = #()
				TextureNames = #()
				TextureIDs = #()
				VMaterials = #()
				ShaderIDs = #()
				MaterialIDs = #()
				vmPassCount = 0
				vmCount = 0
				vmShaderCount = 0
				vmTextureCount = 0
				isWWSkin = false
				local hasnormals = false

				if W3Dchunk.FindChunk W3Dstream 0x00000000 W3DSOF W3DEOF then
				(
					MeshIndex += 1
					MeshChunkStart = W3Dchunk.Start
					MeshChunkSize = W3Dchunk.Size

					W3DFileOffset = W3Dchunk.start
				)
				else exit
				while W3DFileOffset < (MeshChunkStart + MeshChunkSize) do
				(
					fseek W3Dstream W3DFileOffset #seek_set
					ChunkID = W3Dchunk.getChunkID W3Dstream

					case ChunkID of
					(
						0x0000001f:
						(
							W3DMeshHeader.ReadW3D W3Dstream

							if MultipleLODFiles then
							(
								for j = 1 to LODModelsArray.count by 3 do
								(
									if LODModelsArray[j] == currentLOD and LODModelsArray[j+1] == W3DMeshHeader.Name then
									(
										MeshParent = LODModelsArray[j+2]
										MeshLOD = currentLOD
										exit;
									)
								)
							)
							else
							(
								local mIndex = findItem LODModelsArray W3DMeshHeader.Name
								if mIndex != 0 do	MeshParent = LODModelsArray[mIndex+1]

								for j = 1 to MeshesNames.count by 5 do
								(
									if MeshesNames[j+1] == W3DMeshHeader.Name then
									(
										MeshLOD = MeshesNames[j]
										exit;
									)
								)
							)

							if radioLOD.state == 2 and (MeshLOD < CurrentLODRange[1] or MeshLOD > CurrentLODRange[2]) do
								LODSelected = false

							if (ImportSelectedOnly and findItem SelMeshToImport W3DMeshHeader.Name == 0) or not LODSelected do
							(
								W3DFileOffset = MeshChunkStart + MeshChunkSize

								PercentDone = 100*MeshIndex/MeshesCount
								if PercentDone != OldPercentDone do
								(
									OldPercentDone = PercentDone
									W3DImportProgressDlg.Progress.value = PercentDone
									W3DImportProgressDlg.Percent.text = ((PercentDone as string) + " %")
								)

								SkipMesh = true
								exit;
							)

							for j = 1 to MeshesNames.count by 5 do
							(
								if MeshesNames[j+1] == W3DMeshHeader.Name and MeshesNames[j] == MeshLOD then
								(
									W3DMeshHeader.Name = MeshesNames[j+2]
									exit;
								)
							)

							numImportedMesh += 1
						)

						0x0000000c:
						(
							ReadNullTerminatedString W3Dstream
							W3DFileOffset = ftell W3Dstream
						)

						0x00000002:
						(
							for j = 1 to W3DMeshHeader.NumVert do
							(
								W3Dvert.ReadW3D W3Dstream
								append MeshVertices W3Dvert.Position
							)
						)

						0x00000003:
						(
							for j = 1 to W3DMeshHeader.NumVert do
							(
								W3DvNormal.ReadW3D W3Dstream
								append MeshVertsNormals W3DvNormal.Normal
							)
							hasnormals = true
						)
	
						0x00000020:
						(
							for j = 1 to W3DMeshHeader.NumTris do
							(
								W3Dtriangle.ReadW3D W3Dstream
								append MeshFaces W3Dtriangle.TriIndices
								append MeshFacesNormals W3Dtriangle.Normal
								MeshSurfaceType = W3Dtriangle.Flags
							)
						)

						0x00000022:
						(
							for j = 1 to W3DMeshHeader.NumVert do
							(
								local tmp = ReadLong W3Dstream #unsigned
							)

							W3DFileOffset = ftell W3Dstream
						)

						0x0000000e:
						(
							for j = 1 to BonesArray.count by 6 do append VertsBones (#())
							for j = 1 to W3DMeshHeader.NumVert do
							(
								W3DVertInf.ReadW3D W3Dstream
								if W3DVertInf.BoneIndex > 0 do
								(
									append VertsBones[W3DVertInf.BoneIndex] j
								)

								k = (6 * W3DVertInf.BoneIndex) - 5
								local l = MeshVertices[j]
								MeshVertices[j] = wwTransformVertex l W3DVertInf.BoneIndex
								if hasnormals then
								(
									local n = MeshVertsNormals[j]
									MeshVertsNormals[j] = wwTransformNormal l W3DVertInf.BoneIndex
								)
							)
							join MeshVertsBindArray #(MeshLOD, numImportedMesh, VertsBones)

							isWWSkin = true
						)
/*


				if bit.and W3DmeshHeader.Flags 0x02000000 > 0x00000000 then
				else if bit.and W3DmeshHeader.Flags 0x04000000 > 0x00000000 then
				else if bit.and W3DmeshHeader.Flags 0x08000000 > 0x00000000 then
				
*/

						0x00000024: W3DFileOffset = W3Dchunk.Start

						0x00000028:
						(
							W3DMaterialInfo.ReadW3D W3Dstream
							vmPassCount = W3DMaterialInfo.PassCount
							vmCount = W3DMaterialInfo.VMaterialCount
							vmShaderCount = W3DMaterialInfo.ShaderCount
							vmTextureCount = W3DMaterialInfo.TextureCount
						)

						0x0000002a: W3DFileOffset = W3Dchunk.Start

						0x0000002b: W3DFileOffset = W3Dchunk.Start

						0x0000002c:
						(
							W3DVMaterialName.ReadW3D W3Dstream
							append MaterialNames W3DVMaterialName.Name
							CurMat += 1
							if W3DVMaterialName.Name == "WireColor" do
							(
								vmPassCount = 0
							)
						)

						0x0000002d:
						(
							VertexMaterialInfo = #()
							W3DVMatInfo.ReadW3D W3Dstream
							append VertexMaterialInfo W3DVMatInfo.Flags
							append VertexMaterialInfo W3DVMatInfo.Ambient
							append VertexMaterialInfo W3DVMatInfo.Diffuse
							append VertexMaterialInfo W3DVMatInfo.Specular
							append VertexMaterialInfo W3DVMatInfo.Emissive
							append VertexMaterialInfo W3DVMatInfo.Shininess
							append VertexMaterialInfo W3DVMatInfo.Opacity
							append VertexMaterialInfo W3DVMatInfo.Translucency
							append VMatInfos VertexMaterialInfo
							W3DFileOffset = W3Dchunk.Start + W3Dchunk.Size
							append MapperArgs0 undefined
							append MapperArgs1 undefined
						)

						0x00000029:
						(
							for sc = 1 to vmShaderCount do
							(
								ShaderInfo = #()
								W3DShaderInfo.ReadW3D W3Dstream
								append ShaderInfo W3DShaderInfo.DepthCompare
								append ShaderInfo W3DShaderInfo.DepthMask
								append ShaderInfo W3DShaderInfo.ColorMask
								append ShaderInfo W3DShaderInfo.DestBlend
								append ShaderInfo W3DShaderInfo.FogFunc
								append ShaderInfo W3DShaderInfo.PriGradient
								append ShaderInfo W3DShaderInfo.SecGradient
								append ShaderInfo W3DShaderInfo.SrcBlend
								append ShaderInfo W3DShaderInfo.Texturing
								append ShaderInfo W3DShaderInfo.DetailColorFunc
								append ShaderInfo W3DShaderInfo.DetailAlphaFunc
								append ShaderInfo W3DShaderInfo.ShaderPreset
								append ShaderInfo W3DShaderInfo.AlphaTest
								append ShaderInfo W3DShaderInfo.PostDetailColorFunc
								append ShaderInfo W3DShaderInfo.PostDetailAlphaFunc
								append ShaderInfos ShaderInfo
							)
						)

						0x0000002e:
						(
							local args = ReadNullTerminatedString W3Dstream
							MapperArgs0[CurMat] = args
							W3DFileOffset = ftell W3Dstream
						)
						0x0000002f:
						(
							local args = ReadNullTerminatedString W3Dstream
							MapperArgs1[CurMat] = args
							W3DFileOffset = ftell W3Dstream
						)

						0x00000030: W3DFileOffset = W3Dchunk.start

						0x00000031: W3DFileOffset = W3Dchunk.start

						0x00000032:
						(
							W3DTextureName.ReadW3D W3Dstream
							append TextureNames W3DTextureName.Name
							CurTex += 1
							append TextureInfos undefined
						)

						0x00000033:
						(
							TextureInfo = #()
							W3DTextureInfo.ReadW3D W3Dstream
							append TextureInfo W3DTextureInfo.Attrib
							append TextureInfo W3DTextureInfo.AnimType
							append TextureInfo W3DTextureInfo.FrameCount
							append TextureInfo W3DTextureInfo.FrameRate
							TextureInfos[CurTex] = TextureInfo
						)

						0x00000038: 
						(
							CurPass += 1
							W3DFileOffset = W3Dchunk.start
							append VerticesColor undefined
							append VerticesAlpha undefined
							append VerticesIsAlpha true
							local stage = 0
							append Stages stage
							append TextureIDs undefined
							append TextureIDs undefined
							append MeshTVerts undefined
							append MeshTVerts undefined
						)

						0x00000039:
						(
							W3DTextureID.ReadW3D W3Dstream
							append MaterialIDs W3DTextureID.ID
							W3DFileOffset = W3Dchunk.Start + W3Dchunk.Size
						)

						0x0000003a:
						(
							W3DTextureID.ReadW3D W3Dstream
							append ShaderIDs W3DTextureID.ID
							W3DFileOffset = W3Dchunk.Start + W3Dchunk.Size
						)

						0x0000003b:
						(
							local VerticesCol = #()
							local VerticesAl = #()
							for j = 1 to W3DMeshHeader.NumVert do
							(
								W3DDCG.ReadW3D W3Dstream
								append VerticesCol W3DDCG.VertexColor
								append VerticesAl W3DDCG.VertexAlpha
								VerticesIsAlpha[CurPass] = W3DDCG.VertexIsAlpha
 							)
							VerticesColor[CurPass] = VerticesCol
							VerticesAlpha[CurPass] = VerticesAl
							W3DFileOffset = W3Dchunk.Start + W3Dchunk.Size
						)

						0x00000048:
 						(
							Stages[CurPass] += 1
							W3DFileOffset = W3Dchunk.start
						)

						0x00000049:
						(
							W3DTextureID.ReadW3D W3Dstream
							local Stage = Stages[CurPass] - 1
							local val = CurPass - 1
							local val3 = val * 2
							local val2 = val3 + Stage + 1
							TextureIDs[val2] = W3DTextureID.ID
							W3DFileOffset = W3Dchunk.Start + W3Dchunk.Size
						)

						0x0000004a:
						(
							local TVerts = #()
							for j = 1 to W3DmeshHeader.NumVert do
							(
								W3Dtvert.ReadW3D W3Dstream
								append TVerts W3Dtvert.UVW
							)
							local Stage = Stages[CurPass] - 1
							local val = CurPass - 1
							local val3 = val * 2
							local val2 = val3 + Stage + 1
							MeshTVerts[val2] = TVerts
						)

						default:
						(
							W3DFileOffset = W3Dchunk.Start + W3Dchunk.Size
						)
					)
				)

				if SkipMesh do continue

				W3DMesh = mesh name:W3dMeshHeader.Name \
					numverts:W3DmeshHeader.NumVert numfaces:W3DmeshHeader.NumTris

				setMesh W3DMesh vertices:MeshVertices faces:MeshFaces

				for j = 1 to W3DmeshHeader.NumTris do
				(				
					setFaceNormal W3DMesh j MeshFacesNormals[j]
					setFaceSmoothGroup W3DMesh j 1
				)

				if vmPassCount > 0 do
				(
					local newmat = false
					local tindex2 = 0
					if MaterialNames[1] != undefined then
					(
						local m = 0
						if Materials.count > 0 then
						(
							for i = 1 to Materials.count while m != undefined do
							(
								m = Materials[i]
								if MaterialNames[1] != Materials[i].name do
								(
									m = undefined
								)
								if wwGetSortLevel VertexMaterial != W3DMeshHeader.SortLevel then
								(
									m = undefined
								)
								if wwGetSurfaceType VertexMaterial != MeshSurfaceType then
								(
									m = undefined
								)
								if wwGetPassCount VertexMaterial != vmPassCount then
								(
									m = undefined
								)
								for j = 1 to vmPassCount do
								(
									vmInfo = VMatInfos[MaterialIDs[j]]
									local pass = j - 1
									if wwGetMatFlags VertexMaterial pass != vmInfo[1] then
									(
										m = undefined
									)
									local args = wwGetMapperArgs VertexMaterial pass 0
									if args != MapperArgs0[j] then
									(
										m = undefined
									)
									local args2 = wwGetMapperArgs VertexMaterial pass 1
									if args2 != MapperArgs1[j] then
									(
										m = undefined
									)
									if wwGetAmbient VertexMaterial pass != vmInfo[2] then
									(
										m = undefined
									)
									if wwGetDiffuse VertexMaterial pass != vmInfo[3] then
									(
										m = undefined
									)
									if wwGetSpecular VertexMaterial pass != vmInfo[4] then
									(
										m = undefined
									)
									if wwGetEmissive VertexMaterial pass != vmInfo[5] then
									(
										m = undefined
									)
									if wwGetShininess VertexMaterial pass != vmInfo[6] then
									(
										m = undefined
									)
									if wwGetOpacity VertexMaterial pass != vmInfo[7] then
									(
										m = undefined
									)
									if wwGetTranslucency VertexMaterial pass != vmInfo[8] then
									(
										m = undefined
									)
									sInfo = ShaderInfos[ShaderIDs[j]]
									if wwGetDepthCompare VertexMaterial pass != sInfo[1] then
									(
										m = undefined
									)
									local b;
									if sInfo[2] == 0 then
									(
										b = false
									)
									else
									(
										b = true
									)
									if wwGetWriteZBuffer VertexMaterial pass != b then
									(
										m = undefined
									)
									if wwGetDestBlend VertexMaterial pass != sInfo[4] then
									(
										m = undefined
									)
									if wwGetPriGradient VertexMaterial pass != sInfo[6] then
									(
										m = undefined
									)
									if wwGetSecGradient VertexMaterial pass != sInfo[7] then
									(
										m = undefined
									)
									if wwGetSrcBlend VertexMaterial pass != sInfo[8] then
									(
										m = undefined
									)
									if wwGetDetailColor VertexMaterial pass != sInfo[10] then
									(
										m = undefined
									)
									if wwGetDetailAlpha VertexMaterial pass != sInfo[11] then
									(
										m = undefined
									)
									if sInfo[13] == 1 then
									(
										b = true
									)
									else
									(
										b = false
									)
									if wwGetAlphaTestFlag VertexMaterial pass != b then
									(
										m = undefined
									)
									if Stages[j] > 0 do
									(
										for k = 1 to Stages[j] do
										(
											tindex2 += 1
											local stage = k - 1
											local z = (pass * 2) + stage
											local val = z + 1
											if TextureIDs[val] != undefined do
											(
												if TextureNames[TextureIDs[val]] != undefined do
												(
													local tex = wwGetTexture VertexMaterial z
													local tex2 = TextureNames[TextureIDs[val]] as name
													if tex != tex2 then
													(
														m = undefined
													)
													if TextureInfos[TextureIDs[val]] != undefined do
													(
														tInfo = TextureInfos[TextureIDs[val]]
														if wwGetTexFlags VertexMaterial pass stage != tInfo[1] then
														(
															m = undefined
														)
														if wwGetAnimType VertexMaterial pass stage != tInfo[2] then
														(
															m = undefined
														)
														if wwGetFrames VertexMaterial pass stage != tInfo[3] then
														(
															m = undefined
														)
														if wwGetFrameRate VertexMaterial pass stage != tInfo[4] then
														(
															m = undefined
														)
													)
												)
												if wwGetUV VertexMaterial pass stage != tindex2 then
												(
													m = undefined
												)
											)
										)
									)
								)
							)
						)
						else
						(
							m = undefined
						)
						if m == undefined then
						(
							VertexMaterial = W3D name:MaterialNames[1]
							newmat = true
						)
						else
						(
							VertexMaterial = m
						)

					)
					local tindex = 0
					if newmat do
					(
						wwSetSortLevel VertexMaterial W3DMeshHeader.SortLevel
						wwSetSurfaceType VertexMaterial MeshSurfaceType
						wwSetPassCount VertexMaterial vmPassCount
						for j = 1 to vmPassCount do
						(
							vmInfo = VMatInfos[MaterialIDs[j]]
							local pass = j - 1
							wwSetMatFlags VertexMaterial pass vmInfo[1]
							if MapperArgs0[j] != undefined then
							(
								wwSetMapperArgs VertexMaterial pass 0 MapperArgs0[j]
							)
							if MapperArgs1[j] != undefined then
							(
								wwSetMapperArgs VertexMaterial pass 1 MapperArgs1[j]
							)
							wwSetAmbient VertexMaterial pass vmInfo[2]
							wwSetDiffuse VertexMaterial pass vmInfo[3]
							wwSetSpecular VertexMaterial pass vmInfo[4]
							wwSetEmissive VertexMaterial pass vmInfo[5]
							wwSetShininess VertexMaterial pass vmInfo[6]
							wwSetOpacity VertexMaterial pass vmInfo[7]
							wwSetTranslucency VertexMaterial pass vmInfo[8]
							sInfo = ShaderInfos[ShaderIDs[j]]
							wwSetDepthCompare VertexMaterial pass sInfo[1]
							if sInfo[2] == 0 then
							(
								wwSetWriteZBuffer VertexMaterial pass false
							)
							else
							(
								wwSetWriteZBuffer VertexMaterial pass true
							)
							wwSetDestBlend VertexMaterial pass sInfo[4]
							wwSetPriGradient VertexMaterial pass sInfo[6]
							wwSetSecGradient VertexMaterial pass sInfo[7]
							wwSetSrcBlend VertexMaterial pass sInfo[8]
							wwSetDetailColor VertexMaterial pass sInfo[10]
							wwSetDetailAlpha VertexMaterial pass sInfo[11]
							if sInfo[13] == 1 then
							(
								wwSetAlphaTestFlag VertexMaterial pass true
							)
							else
							(
								wwSetAlphaTestFlag VertexMaterial pass false
							)
							if Stages[j] > 0 do
							(
								for k = 1 to Stages[j] do
								(
									local stage = k - 1
									local z = (pass * 2) + stage
									local val = z + 1
									tindex += 1
									if TextureIDs[val] != undefined do
									(
										if TextureNames[TextureIDs[val]] != undefined do
										(
											wwSetTexture VertexMaterial TextureNames[TextureIDs[val]] z
											wwSetStageFlag VertexMaterial pass stage true
											if TextureInfos[TextureIDs[val]] != undefined do
											(
												tInfo = TextureInfos[TextureIDs[val]]
												wwSetTexFlags VertexMaterial pass stage tInfo[1]
												wwSetAnimType VertexMaterial pass stage tInfo[2]
												wwSetFrames VertexMaterial pass stage tInfo[3]
												wwSetFrameRate VertexMaterial pass stage tInfo[4]
											)
										)
										wwSetUV VertexMaterial pass stage tindex
									)
								)
							)
							wwSetDisplayFlag VertexMaterial pass 0 true
						)
						append Materials VertexMaterial
					)
					for vc = 1 to 4 do
					(
						if VerticesColor[vc] != undefined then
						(
							if VerticesIsAlpha[vc] == false then
							(
								meshop.defaultMapFaces W3DMesh 0
								for tv = 1 to W3DmeshHeader.NumVert do
								(
									meshop.setVertColor W3DMesh 0 #(tv) VerticesColor[vc][tv]
								)
							)
							else
							(
								wwSetVAlpha W3DMesh true
								meshop.defaultMapFaces W3DMesh 0
								for tv = 1 to W3DmeshHeader.NumVert do
								(
									local l = VerticesAlpha[vc][tv]
									local c = (color l l l)
									meshop.setVertColor W3DMesh 0 #(tv) c
								)
							)
							setCVertMode W3DMesh true
						)
					)
					for j = 1 to vmPassCount do
					(
						for tf = 1 to W3DmeshHeader.NumTris do
						(
							setFaceMatID W3DMesh tf MaterialIDs[j]
						)
						if Stages[j] > 0 do
						(
							for k = 1 to Stages[j] do
							(
								local pass = j - 1
								local stage = k - 1
								local z = (pass * 2) + stage
								local val = z + 1
								local tindex = wwGetUV VertexMaterial pass stage
								if MeshTVerts[val] != undefined do
								(
									meshop.defaultMapFaces W3DMesh tindex
									for tv = 1 to W3DmeshHeader.NumVert do
									(
										meshop.setMapVert W3DMesh tindex tv MeshTVerts[val][tv] 
									)
								)
							)
						)
					)
					W3DMesh.material = VertexMaterial
				)

				for i = 1 to W3DmeshHeader.NumVert do
				setNormal W3DMesh i MeshVertsNormals[i]

				if isWWSkin do
				(
					local bones = #{}, bonesStr, propStr = ""
					local skin = WWSkinSpaceWarp pos:[0,0,0]
					Scale skin [1,1,1]
					bindspacewarp W3DMesh skin
				)

				append W3DMeshes W3DMesh
				append W3DMeshParents MeshParent

				update W3DMesh

				wwSetExportGeoFlag W3DMesh true
				wwSetExportBoneFlag W3DMesh false
				wwSetFlags W3DMesh W3DMeshHeader.Flags

				PercentDone = 100*MeshIndex/MeshesCount
				if PercentDone != OldPercentDone do
				(
					OldPercentDone = PercentDone
					W3DImportProgressDlg.Progress.value = PercentDone
					W3DImportProgressDlg.Percent.text = ((PercentDone as string) + " %")
				)

				W3DFileOffset = MeshChunkStart + MeshChunkSize
			)

			)

			for i = 1 to BoxesArray.count by 5 do
			(
				local BoundingBox = box name:BoxesArray[i] \
							      width:(2 * BoxesArray[i+3].x) \
								length:(2 * BoxesArray[i+3].y) \
								height:(2 * BoxesArray[i+3].z) \
								pos:[BoxesArray[i+2].x, BoxesArray[i+2].y, BoxesArray[i+2].z - BoxesArray[i+3].z]

				wwSetExportGeoFlag BoundingBox true
				wwSetExportBoneFlag BoundingBox false
				wwSetFlags BoundingBox BoxesArray[i+4]
				join BoundingBoxesArray #(BoundingBox)
			)

			CloseW3D
			return true;
		),

		fn BuildHierarchy=
		(
			local numAddedBone = 0
			local linkedMeshArray = #()

			PercentDone = 0
			OldPercentDone = 0

			W3DImportProgressDlg.Stage.text = "BuildingHierarchy..."
			W3DImportProgressDlg.Progress.value = PercentDone
			W3DImportProgressDlg.Percent.text = ((PercentDone as string) + " %")

			for i = 0 to (LODCount-1) do
			(
				local OriginLOD = if radioLOD.state == 1 then i + 1 else i - CurrentLODRange[1] + 1

				if CreateLODBones then
				(
					if radioLOD.state == 1 or (i >= CurrentLODRange[1] and i <= CurrentLODRange[2]) do
						OriginBone[OriginLOD] = CreateBone "Origin" ("Origin.0" + i as string) [0.0,0.0,0.0]
						setUserProp OriginBone[OriginLOD] "Type" "Bone"
				)
				else
				(
					OriginBone[1] = CreateBone "Origin" "Origin" [0.0,0.0,0.0]
					setUserProp OriginBone[1] "Type" "Bone"
					exit;
				)
			)

			for i = 1 to OriginBone.count do OriginNeeded[i] = false

			PercentDone = 1
			W3DImportProgressDlg.Progress.value = PercentDone
			W3DImportProgressDlg.Percent.text = ((PercentDone as string) + " %")

			for i = 1 to BonesArray.count by 6 do
			(
				local W3DBone
				local W3DBoneIndex = (i + 5) / 6
				local W3DBoneParent
				local W3DBoneType = "Bone"
				local W3DBoneLOD = 0
				local BoneCreated = false, BoneAdded = false
				local OriginLOD

				PercentDone = 1 + ((100*(i-1)/BonesArray.count) / 2)
				if PercentDone != OldPercentDone do
				(
					OldPercentDone = PercentDone
					W3DImportProgressDlg.Progress.value = PercentDone
					W3DImportProgressDlg.Percent.text = ((PercentDone as string) + " %")
				)

				if findItem ProxyArray BonesArray[i] > 0 do
				(
					if (not ImportSelectedOnly or findItem ProxiesSelected BonesArray[i] > 0) and not ImportBonesOnly do
					(
						local ProxyParentLOD

						W3DBoneType = "Proxy"
						W3DBone = CreateBone W3DBoneType BonesArray[i] BonesArray[i+2]
						wwSetExportGeoFlag W3DBone true
						wwSetExportBoneFlag W3DBone true
						if CreateLODBones do
							if radioLOD.state == 2 and CurrentLODRange[1] != 0 do ProxyParentLOD = CurrentLODRange[1]

						W3DBoneParent = getW3DBoneParent BonesArray[i+1] ProxyParentLOD

						if W3DBoneParent > 0 then W3DBone.parent = W3DBones[W3DBoneParent]
						else W3DBone.parent = OriginBone[1]
						join W3DBones #(W3DBone, W3DBoneIndex, W3DBoneParent, W3DBoneType, 0, true)
						Continue
					)
				)

				for j = 1 to DazzlesNames.count by 5 do
				(
					if DazzlesNames[j+3] != BonesArray[i] do continue
					local LODDazzleImported = false

					if (not ImportSelectedOnly or findItem DazzlesSelected DazzlesNames[j+2] > 0) and not ImportBonesOnly do
						LODDazzleImported = true

					W3DBoneLOD = DazzlesNames[j]

					if CreateLODBones then
					(
						if radioLOD.state == 2 and (W3DBoneLOD < CurrentLODRange[1] or W3DBoneLOD > CurrentLODRange[2]) do continue
						W3DBoneParent = getW3DBoneParent BonesArray[i+1] W3DBoneLOD
					)
					else W3DBoneParent = getW3DBoneParent BonesArray[i+1] 0


					OriginLOD = if radioLOD.state == 1 then W3DBoneLOD + 1 else W3DBoneLOD - CurrentLODRange[1] + 1

					W3DBoneType = if LODDazzleImported then "Dazzle" else "Bone"

					W3DBone = CreateBone W3DBoneType DazzlesNames[j+2] BonesArray[i+2]

					k = findItem DazzleArray DazzlesNames[j+1]
					wwSetExportGeoFlag W3DBone true
					wwSet2Side W3DBone true
					wwSetType W3DBone 7
					wwSetDazzle W3DBone DazzleArray[k+1]

					if W3DBoneParent > 0 then W3DBone.parent = W3DBones[W3DBoneParent]
					else W3DBone.parent = if CreateLODBones then OriginBone[OriginLOD] else OriginBone[1]

					join W3DBones #(W3DBone, W3DBoneIndex, W3DBoneParent, W3DBoneType, W3DBoneLOD, LODDazzleImported)
					BoneCreated = true
				)

				if BoneCreated do continue

				for j = 1 to MeshesNames.count by 5 do
				(
					if MeshesNames[j+3] != BonesArray[i] do continue
					local LODMesh, LODMeshImported = false
					local index = (13 * CurrentProfile) - 12
					local CreateMeshBone = W3DImporterInit.UserProfiles[index+12] 

					for k = 1 to W3DMeshes.count do
					(
						if W3DMeshes[k].name == MeshesNames[j+2] do
						(
							LODMeshImported = true
							LODMesh = k
						)
					)

					W3DBoneLOD = MeshesNames[j]

					OriginLOD = if radioLOD.state == 1 then W3DBoneLOD + 1 else W3DBoneLOD - CurrentLODRange[1] + 1
					if CreateMeshBone or not LODMeshImported then
					(
						if CreateLODBones then
						(
							if radioLOD.state == 2 and (W3DBoneLOD < CurrentLODRange[1] or W3DBoneLOD > CurrentLODRange[2]) do continue
							W3DBoneParent = getW3DBoneParent BonesArray[i+1] W3DBoneLOD
						)
						else W3DBoneParent = getW3DBoneParent BonesArray[i+1] 0

						local boneName

						if LODMeshImported then
						(
							boneName = "AddedBone" + numAddedBone as string
							BoneAdded = true
						)
						else boneName = BonesArray[i]

						if CreateLODBones do boneName = boneName + ".0" + W3DBoneLOD as string
						W3DBone = CreateBone "Bone" boneName BonesArray[i+2]
						wwSetExportGeoFlag W3DBone false
						wwSetExportBoneFlag W3DBone true
						setUSerProp W3DBone "BoneID" W3DBoneIndex
						setUSerProp W3DBone "BoneLOD" (if CreateLODBones then W3DBoneLOD else 0)

						if W3DBoneParent > 0 then W3DBone.parent = W3DBones[W3DBoneParent]
						else W3DBone.parent = if CreateLODBones then OriginBone[OriginLOD] else OriginBone[1]

						join W3DBones #(W3DBone, W3DBoneIndex, W3DBoneParent, W3DBoneType, W3DBoneLOD, LODMeshImported)
					)

					else if LODMeshImported do
					(
						W3DMeshes[LODMesh].pos = BonesArray[i+2]
						W3DBoneParent = getW3DBoneParent BonesArray[i+1] W3DBoneLOD
						wwSetExportBoneFlag W3DMeshes[LODMesh] true
						if W3DBoneParent > 0 then W3DMeshes[LODMesh].parent = W3DBones[W3DBoneParent]
						else W3DMeshes[LODMesh].parent = if CreateLODBones then OriginBone[OriginLOD] else OriginBone[1]

						join W3DBones #(W3DMeshes[LODMesh], W3DBoneIndex, W3DBoneParent, "Mesh", W3DBoneLOD, true)
					)

					BoneCreated = true
				)
				local x = 1
				for j = 1 to BoxesArray.count by 5 do 
				(
					if BoxesArray[j] != BonesArray[i] do 
					(
						x += 1
						continue
					)
					join BoxesArray #(W3DBox.Name, W3DBox.BoxColor, W3DBox.Pos, W3DBox.Extent, W3DBox.Flags)
					W3DBoneParent = getW3DBoneParent BonesArray[i+1] W3DBoneLOD
					wwSetExportBoneFlag BoundingBoxesArray[x] true
					if W3DBoneParent > 0 then BoundingBoxesArray[x].parent = W3DBones[W3DBoneParent]
					else BoundingBoxesArray[x].parent = OriginBone[1]
					join W3DBones #(BoundingBoxesArray[x], W3DBoneIndex, W3DBoneParent, "Mesh", 1, true)
					BoneCreated = true
				)

				if BoneAdded do numAddedBone += 1
				if BoneCreated do continue

				if CreateLODBones then
				(
					for j = 0 to (LODCount-1) do
					(
						OriginLOD = if radioLOD.state == 1 then j + 1 else j - CurrentLODRange[1] + 1

						if radioLOD.state == 1 or (j >= CurrentLODRange[1] and j <= CurrentLODRange[2]) do
						(
							local boneName = BonesArray[i] + ".0" + j as string
							W3DBone = CreateBone "Bone" boneName BonesArray[i+2]
							wwSetExportGeoFlag W3DBone false
							wwSetExportBoneFlag W3DBone true
							setUSerProp W3DBone "BoneID" W3DBoneIndex
							setUSerProp W3DBone "BoneLOD" j

							W3DBoneParent = getW3DBoneParent BonesArray[i+1] j

							if W3DBoneParent > 0 then W3DBone.parent = W3DBones[W3DBoneParent]
							else W3DBone.parent = OriginBone[OriginLOD]

							join W3DBones #(W3DBone, W3DBoneIndex, W3DBoneParent, W3DBoneType, j, not DepBonesOnly)
						)
					)
				)

				else
				(
					W3DBone = CreateBone "Bone" BonesArray[i] BonesArray[i+2]
					wwSetExportGeoFlag W3DBone false
					wwSetExportBoneFlag W3DBone true
					setUSerProp W3DBone "BoneID" W3DBoneIndex
					setUSerProp W3DBone "BoneLOD" 0

					W3DBoneParent = getW3DBoneParent BonesArray[i+1] 0

					if W3DBoneParent > 0 then W3DBone.parent = W3DBones[W3DBoneParent]
					else W3DBone.parent = OriginBone[1]
					join W3DBones #(W3DBone, W3DBoneIndex, W3DBoneParent, W3DBoneType, 0, not DepBonesOnly)
				)
			)

			PercentDone = 51
			W3DImportProgressDlg.Progress.value = PercentDone
			W3DImportProgressDlg.Percent.text = ((PercentDone as string) + " %")

			for i = 1 to W3DMeshes.count do
			(
				local linkedMesh = false
				local vertsBonesArray = #(), skinBonesArray = #()
				local vertBone, MeshLOD

				PercentDone = (51 + ((100*(i-1)/W3DMeshes.count) / 2.857)) as integer
				if PercentDone != OldPercentDone do
				(
					OldPercentDone = PercentDone
					W3DImportProgressDlg.Progress.value = PercentDone
					W3DImportProgressDlg.Percent.text = ((PercentDone as string) + " %")
				)

				local zz = 0
				for j = 1 to MeshVertsBindArray.count by 3 do
				(
					if MeshVertsBindArray[j+1] == i then
					(
						zz = j
						linkedMesh = true
						vertsBonesArray = MeshVertsBindArray[j+2]
						MeshLOD = if CreateLODBones then MeshVertsBindArray[j] else 0
						exit;
					)
				)


				if linkedMesh do
				(
					for j = 1 to vertsBonesArray.count do
					(
						vertsArray = vertsBonesArray[j]
						if vertsArray.count == 0 do continue
						for k = 1 to W3DBones.count by 6 do
						(
							if W3DBones[k+4] == MeshLOD and W3DBones[k+1] == j then
							(
								vertBone = W3DBones[k]
								if DepBonesOnly do W3DBones[k+5] = true
								exit;
							)
						)
						local mesh = W3DMeshes[i]
						wwAddBone vertBone mesh
						for vb = 1 to vertsArray.count do
						(
							wwSetBoneWeight W3DMeshes[i] (vertsArray[vb] - 1) 1 vertBone 100
						)
					)
					append linkedMeshArray i
				)

				if W3DMeshes[i].parent != undefined do continue

				for j = 1 to MeshesNames.count by 5 do
				(
					if W3DMeshes[i].name != MeshesNames[j+2] do continue

					MeshLOD = MeshesNames[j]
					local OriginLOD = if radioLOD.state == 1 then MeshLOD + 1 else MeshLOD - CurrentLODRange[1] + 1
					local MeshParent = getW3DBoneParent W3DMeshParents[i] MeshLOD

					if MeshParent > 0 then
					(
						W3DMeshes[i].pos = W3DBones[MeshParent].pos
						W3DMeshes[i].parent = W3DBones[MeshParent]
						if DepBonesOnly do W3DBones[MeshParent+5] = true
					)

					else W3DMeshes[i].parent = if CreateLODBones then OriginBone[OriginLOD] else OriginBone[1]
				)
			)

			PercentDone = 86
			W3DImportProgressDlg.Progress.value = PercentDone
			W3DImportProgressDlg.Percent.text = ((PercentDone as string) + " %")

			for i = 1 to AggregateArray.count by 2 do
			(
				PercentDone = (86 + ((100*(i-1)/(AggregateArray.count/2)) / 20))
				if PercentDone != OldPercentDone do
				(
					OldPercentDone = PercentDone
					W3DImportProgressDlg.Progress.value = PercentDone
					W3DImportProgressDlg.Percent.text = ((PercentDone as string) + " %")
				)

				if (not ImportSelectedOnly or findItem AggregatesSelected AggregateArray[i] > 0) and not ImportBonesOnly do
				(
					local Aggregate, AggParentLOD = 0

					if CreateLODBones do
						if radioLOD.state == 2 and CurrentLODRange[1] != 0 do AggParentLOD = CurrentLODRange[1]

					local AggParent = getW3DBoneParent AggregateArray[i+1] AggParentLOD

					if AggParent > 0 then
					(
						Aggregate = CreateBone "Aggregate" AggregateArray[i] W3DBones[AggParent].pos
						wwSetExportGeoFlag Aggregate true
						wwSetExportBoneFlag Aggregate false
						wwSetHide Aggregate true
						wwSetType Aggregate 8
						Aggregate.parent = W3DBones[AggParent]
						if DepBonesOnly do W3DBones[AggParent+5] = true
					)
					else
					(
						Aggregate = CreateBone "Aggregate" AggregateArray[i] [0.0,0.0,0.0]
						wwSetExportGeoFlag Aggregate true
						wwSetExportBoneFlag Aggregate false
						wwSetHide Aggregate true
						wwSetType Aggregate 8
						Aggregate.parent = OriginBone[1]
						if DepBonesOnly do OriginNeeded[1] = true
					)
				)
			)

			W3DImportProgressDlg.Progress.value = 91
			W3DImportProgressDlg.Percent.text = "91 %"

			for i = 1 to BonesArray.count by 6 do
				for j = 1 to W3DBones.count by 6 do if W3DBones[j+1] == ((i+5) / 6) do
					in coordsys local rotate W3DBones[j] BonesArray[i+3]


			W3DImportProgressDlg.Progress.value = 94
			W3DImportProgressDlg.Percent.text = "94 %"

			local i = W3DBones.count
			while i > 0 do
			(
				if W3DBones[i] and DepBonesOnly then
				(
					local W3DBoneParent = W3DBones[i-3]
					while W3DBoneParent >= 0 do
					(
						if W3DBoneParent == 0 do
						(
							local lodID = if radioLOD.state == 1 then W3DBones[i-1] + 1 else W3DBones[i-1] - CurrentLODRange[1] + 1
							if CreateLODBones then OriginNeeded[lodID] = true
							else OriginNeeded[1] = true
							exit;
						)

						W3DBones[W3DBoneParent+5] = true
						W3DBoneParent = W3DBones[W3DBoneParent+2]
					)
				)
				i -= 6
			)

			W3DImportProgressDlg.Progress.value = 97
			W3DImportProgressDlg.Percent.text = "97 %"

			if not checkBones.checked do
			(
				for i = 1 to W3DMeshes.count do
				(
					if findItem linkedMeshArray i > 0 do convertToMesh W3DMeshes[i]
					W3DMeshes[i].parent = undefined
				)
			)

			local i = W3DBones.count
			while i > 0 do
			(
				i -= 6

				if checkBones.checked and W3DBones[i+6] do continue
				if ImportBonesOnly and W3DBones[i+4] == "Bone" do continue
				if W3DBones[i+4] != "Mesh" and W3DBones[i+4] != "Dazzle" and W3DBones[i+4] != "Proxy" do
				(
					delete W3DBones[i+1]
					for j = 1 to 6 do deleteItem W3DBones (i+1)
				)
			)

			local i = OriginBone.count
			while i > 0 do
			(
				if not CreateOrigin or (DepBonesOnly and not OriginNeeded[i]) do
				(
					delete OriginBone[i]
					deleteItem OriginBone i
					deleteItem OriginNeeded i
				)
				i -= 1
			)

			if WWSkinCreated do
			(
				for o in objects do
				(
					local oMin = o.min, oMax = o.max

					if oMin.x < W3DMin.x do W3DMin.x = oMin.x
					if oMin.y < W3DMin.y do W3DMin.y = oMin.y
					if oMin.z < W3DMin.z do W3DMin.z = oMin.z
					if oMax.x > W3DMax.x do W3DMax.x = oMax.x
					if oMax.y > W3DMax.y do W3DMax.y = oMax.y
					if oMax.z > W3DMax.z do W3DMax.z = oMax.z
				)

				local j = 1
				for i = 1 to W3DSkin.count do
				(
					local CenterX = W3DMin.x + ((W3DMax.x - W3DMin.x) / 2)
					local CenterY = W3DMin.y + ((W3DMax.y - W3DMin.y) / 2)
					local CenterZ = W3DMin.z + ((W3DMax.z - W3DMin.z) / 2)
					local ZOffset = 0

					case j of
					(
						1: W3DSkin[i].pos = [CenterX, (W3DMax.y + 3), (CenterZ + ZOffset)]
						2: W3DSkin[i].pos = [(W3DMax.x + 3), CenterY, (CenterZ + ZOffset)]
						3: W3DSkin[i].pos = [CenterX, (W3DMin.y - 3), (CenterZ + ZOffset)]
						4:
						(
							W3DSkin[i].pos = [(W3DMin.x - 3), CenterY, (CenterZ + ZOffset)]
							j = 0
							ZOffset += 1
						)
					)
					j += 1
				)
			)


			W3DImportProgressDlg.Progress.value = 100
			W3DImportProgressDlg.Percent.text = "100 %"
		),

		fn W3DAnimate=
		(
			OpenW3D W3DAnimationFile

			if AnimFrameCount > 0 and checkBones.checked and checkAnim.checked do
			(
				local SingleFrame = false, frameIndex
				local ChannelIndex, AnimBone, VectorLen, VectorStart
				local ChannelType, ChannelFirstFrame, ChannelLastFrame
				local PosControllers = #(0,1,2,7,8,9,11,12,13)
				local ChannelPercentDone = 0

				PercentDone = 0
				OldPercentDone = 0

				if radioFrames.state == 2 then
				(
					AnimFirstFrame = fromFrameSpin.value
					AnimLastFrame = toFrameSpin.value 
					if AnimFirstFrame == AnimLastFrame do SingleFrame = true
				)
				else
				(
					AnimFirstFrame = 0
					AnimLastFrame = AnimFrameCount - 1
				)

				frameRate = AnimFrameRate
				animationRange = interval 0 (AnimLastFrame - AnimFirstFrame)
				sliderTime = 0f

				W3DImportProgressDlg.Stage.text = "Animating..."
				W3DImportProgressDlg.Progress.value = PercentDone
				W3DImportProgressDlg.Percent.text = ((PercentDone as string) + " %")

				for i = 1 to W3DBones.count by 6 do
				(
					local boneIndex = W3DBones[i+1]

					for j = 1 to AnimChannelCount do
					(
						ChannelIndex = (j * 3) - 2
						AnimBone = AnimBones[ChannelIndex]
						VectorLen = AnimBones[ChannelIndex+1]
						VectorStart = AnimBones[ChannelIndex+2]
						ChannelType = AnimInfo[ChannelIndex]
						ChannelFirstFrame = AnimInfo[ChannelIndex+1]
						ChannelLastFrame = AnimInfo[ChannelIndex+2]
						frameIndex = 1

						if AnimBone == boneIndex do
						(
							local c, k, InitialPos

							if findItem PosControllers ChannelType > 0 then
							(
								c = bezier_position()
								W3DBones[i].pos.controller = c
							)
							else
							(
								c = bezier_rotation()
								W3DBones[i].rotation.controller = c
							)

							if AnimFirstFrame > 0 then frameIndex = 0
							else
							(
								k = addNewKey c 0
								InitialPos = k.value
							)

							W3DFileOffset = VectorStart
							fseek W3Dstream W3DFileOffset #seek_set

							for n = ChannelFirstFrame to ChannelLastFrame do
							(
								if n < AnimFirstFrame do
								(
									W3DFileOffset += (VectorLen * 4)
									fseek W3Dstream W3DFileOffset #seek_set
									continue
								)

								if n > AnimLastFrame then exit;

								k = addNewKey c n
								if frameIndex == 0 do InitialPos = k.value
								case ChannelType of
								(
									0:
									(
										k.value.x = InitialPos.x + (ReadAnimVector W3Dstream)
									)
									1:
									(
										k.value.y = InitialPos.y + (ReadAnimVector W3Dstream)
									)
									2:
									(
										k.value.z = InitialPos.z + (ReadAnimVector W3Dstream)
									)
									3:
									(
										k.value.x = InitialPos.x + (ReadAnimVector W3Dstream)
									)
									4:
									(
										k.value.y = InitialPos.y + (ReadAnimVector W3Dstream)
									)
									5:
									(
										k.value.z = InitialPos.z + (ReadAnimVector W3Dstream)
									)
									6:
									(
										k.value = InitialPos + (ReadAnimVector W3Dstream isQuat:true)
									)
									7:
									(
										k.value.x = InitialPos.x + (ReadAnimVector W3Dstream)
									)
									8:
									(
										k.value.y = InitialPos.y + (ReadAnimVector W3Dstream)
									)
									9:
									(
										k.value.z = InitialPos.z + (ReadAnimVector W3Dstream)
									)
									10:
									(
										k.value = InitialPos + (ReadAnimVector W3Dstream isQuat:true)
									)
									11: 
									(
										k.value.x = InitialPos.x + (ReadAnimVector W3Dstream)
									)
									12: 
									(
										k.value.y = InitialPos.y + (ReadAnimVector W3Dstream)
									)
									13: 
									(
 										k.value.z = InitialPos.z + (ReadAnimVector W3Dstream)
									)
									14: 
									(
										k.value = InitialPos + (ReadAnimVector W3Dstream isQuat:true)
									)
								)

								frameIndex += 1
								local frame = ChannelLastFrame - ChannelFirstFrame
								if frame == 0 do
								(
									frame = 1
								)
								ChannelPercentDone = 100*n/(frame)
								PercentDone = (100*(j-1)/AnimChannelCount)+(ChannelPercentDone/AnimChannelCount)

								if PercentDone != OldPercentDone do
								(
									OldPercentDone = PercentDone
									W3DImportProgressDlg.Progress.value = PercentDone
									W3DImportProgressDlg.Percent.text = ((PercentDone as string) + " %")
								)
							)
						)
					)
				)

			W3DImportProgressDlg.Progress.value = 100
			W3DImportProgressDlg.Percent.text = "100 %"
			)

			W3DImportProgressDlg.Stage.text = "Updating Gmax Viewports..."
		),

		fn W3DBitAnimate=
		(
			OpenW3D W3DAnimationFile
			AnimFirstFrame = 0
			AnimLastFrame = AnimFrameCount - 1
			if AnimFrameCount > 0 do
			(
				local SingleFrame = false, frameIndex
				local ChannelIndex, ChannelIndex2, AnimBone, VectorLen, VectorStart
				local FrameType, ChannelFirstFrame, ChannelLastFrame
				local ChannelPercentDone = 0
				local bitvalue, oldbitvalue, bytevalue
				local x,y
				PercentDone = 0
				OldPercentDone = 0
				AnimFirstFrame = 0
				AnimLastFrame = AnimFrameCount - 1
				frameRate = AnimFrameRate
				animationRange = interval 0 (AnimLastFrame - AnimFirstFrame)
				sliderTime = 0f

				W3DImportProgressDlg.Stage.text = "Animating..."
				W3DImportProgressDlg.Progress.value = PercentDone
				W3DImportProgressDlg.Percent.text = ((PercentDone as string) + " %")
				for i = 1 to W3DBones.count by 6 do
				(
					local boneIndex = W3DBones[i+1]
					for j = 1 to BitChannelCount do
					(
						bitvalue = true
						oldbitvalue = true
						ChannelIndex = (j * 2) - 1
						ChannelIndex2 = (j * 3) - 2
						AnimBone = BitBones[ChannelIndex]
						VectorStart = BitBones[ChannelIndex+1]
						ChannelFirstFrame = BitInfo[ChannelIndex2+1]
						ChannelLastFrame = BitInfo[ChannelIndex2+2]
						frameIndex = 1
						if AnimBone == boneIndex do
						(
							local c, k, InitialPos
							if getVisController W3DBones[i]==undefined then
							(
								animate on at time 0 W3DBones[i].visibility=1
								W3DBones[i].visibility.controller=(on_off())
								deleteKeys W3DBones[i].visibility.controller #allKeys
							)
							if AnimFirstFrame > 0 then frameIndex = 0
							W3DFileOffset = VectorStart
							fseek W3Dstream W3DFileOffset #seek_set
							x = 1
							for n = ChannelFirstFrame to ChannelLastFrame do
							(
								if x == 1 do
								(
									bytevalue = ReadByte W3DStream
								)
								bitvalue = bit.get bytevalue x
								if bitvalue != oldbitvalue do
								(
									addNewKey W3DBones[i].visibility.controller n
									oldbitvalue = bitvalue
								)
								x += 1
								if x == 8 do
								(
									x = 1
								)
								frameIndex += 1
							)
							addNewKey W3DBones[i].visibility.controller (ChannelLastFrame+1)
						)
					)
				)

			W3DImportProgressDlg.Progress.value = 100
			W3DImportProgressDlg.Percent.text = "100 %"
			)

			W3DImportProgressDlg.Stage.text = "Updating Gmax Viewports..."
		)
	)
	
	fn SelectW3D fname:""=
	(
		local sF = false, hF = false, aF = false, lF = false, objF = false
		local importer = W3D_Importer()
		if fname != "" then
		(
			local checkForMix = filterString fname " ()"
			if checkForMix.count > 1 do
			(
				ImportFromMix = true
				fname = checkForMix[1]
				MixFileName = checkForMix[2]
			)
		)

		else ImportFromMix = false

		if ImportFromMix then
		(
			W3DFileName = fname
			importer.getMix()
		)

		else
		(
			if fname != "" then W3DFileName = fname
			else W3DFileName = getOpenFileName caption:"Import W3D File" filename:(GetMostRecentPath()) types:"W3D (*.w3d)|*.w3d"
		
			if W3DFileName == undefined or not DoesFileExist W3DFileName then return false;

			mostRecentPath = getFileNamePath W3DFileName
		)
		ResetImporterDlg()
--		try
--		(
			sf = importer.CheckSelectedW3D W3DFileName
			if not sF then return false;

			hF = importer.GetW3DHierarchy()
			if not hF then return false;

			if W3DAnimationFile != "" do
			(
				aF = importer.GetW3DAnimation()
				if not aF then return false;
			)

			if W3DHLODFile != "" do
			(
				lF = importer.GetW3DHLOD()
				if not lF then return false;
			)

			for i = 1 to LODCount do if W3DObjectsFile[i] != "" do
			(
				objF = importer.GetW3DObjects W3DObjectsFile[i]
				if not objF then return false;
			)

			importer.UpdateImporterDlg()
--		)
--		catch
--		(
--			messageBox "Error occured in Select W3D File."
--		)

		true
	)

	fn ImportW3D=
	(
		Materials = #()
		UserClickedOnImportButton = true

		local importer = W3D_Importer()
		local PanelShown = cui.commandPanelOpen
		local CurrentPanel = getCommandPanelTaskMode()

		if maxFileName != "" or getSaveRequired() do W3DMergePrompt.Open()

		cui.commandPanelOpen = false
		disableSceneRedraw()

		W3DImportProgressDlg.fOpen()
		if ImportFromMix do importer.getMix()
--		try
--		(
			for i = 0 to (LODCount-1) do if W3DObjectsFile[i+1] != "" do importer.ConvertW3D i
--		)
--		catch
--		(
--			messagebox "An Error Occured While Converting Meshes"
--			format "W3D File Selected: %\n" W3DFileName
--			format "LOD Count = %\n" LODCount
--			for i = 1 to LODCount do
--			format "LOD[%] File: %\n" (i-1) W3DObjectsFile[i]
--			W3DImportProgressDlg.fclose()
--			setCommandPanelTaskMode mode:CurrentPanel
--			cui.commandPanelOpen = PanelShown
--			enableSceneRedraw()
--			max views redraw
--		)

--		try
--		(
			importer.BuildHierarchy()
			clearselection()
--		)
--		catch
--		(
--			messagebox "Error Building Hierarchy"
--			W3DImportProgressDlg.fclose()
--			setCommandPanelTaskMode mode:CurrentPanel
--			cui.commandPanelOpen = PanelShown
--			enableSceneRedraw()
--			max views redraw
--		)

--		try (
			if isAnimated do importer.W3DAnimate()
			if isBitAnimated do importer.W3DBitAnimate()
--		)
--		catch	(
--			messagebox "Error occured in Animating process"
--			W3DImportProgressDlg.fclose()
--			setCommandPanelTaskMode mode:CurrentPanel
--			cui.commandPanelOpen = PanelShown
--			enableSceneRedraw()
--			max views redraw
--		)

		AddRecentFile W3DFileName fromMix:ImportFromMix
		W3DImportProgressDlg.fclose()
		setCommandPanelTaskMode mode:CurrentPanel
		cui.commandPanelOpen = PanelShown
		enableSceneRedraw()
		max views redraw
		setSaveRequired true
		ImportFromMix = false
	)

	fn SelectMix=
	(
		ImportFromMix = false

		local MixFile = Mix_File()
--		local MixPath = "C:\\Westwood\\Renegade\\data\\"
		local MixPath = W3DImporterInit.MixPath
		
		MixFileName = getOpenFileName caption:"Select W3D File" filename:(MixPath) \
			types:"MIX (*.mix)|*.mix|Package (*.pkg)|*.pkg|DAT (*.dat)|*.dat"

		if MixFileName != undefined then
		(
			local W3DSelected

			if doesFileExist MixFileName then
			(
				local MixStream = fopen MixFileName "rb"

				if not MixFile.ReadMix MixStream then
				(
					messageBox "Invalid or unsuported Mix file."
					fclose MixStream
					return false;
				)

				MixFilesList = MixFile.getMixFilesNames MixStream

				for i = 1 to MixFilesList.count do
				(
					local ext = getFileNameType MixFilesList[i]
					if matchPattern ext pattern:".w3d" do
					(
						append MixFilesArray MixFilesList[i]
						sort MixFilesArray
					)
				)

				W3DSelected = SelectFromMixDlg.open()
				if W3DSelected != undefined do
				(
					MixW3DIndex = findItem MixFilesList W3Dselected
					if MixFile.getMixFile MixStream MixW3DIndex do
					(
						ImportFromMix = true
						MixW3DFileName = W3DSelected
						MixW3DFileOffset = MixFile.MixFileOffset
						MixW3DFileSize = MixFile.MixFileSize
					)
				)
				
				MixFilesArray = #()
				fclose MixStream

				if ImportFromMix then
				(
					SelectW3D fname:MixW3DFileName
					return true;
				)
			)
		)

		return false;
	)

	on W3DImportDlg open do	ResetImporterDlg()

	on BonesPropList doubleclicked sel do setFocus W3DImportDlg
	on BonesPropList selected sel do
	(
		BonesPropList.selection = 0
		setFocus W3DImportDlg
	)

	on mClearButton pressed do
	(
		MeshToImport.selection = #{}
		UpdateImportSelection "Meshes" true
	)

	on mAllButton pressed do
	(
		local mCount = MeshToImport.selection.count
		MeshToImport.selection = #{1..mCount}
		UpdateImportSelection "Meshes" false
	)

	on pClearButton pressed do
	(
		ProxyToImport.selection = #{}
		UpdateImportSelection "Proxies" true
	)

	on pAllButton pressed do
	(
		local pCount = ProxyToImport.selection.count
		ProxyToImport.selection = #{1..pCount}
		UpdateImportSelection "Proxies" false
	)

	on mInvertButton pressed do
	(
		MeshToImport.Selection = -MeshToImport.Selection
		UpdateImportSelection "Meshes" false
	)

	on pInvertButton pressed do
	(
		ProxyToImport.Selection = -ProxyToImport.Selection
		UpdateImportSelection "Proxies" false
	)

	on aClearButton pressed do
	(
		AggregateToImport.selection = #{}
		UpdateImportSelection "Aggregates" true
	)
	on aAllButton pressed do
	(
		local aCount = AggregateToImport.selection.count
		AggregateToImport.selection = #{1..aCount}
		UpdateImportSelection "Aggregates" false
	)
	on aInvertButton pressed do
	(
		AggregateToImport.Selection = -AggregateToImport.Selection
		UpdateImportSelection "Aggregates" false
	)

	on dClearButton pressed do
	(
		DazzleToImport.selection = #{}
		UpdateImportSelection "Dazzles" true
	)
	on dAllButton pressed do
	(
		local dCount = DazzleToImport.selection.count
		DazzleToImport.selection = #{1..dCount}
		UpdateImportSelection "Dazzles" false
	)
	on dInvertButton pressed do
	(
		DazzleToImport.Selection = -DazzleToImport.Selection
		UpdateImportSelection "Dazzles" false
	)

	on fromFrameSpin changed val do UpdatePropSpinner "FromFrames" val
	on toFrameSpin changed val do UpdatePropSpinner "ToFrames" val

	on radioLOD changed val do UpdatePropCheck "LOD" true val  
	on fromLODSpin changed val do UpdatePropSpinner "FromLOD" val
	on toLODSpin changed val do UpdatePropSpinner "ToLOD" val

	on MeshToImport selectionEND do UpdateImportSelection "Meshes" false
	on ProxyToImport selectionEND do UpdateImportSelection "Proxies" false

	on DazzleToImport selectionEND do UpdateImportSelection "Dazzles" false
	on AggregateToImport selectionEND do UpdateImportSelection "Aggregates" false

	on checkBones changed isChecked do
	(
		checkDepBones.enabled = if IsChecked and bit.and ItemSelected 15 > 0 then true else false
		checkOrigin.enabled = IsChecked
		checkLODBones.enabled = if IsChecked and LODCount > 1 then true else false
		BonesOnlyButton.enabled = Ischecked

		if IsChecked and AnimFrameCount > 0 then
		(
			FramesOptions.enabled = true
			checkAnim.enabled = true

			if checkAnim.checked then radioFrames.enabled = true
			else radioFrames.enabled = false
						
			if radioFrames.state == 2 then
			(
				fromFrameSpin.enabled = true
				toFrameSpin.enabled = true
			)
			else
			(
				fromFrameSpin.enabled = false
				toFrameSpin.enabled = false
			)							
		)	
		else
		(
			FramesOptions.enabled = false
			checkAnim.enabled = false
			radioFrames.enabled = false
			fromFrameSpin.enabled = false
			toFrameSpin.enabled = false
		)
	)

	on checkAnim changed isChecked do UpdatePropCheck "Frames" true (if isChecked then 1 else 0)
	on radioFrames changed val do UpdatePropCheck "Frames" true (1+ bit.shift val 1)

	on BonesOnlyButton pressed do
	(
		destroyDialog W3DImportDlg
		ImportBonesOnly = true
		ImportW3D()
	)

	on ImportSelButton pressed do
	(
		destroyDialog W3DImportDlg
		ImportSelectedOnly = true
		ImportW3D()
	)

	on ImportButton pressed do
	(
		destroyDialog W3DImportDlg
		ImportW3D()
	)
	on cancelButton pressed do destroyDialog W3DImportDlg
)

rollout W3DPreferences "W3D Importer Preferences" width:418 height:550 silentErrors:false
(
	local ProfilesSettings = #()

	groupBox Settings "Settings:" width:410 height:307 pos:[4,9]

	label ProfileLabel "Profile : " pos:[14,33] align:#left
	dropdownlist ProfileCombo pos:[56,30] width:196 align:#left
	button NewButton "New" pos:[257,30] width:70
	button DeleteButton "Delete" pos:[333,30] width:71

	label bShapeLabel "Bones Shape :" pos:[18,70] align:#left
	dropdownlist bShapeCombo pos:[95,67] width:81 height:5 align:#left
	edittext bSizeEdit "Bones Size : " pos:[29,100] fieldWidth:80 align:#left
	colorpicker bColorPick "Bones Color : " pos:[25,127] fieldWidth:80 title:"Bones Color" align:#left

	label pShapeLabel "Proxies Shape :" pos:[14,169] align:#left
	dropdownlist pShapeCombo pos:[95,166] width:81 height:5 align:#left
	edittext pSizeEdit "Proxies Size : " pos:[25,199] fieldWidth:80 align:#left
	colorpicker pColorPick "Proxies Color : " pos:[21,226] fieldWidth:80 title:"Proxies Color" align:#left

	label aShapeLabel "Aggregates Shape : " pos:[223,70] align:#left
	dropdownlist aShapeCombo pos:[324,67] width:81 height:5 align:#left
	edittext aSizeEdit "Aggregates Size : " pos:[234,100] fieldWidth:80 align:#left
	colorpicker aColorPick "Aggregates Color : " pos:[230,127] fieldWidth:80 title:"Aggregates Color" align:#left

	label dShapeLabel "Dazzles Shape : " pos:[240,169] align:#left
	dropdownlist dShapeCombo pos:[324,166] width:81 height:5 align:#left
	edittext dSizeEdit "Dazzles Size : " pos:[251,199] fieldWidth:80 align:#left
	colorpicker dColorPick "Dazzles Color : " pos:[247,226] fieldWidth:80 title:"Dazzles Color" align:#left

	checkbox MeshBonesCheck "Create Bones For Meshes Exported With Bone Transform" pos:[14,264]
	button RestoreButton "Restore" pos:[329,280] width:75

	groupBox ProfileSpec "Export Types Profiles:" width:410 height:116 pos:[4,326]

	checkbox UseOneProfile "Always Use The Selected Profile Above For All Type Of Exports" pos:[14,350]
	label CharProfile "Profile To Use For Characters Models :" pos:[20,380]
	dropdownlist cProfileCombo pos:[209,377] width:196 align:#left
	label VehicleProfile "Profile To Use For Vehicles Models :" pos:[31,410]
	dropdownlist vProfileCombo pos:[209,407] width:196 align:#left

	groupBox W3DPathGroup "Default W3D Path:" width:410 height:57 pos:[4,452]

	dropdownlist W3DPathCombo pos:[14,473] width:310 align:#left
	button BrowseButton "Browse" pos:[329,473] width:75

	button OkButton "OK" pos:[173,525] width:75
	button CancelButton "Cancel" pos:[254,525] width:75
	button ApplyButton "Apply" pos:[335,525] width:75

	fn UpdateProfile sel restore:false isNew:false fromInit:false=
	(
		local index = (13 * sel) - 12

		if sel <= 3 then
		(
			DeleteButton.enabled = false
			RestoreButton.enabled = true		)
		else
		(
			DeleteButton.enabled = true
			RestoreButton.enabled = false
		)

		if isNew do
		(
			W3DNewProfile.open (getDialogPos W3DPreferences)
			local newName = W3DNewProfile.NewName

			if newName != undefined then
			(
				local tmpProfiles = ProfileCombo.items
				
				if findItem tmpProfiles newName > 0 do
				(
					local nameIndex = 2, nameIndexArray = #()

					for i = 1 to tmpProfiles.count do
					(
						local tmpStr = tmpProfiles[i]
						if matchPattern tmpStr pattern:(newName + "(*)") do
						(
							nameIndex = (trimRight (trimLeft tmpStr (newName + "(")) ")") as integer
							append nameIndexArray nameIndex
						)
					)

					for i = 0 to nameIndexArray.count do
					(
						if findItem nameIndexArray (i+2) == 0 then
						(
							nameIndex = i + 2
							exit;
						)
					)

					newName = newName + "(" + nameIndex as string + ")"
				)

				append tmpProfiles newName
				ProfileCombo.items = tmpProfiles
				ProfileCombo.selection = sel
				sel = 1
				restore = true
			)
			else return false;
		)

		if restore do
		(
			local ProfileDefaults = W3DImporterInit.getProfileDefaults sel
			for i = 0 to 12 do ProfilesSettings[index+i] = ProfileDefaults[i+1]
		)

		bShapeCombo.selection = ProfilesSettings[index]
		bSizeEdit.text = ProfilesSettings[index+1] as string
		bColorPick.color = ProfilesSettings[index+2]
		pShapeCombo.selection = ProfilesSettings[index+3]
		pSizeEdit.text = ProfilesSettings[index+4] as string
		pColorPick.color = ProfilesSettings[index+5]
		aShapeCombo.selection = ProfilesSettings[index+6]
		aSizeEdit.text = ProfilesSettings[index+7] as string
		aColorPick.color = ProfilesSettings[index+8]
		dShapeCombo.selection = ProfilesSettings[index+9]
		dSizeEdit.text = ProfilesSettings[index+10] as string
		dColorPick.color = ProfilesSettings[index+11]
		MeshBonesCheck.checked = ProfilesSettings[index+12]

		ApplyButton.enabled = not fromInit
	)

	fn UpdateSettings controlChanged val=
	(
		local index = (13 * ProfileCombo.selection) - 12

		case controlChanged of
		(
			"BoneShape": ProfilesSettings[index] = val
			"BoneSize": ProfilesSettings[index+1] = val as float
			"BoneColor": ProfilesSettings[index+2] = val
			"ProxyShape": ProfilesSettings[index+3] = val
			"ProxySize": ProfilesSettings[index+4] = val as float
			"ProxyColor": ProfilesSettings[index+5] = val
			"AggregateShape": ProfilesSettings[index+6] = val
			"AggregateSize": ProfilesSettings[index+7] = val as float
			"AggregateColor": ProfilesSettings[index+8] = val
			"DazzleShape": ProfilesSettings[index+9] = val
			"DazzleSize": ProfilesSettings[index+10] = val as float
			"DazzleColor": ProfilesSettings[index+11] = val
			"MeshesBones": ProfilesSettings[index+12] = val
		)

		ApplyButton.enabled = true
	)

	fn UpdateProfSpec val newList:false fromInit:false=
	(
		if newList then
		(
			local cSel = cProfileCombo.selection
			local vSel = vProfileCombo.selection
			local listCount = cProfileCombo.items.count
			local newListCount = ProfileCombo.items.count

			cProfileCombo.items = ProfileCombo.items
			vProfileCombo.items = ProfileCombo.items

			if listCount > newListCount do
			(
				if cSel > val do cProfileCombo.selection = cSel - 1
				if cSel == val do cProfileCombo.selection = 2
				if vSel > val do vProfileCombo.selection = vSel - 1
				if vSel == val do vProfileCombo.selection = 3
			)
		)

		else
		(
			CharProfile.enabled = not val
			cProfileCombo.enabled = not val
			VehicleProfile.enabled = not val
			vProfileCombo.enabled = not val
		)

		ApplyButton.enabled = not fromInit
	)

	fn UpdateW3DPaths val=
	(
		local tmpPaths = W3DPathCombo.items
		local pathCount = tmpPaths.count
		local currentPath = tmpPaths[val]

		if pathCount > 1 do
		(
			while pathCount > 1 do
			(
				if pathCount <= val do tmpPaths[pathCount] = tmpPaths[pathCount-1]
				pathCount -= 1
			)
			tmpPaths[1] = currentPath
			W3DPathCombo.items = tmpPaths
			W3DPathCombo.selection = 1		)

		ApplyButton.enabled = true
	)

	fn ApplyChanges=
	(
		local ProfilesList = #(), W3DPathsList = #(), SettingsArray = #()

		join ProfilesList ProfileCombo.items
		join SettingsArray ProfilesSettings
		join W3DPathsList W3DPathCombo.items

		W3DImporterInit.ProfilesList = ProfilesList
		W3DImporterInit.UserProfiles = SettingsArray
		W3DImporterInit.W3DPaths = W3DPathsList
		W3DImporterInit.CurrentProfile = ProfileCombo.selection
		W3DImporterInit.UseOneProfile = UseOneProfile.checked
		W3DImporterInit.CharProfile = cProfileCombo.selection
		W3DImporterInit.VehicleProfile = vProfileCombo.selection

		W3DImporterInit.UpdateInitFile()

		ApplyButton.enabled = false
	)

	fn init=
	(
		local Shapes = #("Box","Sphere","Cylinder")
		local ProfilesList = #(), W3DPathsList = #(), SettingsArray = #()

		join ProfilesList W3DImporterInit.ProfilesList
		join SettingsArray W3DImporterInit.UserProfiles
		join W3DPathsList W3DImporterInit.W3DPaths

		ProfilesSettings = SettingsArray
		ProfileCombo.items = ProfilesList
		ProfileCombo.selection = W3DImporterInit.CurrentProfile
		bShapeCombo.items = Shapes
		pShapeCombo.items = Shapes
		aShapeCombo.items = Shapes
		dShapeCombo.items = Shapes
		UseOneProfile.checked = W3DImporterInit.UseOneProfile
		cProfileCombo.items = ProfilesList
		cProfileCombo.selection = W3DImporterInit.CharProfile
		vProfileCombo.items = ProfilesList
		vProfileCombo.selection = W3DImporterInit.VehicleProfile
		W3DPathCombo.items = W3DPathsList

		UpdateProfile ProfileCombo.selection fromInit:true
		UpdateProfSpec UseOneProfile.checked fromInit:true
	)

	fn Open XYPos=
	(
		createDialog W3DPreferences style:#(#style_titlebar, #style_sysmenu)
			
		init()
		setFocus W3DPreferences
	)

	on ProfileCombo selected val do UpdateProfile val

	on NewButton pressed do
	(
		if ProfileCombo.items.count < 20 then
		(
			UpdateProfile (ProfileCombo.items.count + 1) isNew:true
			UpdateProfSpec ProfileCombo.selection newList:true
		)

		else
		(
			local Str1 = "Dude, you already have 20 profiles !  How much more do you need ?      \n"
			local Str2 = "Delete or modify profiles that you dont use anymore.\n\n"
			local Str3 = "If you absolutly need more profiles, email me and explain me why\n"
			local Str4 = "exactly you would need more. I am already surprised that someone\n"
			local Str5 = "has got this message to pop up !\n"
			local BugSeekerStr = Str1 + Str2 + Str3 + Str4 + Str5
			messageBox BugSeekerStr title:"Profiles Limit Reached" beep:true
		)
	)

	on DeleteButton pressed do
	(
		local index, tmpSettings = #(), tmpProfiles = #()
		local profileCount = ProfileCombo.items.count
		local delProfile = ProfileCombo.selection

		for i = 1 to profileCount do
		(
			if i != delProfile do
			(
				index = (13 * i) - 12
				for j = 0 to 12 do append tmpSettings ProfilesSettings[index+j]
				append tmpProfiles ProfileCombo.items[i]
			)
		)

		if delProfile == profileCount do ProfileCombo.selection = profileCount - 1

		ProfilesSettings = tmpSettings
		ProfileCombo.items = tmpProfiles

		UpdateProfile ProfileCombo.selection
		UpdateProfSpec delProfile newList:true
	)

	on bShapeCombo selected val do UpdateSettings "BoneShape" val
	on bSizeEdit changed val do UpdateSettings "BoneSize" val
	on bColorPick changed val do UpdateSettings "BoneColor" val

	on pShapeCombo selected val do UpdateSettings "ProxyShape" val
	on pSizeEdit changed val do UpdateSettings "ProxySize" val
	on pColorPick changed val do UpdateSettings "ProxyColor" val

	on aShapeCombo selected val do UpdateSettings "AggregateShape" val
	on aSizeEdit changed val do UpdateSettings "AggregateSize" val
	on aColorPick changed val do UpdateSettings "AggregateColor" val

	on dShapeCombo selected val do UpdateSettings "DazzleShape" val
	on dSizeEdit changed val do UpdateSettings "DazzleSize" val
	on dColorPick changed val do UpdateSettings "DazzleColor" val

	on MeshBonesCheck changed val do UpdateSettings "MeshesBones" val

	on RestoreButton pressed do UpdateProfile ProfileCombo.selection restore:true

	on UseOneProfile changed val do UpdateProfSpec val
	on cProfileCombo selected val do ApplyButton.enabled = true
	on vProfileCombo selected val do ApplyButton.enabled = true

	on W3DPathCombo selected val do UpdateW3DPaths val
	on BrowseButton pressed do
	(
		local newW3DPath = #(), tmpPath = getSavePath caption:"Choose W3D Folder"

		if tmpPath != undefined do newW3DPath = getDirectories tmpPath

		if newW3DPath[1] != undefined do
		(
			local PathIndex = findItem W3DPathCombo.items newW3DPath[1]

			if PathIndex > 0 then UpdateW3DPaths PathIndex
			else
			(
				local tmpPaths = W3DPathCombo.items
				local pathCount = tmpPaths.count + 1

				while pathCount > 1 do
				(
					if pathCount <= 5 do tmpPaths[pathCount] = tmpPaths[pathCount-1]
					pathCount -= 1
				)
				tmpPaths[1] = newW3DPath[1]
				W3DPathCombo.items = tmpPaths
				W3DPathCombo.selection = 1

				ApplyButton.enabled = true
			)
		)
	)

	on OkButton pressed do
	(
		if ApplyButton.enabled do ApplyChanges()
		destroyDialog W3DPreferences
	)

	on CancelButton pressed do destroyDialog W3DPreferences
	on ApplyButton pressed do ApplyChanges()

	on W3DPreferences close do
	(
		W3DImportDlg.CurrentProfile = W3DImporterInit.CurrentProfile
		W3DImportDlg.UseOneProfile = W3DImporterInit.UseOneProfile
		W3DImportDlg.DefaultW3DPath = W3DImporterInit.W3DPaths[1]
	)
)

rcmenu W3DImportMenu 
( 
	fn recentExistA = W3DImporterInit.recentFiles[1] != ""
	fn recentExistB = W3DImporterInit.recentFiles[2] != ""
	fn recentExistC = W3DImporterInit.recentFiles[3] != ""
	fn recentExistD = W3DImporterInit.recentFiles[4] != ""
	fn recentExistE = W3DImporterInit.recentFiles[5] != ""

	subMenu "&File"
	(
		menuItem mi_s "&Select W3D"
		menuItem mi_m "Select From &Mix"
		separator sep1 
		menuItem mi_rfA "" filter:recentExistA
		menuItem mi_rfB "" filter:recentExistB
		menuItem mi_rfC "" filter:recentExistC
		menuItem mi_rfD "" filter:recentExistD
		menuItem mi_rfE "" filter:recentExistE
		separator sep2 filter:recentExistA
		menuItem mi_x "E&xit"
	) 

	subMenu "&Edit"
	(
		menuItem mi_p "&Preferences..."
	)

	subMenu "&Help"
	(
		menuItem mi_h "&W3D Importer References"
		separator sep3
		menuItem mi_a "&About W3D Importer"
	)

	on mi_s picked do W3DImportDlg.SelectW3D()
	on mi_m picked do W3DImportDlg.SelectMix()
	on mi_x picked do destroyDialog W3DImportDlg
	on mi_rfA picked do W3DImportDlg.SelectW3D fname:W3DImporterInit.recentFiles[1]
	on mi_rfB picked do W3DImportDlg.SelectW3D fname:W3DImporterInit.recentFiles[2]
	on mi_rfC picked do W3DImportDlg.SelectW3D fname:W3DImporterInit.recentFiles[3]
	on mi_rfD picked do W3DImportDlg.SelectW3D fname:W3DImporterInit.recentFiles[4]
	on mi_rfE picked do W3DImportDlg.SelectW3D fname:W3DImporterInit.recentFiles[5]
	on mi_h picked do actionMan.executeAction 0 "40218"
	on mi_a picked do W3DImportAboutDlg.Open (getDialogPos W3DImportDlg)
	on mi_p picked do
	(
--		try (
			W3DPreferences.Open (getDialogPos W3DImportDlg)
--		)
--		catch
--		(
--			messageBox "Error occured launching Importer's preferences dialog."
--		)
	)
) 

fn OpenW3DImporter=
(
	if W3DImporterInit.open() then
	(
--		try
--		(
			W3DImporterInit.init()
			W3DImporterInit.close()
--		)
--		catch
--		(
--			messageBox "An error occured Initializing W3D Importer."
--		)
	)
	else messageBox "W3D-Importer.ini not found!\n Make sure it is in plugins\n\n"

	W3DImportMenu.mi_rfA.text = "&1 " + W3DImporterInit.recentFiles[1]
	W3DImportMenu.mi_rfB.text = "&2 " + W3DImporterInit.recentFiles[2]
	W3DImportMenu.mi_rfC.text = "&3 " + W3DImporterInit.recentFiles[3]
	W3DImportMenu.mi_rfD.text = "&4 " + W3DImporterInit.recentFiles[4]
	W3DImportMenu.mi_rfE.text = "&5 " + W3DImporterInit.recentFiles[5]

--	try
--	(
		createDialog W3DImportDlg menu:W3DImportMenu style:#(#style_titlebar, #style_minimizebox, #style_sysmenu)
			

		setFocus W3DImportDlg
--	)
--	catch
--	(
--		messageBox "An error occured trying to launch W3D Importer."
--	)
)

callbacks.addScript #postSystemStartup "setSaveRequired false" id:#W3D_Editor
callbacks.addScript #filePostOpen "setW3DAppTitle()" id:#W3D_Editor
callbacks.addScript #PostImport "setW3DAppTitle()" id:#W3D_Editor
callbacks.addScript #systemPostNew "setW3DAppTitle()" id:#W3D_Editor
callbacks.addScript #systemPostReset "setW3DAppTitle()" id:#W3D_Editor
callbacks.addScript #preExport "clearW3DFlags()" id:#W3D_Editor
callbacks.addScript #postExport "restoreW3DFlags()" id:#W3D_Editor
callbacks.addScript #exportFailed "restoreW3DFlags()" id:#W3D_Editor
-- callbacks.addScript #filePreSave "Saving()" id:#W3D_Editor
-- callbacks.addScript #filePostSave "Saved()" id:#W3D_Editor
