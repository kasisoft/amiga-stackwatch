/* -- ----------------------------------------------------------------- -- *
 * -- Program.....: sta_Runner.e                                        -- *
 * -- Author......: Daniel Kasmeroglu <raptor@cs.tu-berlin.de>          -- *
 * -- Description.: Main program of StackWatch                          -- *
 * -- Version.....: 1.2 (30.01.1999) Updated new structure              -- *
 * -- ----------------------------------------------------------------- -- */

/* -- ----------------------------------------------------------------- -- *
 * --                              Options                              -- *
 * -- ----------------------------------------------------------------- -- */

OPT REG = 5          -> register-optimisation


/* -- ----------------------------------------------------------------- -- *
 * --                              Modules                              -- *
 * -- ----------------------------------------------------------------- -- */

->»» LIST OF MODULES
MODULE 'kasimir/setstack'    ,   -> kasimir is my nickname ;-)
       'libraries/locale'    ,
       'utility/tagitem'     ,
       'workbench/workbench' ,
       'workbench/startup'   ,
       'lib/locale'          ,
       'lib/bgui'            ,
       'lib/icon'

MODULE '*sta_Localisation' ,
       '*sta_MainGUI'

->»»>


/* -- ----------------------------------------------------------------- -- *
 * --                             Constants                             -- *
 * -- ----------------------------------------------------------------- -- */

ENUM ARG_POPUP     ,
     ARG_POPKEY    ,
     ARG_PUBSCREEN


/* -- ----------------------------------------------------------------- -- *
 * --                            Procedures                             -- *
 * -- ----------------------------------------------------------------- -- */

->»» PROC intern_GetCLIArgs
PROC intern_GetCLIArgs( get_args : PTR TO LONG )
DEF get_rdargs,get_string

  get_rdargs := ReadArgs( 'CX_POPUP/S,CX_POPKEY,PS=PUBSCREEN/K', get_args, NIL )
  IF get_rdargs <> NIL

    get_string := String( StrLen( get_args[ ARG_POPKEY ] ) + 1 )
    IF get_string <> NIL THEN StringF( get_string, '\s', get_args[ ARG_POPKEY ] )
    get_args[ ARG_POPKEY ] := get_string

    get_string := String( StrLen( get_args[ ARG_PUBSCREEN ] ) + 1 )
    IF get_string <> NIL THEN StringF( get_string, '\s', get_args[ ARG_PUBSCREEN ] )
    get_args[ ARG_PUBSCREEN ] := get_string

    FreeArgs( get_rdargs )

  ENDIF

ENDPROC
->»»>

->»» PROC intern_GetWBArgs
PROC intern_GetWBArgs( get_args : PTR TO LONG, get_wbmessage : PTR TO wbstartup )
DEF get_icon         : PTR TO diskobject
DEF get_wbarg        : PTR TO wbarg
DEF get_array        : PTR TO LONG
DEF get_buff [ 100 ] : STRING
DEF get_string,get_err,get_old

  get_err  := FALSE

  iconbase := OpenLibrary( 'icon.library', 33 )
  IF iconbase <> NIL

    get_wbarg := get_wbmessage.arglist
    get_old   := -1
    IF (get_wbarg.lock <> NIL) AND (get_wbarg.name[] <> 0) THEN get_old := CurrentDir( get_wbarg.lock )

    get_icon  := GetDiskObject( get_wbarg.name )
    IF get_icon <> NIL

      get_array := get_icon.tooltypes

      -> // CX_POPUP
      get_string := FindToolType( get_array, 'CX_POPUP' )
      IF get_string <> NIL
        StringF( get_buff, '\s', get_string )
        LowerStr( get_buff )
        IF StrCmp( get_buff, 'yes' ) <> FALSE
          get_args[ ARG_POPUP ] := TRUE
        ELSE
          get_args[ ARG_POPUP ] := FALSE
        ENDIF
      ENDIF

      -> // CX_POPKEY
      get_string := FindToolType( get_array, 'CX_POPKEY' )
      IF get_string <> NIL
        get_args[ ARG_POPKEY ] := String( StrLen( get_string ) + 1 )
        IF get_args[ ARG_POPKEY ] <> NIL
          StringF( get_args[ ARG_POPKEY ], '\s', get_string )
          LowerStr( get_args[ ARG_POPKEY ] )
        ENDIF
      ENDIF

      -> // PUBSCREEN
      get_string    := FindToolType( get_array, 'PUBSCREEN' )
      IF get_string <> NIL
        get_args[ ARG_PUBSCREEN ] := String( StrLen( get_string ) + 1 )
        IF get_args[ ARG_PUBSCREEN ] <> NIL
          StringF( get_args[ ARG_PUBSCREEN ], '\s', get_string )
        ENDIF
      ENDIF

      FreeDiskObject( get_icon )

    ENDIF

    IF get_old <> -1 THEN CurrentDir( get_old )
    CloseLibrary( iconbase )

  ELSE
    get_err := TRUE
  ENDIF

