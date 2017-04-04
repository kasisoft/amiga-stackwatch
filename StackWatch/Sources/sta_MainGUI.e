/* -- ----------------------------------------------------------------- -- *
 * -- Program.....: sta_Runner.e                                        -- *
 * -- Author......: Daniel Kasmeroglu <raptor@cs.tu-berlin.de>          -- *
 * -- Description.: StackWatcher                                        -- *
 * -- Version.....: 1.2 (30.01.1999) Updated new structure              -- *
 * -- ----------------------------------------------------------------- -- */

/* -- ----------------------------------------------------------------- -- *
 * --                              Options                              -- *
 * -- ----------------------------------------------------------------- -- */

OPT PREPROCESS       -> enable preprocessor
OPT MODULE           -> generate module


/* -- ----------------------------------------------------------------- -- *
 * --                              Modules                              -- *
 * -- ----------------------------------------------------------------- -- */

->»» LIST OF MODULES
MODULE 'libraries/gadtools'    ,
       'libraries/bguim'       ,
       'libraries/bgui'        ,
       'dos/dosextens'         ,
       'graphics/text'         ,
       'intuition/gadgetclass' ,
       'intuition/intuition'   ,
       'intuition/classes'     ,
       'intuition/screens'     ,
       'utility/tagitem'       ,
       'utility/hooks'         ,
       'tools/inithook'        ,
       'tools/boopsi'          ,
       'amigalib/lists'        ,
       'bgui/image'            ,
       'kasimir/commodity'     ,
       'exec/execbase'         ,
       'exec/memory'           ,
       'exec/tasks'            ,
       'exec/lists'            ,
       'exec/nodes'

MODULE 'lib/bgui'

MODULE '*sta_Localisation'
->»»>


/* -- ----------------------------------------------------------------- -- *
 * --                             Constants                             -- *
 * -- ----------------------------------------------------------------- -- */

->»» Handler ID's
ENUM GID_GAUGE = 1 ,
     GID_SELECTED  ,
     GID_INFO      ,
     GID_LIST      ,
     GID_ABOUT     ,
     GID_REFRESH   ,
     GID_STOP      ,
     GROUP_MAIN    ,
     NUMBER        ,
     POPKEYID      ,
     MID_HIDE      ,
     MID_QUIT

CONST TICKS = 10
->»»>


/* -- ----------------------------------------------------------------- -- *
 * --                            Structures                             -- *
 * -- ----------------------------------------------------------------- -- */

->»» OBJECT entry
OBJECT entry OF mln
  ent_Name [ 128 ] : ARRAY OF CHAR
  ent_Size         : LONG
  ent_Max          : LONG
  ent_Task         : PTR TO tc
ENDOBJECT
->»»>

->»» OBJECT stackwatch
EXPORT OBJECT stackwatch OF commodity
  sta_Gadgets[ NUMBER ] : ARRAY OF LONG    -> the used objects
  sta_ExecBase          : PTR TO execbase  -> simple for dereferencing
  sta_CurrentTask       : PTR TO tc        -> the current selected task or NIL
  sta_CurrentEntry      : PTR TO entry     -> the current selected entry or NIL
  sta_List              : mlh              -> this list contains all tasks
  sta_CompareHook       : hook             -> hook for list comparison
  sta_ResourceHook      : hook             -> a simple resource-hook
  sta_IDCMPHook         : hook             -> an IDCMP-Hook
  sta_Selected          : PTR TO LONG      -> a taglist
  sta_Info              : PTR TO LONG      -> a taglist
  sta_Ticks             : INT              -> the number of ticks
  sta_Broker            : INT              -> 0 = No broker, else broker available
  sta_Menu              : PTR TO newmenu   -> menu structure
ENDOBJECT
->»»>


/* -- ----------------------------------------------------------------- -- *
 * --                           Declarations                            -- *
 * -- ----------------------------------------------------------------- -- */

