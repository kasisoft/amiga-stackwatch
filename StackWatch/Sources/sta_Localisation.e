/* -- ----------------------------------------------------------------- -- *
 * -- Program.....: sta_Localisation.e                                  -- *
 * -- Author......: Daniel Kasmeroglu <raptor@cs.tu-berlin.de>          -- *
 * -- Description.: Localisation for StackWatch                         -- *
 * -- Version.....: 1.2 (30.01.1999) Minor changings                    -- *
 * -- ----------------------------------------------------------------- -- */

/* -- ----------------------------------------------------------------- -- *
 * --                              Options                              -- *
 * -- ----------------------------------------------------------------- -- */

OPT PREPROCESS       -> enable preprocessor
OPT MODULE           -> generate module


/* -- ----------------------------------------------------------------- -- *
 * --                              Modules                              -- *
 * -- ----------------------------------------------------------------- -- */

MODULE 'lib/locale'


/* -- ----------------------------------------------------------------- -- *
 * --                             Constants                             -- *
 * -- ----------------------------------------------------------------- -- */

->»» ERR_??? [ 0..9 | 10 ]
EXPORT ENUM ERR_OKAY     ,
            ERR_OS       ,
            ERR_MEMORY   ,
            ERR_LIBRARY  ,
            ERR_LIBWARN
->»»>

->»» GLO_??? [ 10..29 | 20 ]
EXPORT ENUM GLO_SCREENTITLE = 10 ,
            GLO_TITLE            ,
            GLO_INFOFORMAT       ,
            GLO_SELFORMAT        ,
            GLO_ABOUT            ,
            GLO_ANSWER           ,
            GLO_BODY             ,
            GLO_COMMNAME         ,
            GLO_COMMTITLE        ,
            GLO_COMMDESC
->»»>

->»» MAIN_??? [ 30..39 | 10 ]
EXPORT ENUM MAIN_ABOUT = 30 ,
            MAIN_REFRESH    ,
            MAIN_STOP
->»»>

->»» TTI_??? [ 40..49 | 10 ]
EXPORT ENUM TTI_MAIN_GAUGE = 40 ,
            TTI_MAIN_INFO       ,
            TTI_MAIN_LIST       ,
            TTI_MAIN_ABOUT      ,
            TTI_MAIN_REFRESH    ,
            TTI_MAIN_STOP       ,
            TTI_MAIN_SELECTED
->»»>

->»» MSG_??? [ 50..59 | 10 ]
EXPORT ENUM MSG_OVERFLOW = 50 ,
            MSG_TASKFINISHED
->»»>

->»» MENU_??? [ 60..69 | 10 ]
EXPORT ENUM MENU_HIDE = 60  ,
            MENU_ABOUT      ,
            MENU_QUIT       ,
            MENU_HIDESHORT  ,
            MENU_ABOUTSHORT ,
            MENU_QUITSHORT  ,
            MENU_TITLE
->»»>


/* -- ----------------------------------------------------------------- -- *
 * --                           Declarations                            -- *
 * -- ----------------------------------------------------------------- -- */

EXPORT DEF glo_catalog


/* -- ----------------------------------------------------------------- -- *
 * --                              Macros                               -- *
 * -- ----------------------------------------------------------------- -- */

->»» LIST OF MACROS
#define ERR_OS_STR                 'You need at least Amiga OS 2.0 or higher !'
#define ERR_MEMORY_STR             'Not enough memory available !'
#define ERR_LIBRARY_STR            'Library "\s" v\d+ is needed to run !'
#define ERR_LIBWARN_STR            'Library "\s" v\d+ could be used !'

#define GLO_SCREENTITLE_STR        'StackWatch 1.0 (c) Daniel Kasmeroglu (1998)'
#define GLO_TITLE_STR              'StackWatch'
#define GLO_INFOFORMAT_STR         'Current: \r\d[6]\sStack: \r\d[8]\nLargest: \r\d[6]'
#define GLO_SELFORMAT_STR          'Monitoring: \eb\s\en'
#define GLO_ABOUT_STR              'About the author'
#define GLO_ANSWER_STR             '_Ok'
#define GLO_BODY_STR               '\ec\ebStackWatch 1.0 (1998)\en\n\ebWritten by\en\n\ebDaniel Kasmeroglu\en\n\ed3Based on StackMon by David Kinder'

#define GLO_COMMNAME_STR           'StackWatch'
#define GLO_COMMTITLE_STR          'StackWatch 1.0'
#define GLO_COMMDESC_STR           'Monitors stack usage of a task'

#define MAIN_ABOUT_STR             '_About'
#define MAIN_REFRESH_STR           '_Refresh'
#define MAIN_STOP_STR              '_Stop'

