.key COMPILE/S,COPY/S,RUN/S,DEBUG/S,REG5/S

IF <REG5>
  setenv reg5 "REG=5"
ELSE
  setenv reg5 "REG=0"
ENDIF

IF <COPY>
  copy sta_#?.e $edestination/StackWatch/ QUIET
ENDIF

IF <COMPILE>
  $ecompiler sta_Localisation IGNORECACHE $reg5 QUIET
  $ecompiler sta_MainGUI      IGNORECACHE $reg5 <DEBUG> QUIET
  $ecompiler sta_Runner       IGNORECACHE $reg5 <DEBUG> QUIET
ENDIF

IF <RUN>
  IF EXISTS sta_Runner
    IF <DEBUG>
      $edebugger sta_Runner
    ELSE
      sta_Runner CX_POPUP
    ENDIF
  ENDIF
ENDIF