EXPORT DEF glo_popkey,glo_popup,glo_screen


/* -- ----------------------------------------------------------------- -- *
 * --                              Methods                              -- *
 * -- ----------------------------------------------------------------- -- */

->»» METHOD sta_Constructor
PROC sta_Constructor() OF stackwatch

  self.sta_InitStuff()
  self.sta_InitObjects()

  self.sta_Broker := self.com_Constructor( loc_GetString( GLO_COMMNAME ), loc_GetString( GLO_COMMTITLE ), loc_GetString( GLO_COMMDESC ), glo_popkey, POPKEYID, {intern_GetTasks} )

  self.com_ObjectWindow := WindowObject,
                             WINDOW_ScreenTitle,     loc_GetString( GLO_SCREENTITLE ),
                             WINDOW_Title,           loc_GetString( GLO_TITLE       ),
                             WINDOW_SmartRefresh,    TRUE,
                             WINDOW_AutoAspect,      TRUE,
                             WINDOW_AutoKeyLabel,    TRUE,
                             WINDOW_CloseOnEsc,      TRUE,
                             WINDOW_ScaleWidth,      20,
                             WINDOW_ScaleHeight,     20,
                             WINDOW_ToolTicks,       50,
                             WINDOW_Screen,          glo_screen,
                             WINDOW_MenuStrip,       self.sta_Menu,
                             WINDOW_IDCMPHookBits,   IDCMP_INTUITICKS,
                             WINDOW_IDCMPHook,       self.sta_IDCMPHook,
                             WINDOW_MasterGroup,     self.sta_Gadgets[ GROUP_MAIN ],
                           EndObject

  IF self.com_ObjectWindow = NIL THEN Raise( "MEM" )

ENDPROC
->»»>

->»» METHOD sta_InitObjects
PROC sta_InitObjects() OF stackwatch
DEF ini_run,ini_err

  self.sta_Gadgets[ GID_INFO     ] := intern_PInfo   ( TTI_MAIN_INFO     , NIL              , GLO_INFOFORMAT        , self.sta_Info        , 2 )
  self.sta_Gadgets[ GID_SELECTED ] := intern_PInfo   ( TTI_MAIN_SELECTED , NIL              , GLO_SELFORMAT         , self.sta_Selected    , 1 )
  self.sta_Gadgets[ GID_LIST     ] := intern_PList   ( TTI_MAIN_LIST     , NIL              , self.sta_ResourceHook , self.sta_CompareHook )
  self.sta_Gadgets[ GID_ABOUT    ] := intern_PButton ( MAIN_ABOUT        , TTI_MAIN_ABOUT   , NIL )
  self.sta_Gadgets[ GID_REFRESH  ] := intern_PButton ( MAIN_REFRESH      , TTI_MAIN_REFRESH , NIL )
  self.sta_Gadgets[ GID_STOP     ] := intern_PButton ( MAIN_STOP         , TTI_MAIN_STOP    , NIL )
  self.sta_Gadgets[ GID_GAUGE    ] := intern_PGauge  ( TTI_MAIN_GAUGE    , NIL              )

  ini_err := FALSE
  FOR ini_run := GID_GAUGE TO GID_STOP
    IF self.sta_Gadgets[ ini_run ] <> NIL
      SetAttrsA( self.sta_Gadgets[ ini_run ], [ GA_ID, ini_run, TAG_END ] )
    ELSE
      ini_err := TRUE
    ENDIF
  ENDFOR

  IF ini_err = FALSE

    self.sta_Gadgets[ GROUP_MAIN ] := VGroupObject,
                                        NoFrame,
                                        NormalOffset,
                                        NormalSpacing,
                                        ShineRaster,
                                        StartMember,
                                          VGroupObject,
                                            NormalSpacing,
                                            EqualHeight,
                                            StartMember,
                                              self.sta_Gadgets[ GID_SELECTED ],
                                            EndMember,
                                            StartMember,
                                              self.sta_Gadgets[ GID_GAUGE ],
                                            EndMember,
                                          EndObject,
                                          FixMinHeight,
                                        EndMember,
                                        StartMember,
                                          self.sta_Gadgets[ GID_INFO ],
                                          FixMinHeight,
                                        EndMember,
                                        StartMember,
                                          self.sta_Gadgets[ GID_LIST ],
                                        EndMember,
                                        StartMember,
                                          HGroupObject,
                                            NoFrame,
                                            ShineRaster,
                                            NormalSpacing,
                                            StartMember,
                                              self.sta_Gadgets[ GID_ABOUT ],
                                            EndMember,
                                            StartMember,
                                              self.sta_Gadgets[ GID_REFRESH ],
                                            EndMember,
                                            StartMember,
                                              self.sta_Gadgets[ GID_STOP ],
                                            EndMember,
                                          EndObject,
                                          FixMinHeight,
                                        EndMember,
                                      EndObject

    IF self.sta_Gadgets[ GROUP_MAIN ] = NIL THEN ini_err := TRUE

  ENDIF

  IF ini_err <> FALSE
    FOR ini_run := GID_GAUGE TO GID_STOP
      IF self.sta_Gadgets[ ini_run ] <> NIL
        DisposeObject( self.sta_Gadgets[ ini_run ] )
      ENDIF
    ENDFOR
    Raise( "MEM" )
  ENDIF