ENDPROC get_err
->»»>


/* -- ----------------------------------------------------------------- -- *
 * --                               Main                                -- *
 * -- ----------------------------------------------------------------- -- */

->»» PROC main
PROC main() HANDLE
DEF ma_object : PTR TO stackwatch
DEF ma_args   : PTR TO LONG

  setstack( 10704 )
  ma_object := NIL

  ->»» check out all arguments
  ma_args   := [ FALSE, 'alt s', NIL ]

  IF wbmessage <> NIL
    intern_GetWBArgs( ma_args, wbmessage )
  ELSE
    intern_GetCLIArgs( ma_args )
  ENDIF

  glo_popup  := ma_args[ ARG_POPUP  ]
  IF ma_args[ ARG_POPKEY ] <> NIL
    glo_popkey := ma_args[ ARG_POPKEY ]
  ELSE
    glo_popkey := 'alt s'
  ENDIF

  glo_screen := LockPubScreen( ma_args[ ARG_PUBSCREEN ] )
  IF glo_screen = NIL THEN glo_screen := LockPubScreen( NIL )
  ->»»>

  ->»» open the libraries and the catalog
  bguibase  := OpenLibrary( 'bgui.library', 37 )
  IF bguibase = NIL THEN Raise( ERR_LIBRARY )

  localebase := OpenLibrary( 'locale.library', 38 )
  IF localebase <> NIL
    glo_catalog := OpenCatalogA( NIL, 'StackWatch.catalog', [ OC_BUILTINLANGUAGE, 'english', TAG_END ] )
  ELSE
    Vprintf( loc_GetString( ERR_LIBWARN ), [ 'locale.library', 38 ] )
  ENDIF
  ->»»>

  NEW ma_object.sta_Constructor()
  ma_object.sta_StartInterface()

EXCEPT DO

  ->»» print out the error-message
  SELECT exception
  CASE ERR_LIBRARY ; Vprintf( loc_GetString( ERR_LIBRARY ), [ 'bgui.library', 37 ] )
  CASE "MEM"       ; Vprintf( loc_GetString( ERR_MEMORY ), NIL )
  ENDSELECT
  ->»»>

  ->»» free all resources
  IF ma_object <> NIL THEN END ma_object
  IF bguibase  <> NIL THEN CloseLibrary( bguibase )

  IF localebase <> NIL
    IF glo_catalog <> NIL THEN CloseCatalog( glo_catalog )
    CloseLibrary( localebase )
  ENDIF

  IF glo_screen <> NIL THEN UnlockPubScreen( NIL, glo_screen )
  ->»»>

ENDPROC
->»»>


/* -- ----------------------------------------------------------------- -- *
 * --                               Data                                -- *
 * -- ----------------------------------------------------------------- -- */

lab_Version:
CHAR '$VER: StackWatch 1.2 (30-Jan-99) [ Daniel Kasmeroglu ]',0