#define TTI_MAIN_GAUGE_STR         'Shows how much stack is currently used !'
#define TTI_MAIN_INFO_STR          'Some data you can need !'
#define TTI_MAIN_LIST_STR          'This list contains all tasks !'
#define TTI_MAIN_ABOUT_STR         'Some infos about this app !'
#define TTI_MAIN_REFRESH_STR       'Refreshs the whole list !'
#define TTI_MAIN_STOP_STR          'Stops monitoring of a task !'
#define TTI_MAIN_SELECTED_STR      'Shows the current selected task !'

#define MSG_OVERFLOW_STR           'Stack overflow !'
#define MSG_TASKFINISHED_STR       'Task has finished !'

#define MENU_HIDE_STR              'Hide'
#define MENU_ABOUT_STR             'About'
#define MENU_QUIT_STR              'Quit'
#define MENU_HIDESHORT_STR         'H'
#define MENU_ABOUTSHORT_STR        'A'
#define MENU_QUITSHORT_STR         'Q'
#define MENU_TITLE_STR             'Project'
->»»>


/* -- ----------------------------------------------------------------- -- *
 * --                            Procedures                             -- *
 * -- ----------------------------------------------------------------- -- */

->»» PUBLIC loc_GetString
EXPORT PROC loc_GetString( get_id )
DEF get_builtin

  SELECT get_id
  CASE ERR_OS                 ; get_builtin := ERR_OS_STR
  CASE ERR_MEMORY             ; get_builtin := ERR_MEMORY_STR
  CASE ERR_LIBRARY            ; get_builtin := ERR_LIBRARY_STR
  CASE ERR_LIBWARN            ; get_builtin := ERR_LIBWARN_STR

  CASE GLO_SCREENTITLE        ; get_builtin := GLO_SCREENTITLE_STR
  CASE GLO_TITLE              ; get_builtin := GLO_TITLE_STR
  CASE GLO_INFOFORMAT         ; get_builtin := GLO_INFOFORMAT_STR
  CASE GLO_SELFORMAT          ; get_builtin := GLO_SELFORMAT_STR
  CASE GLO_ABOUT              ; get_builtin := GLO_ABOUT_STR
  CASE GLO_ANSWER             ; get_builtin := GLO_ANSWER_STR
  CASE GLO_BODY               ; get_builtin := GLO_BODY_STR
  CASE GLO_COMMNAME           ; get_builtin := GLO_COMMNAME_STR
  CASE GLO_COMMTITLE          ; get_builtin := GLO_COMMTITLE_STR
  CASE GLO_COMMDESC           ; get_builtin := GLO_COMMDESC_STR

  CASE MAIN_ABOUT             ; get_builtin := MAIN_ABOUT_STR
  CASE MAIN_REFRESH           ; get_builtin := MAIN_REFRESH_STR
  CASE MAIN_STOP              ; get_builtin := MAIN_STOP_STR

  CASE TTI_MAIN_GAUGE         ; get_builtin := TTI_MAIN_GAUGE_STR
  CASE TTI_MAIN_INFO          ; get_builtin := TTI_MAIN_INFO_STR
  CASE TTI_MAIN_LIST          ; get_builtin := TTI_MAIN_LIST_STR
  CASE TTI_MAIN_ABOUT         ; get_builtin := TTI_MAIN_ABOUT_STR
  CASE TTI_MAIN_REFRESH       ; get_builtin := TTI_MAIN_REFRESH_STR
  CASE TTI_MAIN_STOP          ; get_builtin := TTI_MAIN_STOP_STR
  CASE TTI_MAIN_SELECTED      ; get_builtin := TTI_MAIN_SELECTED_STR

  CASE MSG_OVERFLOW           ; get_builtin := MSG_OVERFLOW_STR
  CASE MSG_TASKFINISHED       ; get_builtin := MSG_TASKFINISHED_STR

  CASE MENU_HIDE              ; get_builtin := MENU_HIDE_STR
  CASE MENU_ABOUT             ; get_builtin := MENU_ABOUT_STR
  CASE MENU_QUIT              ; get_builtin := MENU_QUIT_STR
  CASE MENU_HIDESHORT         ; get_builtin := MENU_HIDESHORT_STR
  CASE MENU_ABOUTSHORT        ; get_builtin := MENU_ABOUTSHORT_STR
  CASE MENU_QUITSHORT         ; get_builtin := MENU_QUITSHORT_STR
  CASE MENU_TITLE             ; get_builtin := MENU_TITLE_STR
  ENDSELECT

  IF (localebase <> NIL) AND (glo_catalog <> NIL) THEN RETURN GetCatalogStr( glo_catalog, get_id, get_builtin )

ENDPROC get_builtin
->»»>