ENDPROC
->»»>

->»» METHOD sta_InitStuff
PROC sta_InitStuff() OF stackwatch

  newList( self.sta_List )

  self.sta_Ticks       := 0
  self.sta_ExecBase    := execbase
  self.sta_Selected    := [ {lab_ZeroString} ]
  self.sta_Info        := [ 0, {lab_FillString}, 0, 0 ]

  self.sta_Menu := StartMenu,
                     Title( loc_GetString( MENU_TITLE ) ),
                       Item( loc_GetString( MENU_HIDE  ), loc_GetString( MENU_HIDESHORT  ), MID_HIDE  ),
                       Item( loc_GetString( MENU_ABOUT ), loc_GetString( MENU_ABOUTSHORT ), GID_ABOUT ),
                       ItemBar,
                       Item( loc_GetString( MENU_QUIT  ), loc_GetString( MENU_QUITSHORT  ), MID_QUIT  ),
                   End

  inithook( self.sta_IDCMPHook,    { hoo_IDCMPHook    } , self )
  inithook( self.sta_CompareHook,  { hoo_CompareHook  } )
  inithook( self.sta_ResourceHook, { hoo_ResourceHook } )

ENDPROC
->»»>

->»» METHOD sta_StartInterface
PROC sta_StartInterface() OF stackwatch
DEF sta_running,sta_received

  sta_running := TRUE

  -> open the window if requested or broker is not available
  IF (glo_popup <> FALSE) OR (self.sta_Broker = FALSE)
    self.com_OpenWindow()
  ENDIF

  -> run the broker (checks itselfs if it's available)
  self.com_RunBroker()

  WHILE sta_running <> FALSE

    sta_received := Wait( self.com_Signal() )

    IF self.com_CommodityEvent( sta_received ) <> FALSE
      sta_running := self.com_BrokerSignal()
    ENDIF

    IF self.com_WindowEvent( sta_received ) <> FALSE
      sta_running := self.sta_WindowSignal()
    ENDIF

  ENDWHILE

ENDPROC
->»»>

->»» METHOD sta_WindowSignal
PROC sta_WindowSignal() OF stackwatch
DEF sta_running,sta_rc

  sta_running := TRUE
  WHILE (sta_rc := HandleEvent( self.com_ObjectWindow )) <> WMHI_NOMORE

    SELECT sta_rc
    CASE GID_LIST         ; self.sta_StartMonitoring()
    CASE GID_STOP         ; self.sta_EndMonitoring()
    CASE GID_ABOUT        ; intern_About( self )
    CASE MID_HIDE         ; RETURN self.com_CloseWindow()
    CASE WMHI_CLOSEWINDOW ; RETURN self.com_CloseWindow()
    CASE GID_REFRESH
      self.sta_EndMonitoring()
      intern_GetTasks( self )
    CASE MID_QUIT
      self.sta_EndMonitoring()
      sta_running := FALSE
    ENDSELECT

  ENDWHILE

ENDPROC sta_running
->»»>

->»» METHOD sta_AddEntry
PROC sta_AddEntry( add_node : PTR TO entry ) OF stackwatch
DEF add_current : PTR TO entry
DEF add_found

  add_found   := FALSE
  add_current := self.sta_List.head

  WHILE (add_current.succ <> NIL) AND (add_found = FALSE)

    IF add_current.ent_Task = add_node.ent_Task
      add_found := TRUE
    ELSE
      add_current := add_current.succ
    ENDIF

  ENDWHILE

  IF add_found <> FALSE
    add_current.ent_Max := Max( add_current.ent_Max, add_node.ent_Max )
    FreeVec( add_node )
  ELSE
    AddTail( self.sta_List, add_node )
  ENDIF

ENDPROC
->»»>

->»» METHOD sta_ScanList
PROC sta_ScanList( sca_pnode : PTR TO process ) OF stackwatch
DEF sca_name [ 128 ] : STRING
DEF sca_node         : PTR TO entry
DEF sca_cli          : PTR TO commandlineinterface
DEF sca_len

  WHILE sca_pnode::ln.succ <> NIL

    IF (sca_pnode::ln.type = NT_PROCESS) OR (sca_pnode::ln.type = NT_TASK)

      sca_cli := Shl( sca_pnode.cli, 2 )
      IF (sca_cli = 0) OR (sca_cli.module = 0) OR (sca_pnode::ln.type = NT_TASK)

        sca_node := intern_AllocEntry( sca_pnode::ln.name, sca_pnode )
        IF sca_node <> FALSE THEN self.sta_AddEntry( sca_node )

      ELSE

        sca_len := Char( Shl( sca_cli.commandname, 2 ) )
        StringF( sca_name, '\s', Shl( sca_cli.commandname, 2 ) + 1 )

        sca_node := intern_AllocEntry( sca_name, sca_pnode )
        IF sca_node <> FALSE THEN self.sta_AddEntry( sca_node )

      ENDIF

    ENDIF

    sca_pnode := sca_pnode::ln.succ

  ENDWHILE

ENDPROC
->»»>

->»» METHOD sta_StartMonitoring
PROC sta_StartMonitoring() OF stackwatch
DEF sta_entry : PTR TO entry

  sta_entry             := FirstSelected( self.sta_Gadgets[ GID_LIST ] )
  sta_entry             := sta_entry - SIZEOF mln
  self.sta_CurrentTask  := sta_entry.ent_Task
  self.sta_CurrentEntry := sta_entry

  self.sta_Selected[0]  := sta_entry.ent_Name
  self.sta_SetInfo( GID_SELECTED, self.sta_Selected )

  SetGadgetAttrsA( self.sta_Gadgets[ GID_SELECTED ], self.com_Window, NIL,
  [ PROGRESS_Max, sta_entry.ent_Size, TAG_END ] )

  intern_UpdateDisplay( self )

ENDPROC
->»»>

->»» METHOD sta_EndMonitoring
PROC sta_EndMonitoring() OF stackwatch

  self.sta_CurrentTask    := NIL
  self.sta_CurrentEntry   := NIL
  self.sta_Selected [ 0 ] := {lab_ZeroString}
  self.sta_Info     [ 0 ] := 0
  self.sta_Info     [ 2 ] := 0
  self.sta_Info     [ 3 ] := 0

  self.sta_SetInfo( GID_SELECTED , self.sta_Selected )
  self.sta_SetInfo( GID_INFO     , self.sta_Info     )

  SetGadgetAttrsA( self.sta_Gadgets[ GID_GAUGE ], self.com_Window, NIL,
  [ PROGRESS_Done, 0, TAG_END ] )

ENDPROC
->»»>

->»» METHOD sta_SetInfo
PROC sta_SetInfo( set_id, set_args ) OF stackwatch
DEF set_tags : PTR TO LONG

  set_tags := [ INFO_Args, set_args, TAG_END ]
  SetGadgetAttrsA( self.sta_Gadgets[ set_id ], self.com_Window, NIL, set_tags )

ENDPROC
->»»>

->»» METHOD end
PROC end() OF stackwatch

  IF self.com_ObjectWindow <> NIL
    DisposeObject( self.com_ObjectWindow )
  ELSEIF self.sta_Gadgets[ GROUP_MAIN ] <> NIL
    DisposeObject( self.sta_Gadgets[ GROUP_MAIN ] )
  ENDIF

  -> remove the commodity
  self.com_Destructor()

ENDPROC
->»»>


/* -- ----------------------------------------------------------------- -- *
 * --                         Helping Routines                          -- *
 * -- ----------------------------------------------------------------- -- */

->»» PROC intern_GetTasks
PROC intern_GetTasks( get_swatch : PTR TO stackwatch )

  Forbid()
  Disable()

  ClearList( get_swatch.com_Window, get_swatch.sta_Gadgets[ GID_LIST ] )

  get_swatch.sta_ScanList( get_swatch.sta_ExecBase.taskwait.head  )
  get_swatch.sta_ScanList( get_swatch.sta_ExecBase.taskready.head )

  intern_RemoveUnused( get_swatch )
  intern_AddEntries( get_swatch )

  RefreshList( get_swatch.com_Window, get_swatch.sta_Gadgets[ GID_LIST ] )

  Enable()
  Permit()

ENDPROC
->»»>

->»» PROC intern_AddEntries
-> Simple routine which adds all entries from
-> our internal exec-list to the listview.
PROC intern_AddEntries( add_swatch : PTR TO stackwatch )
DEF add_node : PTR TO entry

  add_node := add_swatch.sta_List.head
  WHILE add_node.succ <> NIL
    AddEntry( add_swatch.com_Window, add_swatch.sta_Gadgets[ GID_LIST  ], add_node, LVAP_SORTED )
    add_node := add_node.succ
  ENDWHILE

ENDPROC
->»»>

->»» PROC intern_AllocEntry
-> Creates an entry and fills it with initial data.
PROC intern_AllocEntry( all_name, all_process : PTR TO tc )
DEF all_node : PTR TO entry

  all_node := AllocVec( SIZEOF entry, MEMF_PUBLIC )
  IF all_node <> NIL
    StringF( all_node.ent_Name, '\s', all_name )
    all_node.ent_Size := all_process.spupper - all_process.splower
    all_node.ent_Max  := all_process.spupper - all_process.spreg
    all_node.ent_Task := all_process
  ENDIF

ENDPROC all_node
->»»>

->»» PROC intern_RemoveUnused
-> This routine removes all unused entries.
PROC intern_RemoveUnused( rem_swatch : PTR TO stackwatch )
DEF rem_node : PTR TO entry
DEF rem_kill : PTR TO entry

  Forbid()
  rem_node := rem_swatch.sta_List.head
  WHILE rem_node.succ <> NIL
    IF intern_SearchList( rem_swatch, rem_node.ent_Task ) = FALSE
      rem_kill := rem_node
      rem_node := rem_node.succ
      Remove( rem_kill )
      FreeVec( rem_kill )
    ELSE
      rem_node := rem_node.succ
    ENDIF
  ENDWHILE
  Permit()

ENDPROC
->»»>

->»» PROC intern_SearchList
-> Returns TRUE if a task is currently available, otherwise FALSE
PROC intern_SearchList( sea_swatch : PTR TO stackwatch, sea_task = NIL )
DEF sea_node : PTR TO entry
DEF sea_list : PTR TO mlh

  Forbid()
  Disable()

  IF sea_task = NIL THEN sea_task := sea_swatch.sta_CurrentTask

  sea_list := sea_swatch.sta_ExecBase.taskwait
  sea_node := sea_list.head
  WHILE sea_node.succ <> NIL
    IF sea_node = sea_task
      Enable()
      Permit()
      RETURN TRUE
    ENDIF
    sea_node := sea_node.succ
  ENDWHILE

  sea_list := sea_swatch.sta_ExecBase.taskready
  sea_node := sea_list.head
  WHILE sea_node.succ <> NIL
    IF sea_node = sea_task
      Enable()
      Permit()
      RETURN TRUE
    ENDIF
    sea_node := sea_node.succ
  ENDWHILE

  Enable()
  Permit()

ENDPROC FALSE
->»»>

->»» PROC intern_About
PROC intern_About( abo_swatch : PTR TO stackwatch )
DEF abo_request : bguiRequest

  abo_request.flags        := BREQF_CENTERWINDOW OR BREQF_LOCKWINDOW OR BREQF_AUTO_ASPECT
  abo_request.title        := loc_GetString( GLO_ABOUT  )
  abo_request.gadgetFormat := loc_GetString( GLO_ANSWER )
  abo_request.textFormat   := loc_GetString( GLO_BODY   )
  abo_request.screen       := abo_swatch.com_Window.wscreen
  abo_request.underscore   := "_"
  abo_request.textAttr     := abo_swatch.com_Window.wscreen.font

  BgUI_RequestA( abo_swatch.com_Window, abo_request, NIL )

ENDPROC
->»»>

->»» PROC intern_UpdateDisplay
PROC intern_UpdateDisplay( get_swatch : PTR TO stackwatch )
DEF get_entry : PTR TO entry
DEF get_newstack

  IF get_swatch.sta_CurrentTask <> NIL

    Forbid()

    IF intern_SearchList( get_swatch ) = FALSE

      get_entry := get_swatch.sta_CurrentEntry
      RemoveEntry( get_swatch.sta_Gadgets[ GID_LIST ], get_entry + SIZEOF mln )
      Remove( get_entry )
      FreeVec( get_entry )
      RefreshList( get_swatch.com_Window, get_swatch.sta_Gadgets[ GID_LIST ] )

      get_swatch.sta_EndMonitoring()

      get_swatch.sta_Selected [ 0 ] := loc_GetString( MSG_TASKFINISHED )
      get_swatch.sta_Info     [ 0 ] := 0
      get_swatch.sta_Info     [ 2 ] := 0
      get_swatch.sta_Info     [ 3 ] := 0
      get_swatch.sta_SetInfo( GID_SELECTED , get_swatch.sta_Selected )
      get_swatch.sta_SetInfo( GID_INFO     , get_swatch.sta_Info     )

    ENDIF

    IF get_swatch.sta_CurrentTask <> NIL

      get_entry         := get_swatch.sta_CurrentEntry
      get_newstack      := get_entry.ent_Task.spupper - get_entry.ent_Task.spreg
      get_entry.ent_Max := Max( get_newstack, get_entry.ent_Max )

      IF get_newstack > get_entry.ent_Size
        get_swatch.sta_Selected [ 0 ] := loc_GetString( MSG_OVERFLOW )
        get_swatch.sta_SetInfo( GID_SELECTED, get_swatch.sta_Selected )
      ENDIF

      SetGadgetAttrsA( get_swatch.sta_Gadgets[ GID_GAUGE ], get_swatch.com_Window, NIL,
      [ PROGRESS_Done, get_newstack, TAG_END ] )

      get_swatch.sta_Info [ 0 ] := get_newstack
      get_swatch.sta_Info [ 2 ] := get_entry.ent_Size
      get_swatch.sta_Info [ 3 ] := get_entry.ent_Max
      get_swatch.sta_SetInfo( GID_INFO, get_swatch.sta_Info )

    ENDIF

    Permit()

  ENDIF

ENDPROC
->»»>

->++++++++++++++++++++++++++++++++++++++++++++++++++++++
-> the next procedures are only used for object creation

->»» PROC intern_PButton
PROC intern_PButton( labid, ttid, node )
ENDPROC ButtonObject   ,
          ButtonFrame  ,
          LAB_Label    , loc_GetString( labid ) ,
          BT_ToolTip   , loc_GetString( ttid  ) ,
          BT_HelpNode  , node                   ,
        EndObject
->»»>

->»» PROC intern_PGauge
PROC intern_PGauge( ttid, node )
ENDPROC ProgressObject     ,
          ButtonFrame      ,
          FRM_Flags        , FRF_RECESSED          ,
          BT_ToolTip       , loc_GetString( ttid ) ,
          BT_HelpNode      , node                  ,
          PROGRESS_Divisor , 50                    ,
        EndObject
->»»>

->»» PROC intern_PInfo
PROC intern_PInfo( ttid, node, tfid, args, ml )
ENDPROC InfoObject          ,
          ButtonFrame       ,
          FRM_Flags         , FRF_RECESSED          ,
          BT_ToolTip        , loc_GetString( ttid ) ,
          BT_HelpNode       , node                  ,
          INFO_TextFormat   , loc_GetString( tfid ) ,
          INFO_Args         , args                  ,
          INFO_MinLines     , ml                    ,
          INFO_FixTextWidth , TRUE                  ,
        EndObject
->»»>

->»» PROC intern_PList
PROC intern_PList( ttid, node, res, com )
ENDPROC ListviewObject       ,
          BT_ToolTip         , loc_GetString( ttid ) ,
          BT_HelpNode        , node                  ,
          LISTV_ResourceHook , res                   ,
          LISTV_CompareHook  , com                   ,
          PGA_NEWLOOK        , TRUE                  ,
        EndObject
->»»>


/* -- ----------------------------------------------------------------- -- *
 * --                           Hook-Routines                           -- *
 * -- ----------------------------------------------------------------- -- */

->»» PROC hoo_CompareHook
PROC hoo_CompareHook( com_hook, com_obj, com_lvc : PTR TO lvCompare )
DEF com_strb [ 128 ] : STRING
DEF com_stra [ 128 ] : STRING

  StringF( com_stra, '\s', com_lvc.entryA )
  StringF( com_strb, '\s', com_lvc.entryB )

  LowerStr( com_stra )
  LowerStr( com_strb )

ENDPROC OstrCmp( com_strb, com_stra )
->»»>

->»» PROC hoo_ResourceHook
PROC hoo_ResourceHook( res_hook, res_obj, res_lvr : PTR TO lvResource )
  IF res_lvr.command = LVRC_MAKE THEN RETURN res_lvr.entry + SIZEOF mln
ENDPROC NIL
->»»>

->»» PROC hoo_IDCMPHook
PROC hoo_IDCMPHook( idc_hook : PTR TO hook, idc_obj, idc_msg : PTR TO intuimessage )
DEF idc_swatch : PTR TO stackwatch

  IF idc_msg.class = IDCMP_INTUITICKS
    idc_swatch           := idc_hook.data
    idc_swatch.sta_Ticks := idc_swatch.sta_Ticks + 1
    IF idc_swatch.sta_Ticks = TICKS
      intern_UpdateDisplay( idc_swatch )
      idc_swatch.sta_Ticks := 0
    ENDIF
  ENDIF

ENDPROC
->»»>


/* -- ----------------------------------------------------------------- -- *
 * --                               Data                                -- *
 * -- ----------------------------------------------------------------- -- */

lab_FillString:
CHAR '      ',0

lab_ZeroString:
CHAR 0,0
