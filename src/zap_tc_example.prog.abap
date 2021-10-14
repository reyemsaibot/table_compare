"#autoformat
**********************************************************************
* Author: T.Meyer, https://www.reyemsaibot.com, 2021-10-14
**********************************************************************
*
* Compare two tables with the same structure and mark the differences
* to display it in an ALV grid for further investigation
*
**********************************************************************
* Change log
**********************************************************************
* 14.10.21 TM initial version
**********************************************************************
REPORT zap_tc_example.

FIELD-SYMBOLS: <lt_table> TYPE STANDARD TABLE.

SELECT * FROM rsdiobj INTO TABLE @DATA(lt_source) WHERE objvers = 'A'.
SELECT * FROM rsdiobj INTO TABLE @DATA(lt_target).

"Example with direct display
TRY.
    NEW zcl_tc( )->compare_tables( it_table_old  = lt_source
                                   it_table_new  = lt_target
                                   iv_display    = rs_c_true ).
  CATCH zcx_tc INTO DATA(lcx_tc).
    MESSAGE lcx_tc->get_text( ) TYPE 'E'.
ENDTRY.

"Example with export table for further processing


TRY.
    NEW zcl_tc( )->compare_tables( EXPORTING it_table_old  = lt_source
                                             it_table_new  = lt_target
                                   IMPORTING et_table      = <lt_table> ).
  CATCH zcx_tc INTO lcx_tc.
    MESSAGE lcx_tc->get_text( ) TYPE 'E'.
ENDTRY.
