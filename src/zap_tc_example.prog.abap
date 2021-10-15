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
* 15.10.21 TM Add logic for color column
**********************************************************************
REPORT zap_tc_example.

DATA: lo_table TYPE REF TO data.

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

NEW zcl_tc( )->add_color_column( EXPORTING it_table            = lt_source
                                 IMPORTING eo_table_with_color = DATA(lo_table_with_color) ).

CREATE DATA lo_table TYPE HANDLE lo_table_with_color.
ASSIGN lo_table->* TO <lt_table>.

TRY.
    NEW zcl_tc( )->compare_tables( EXPORTING it_table_old  = lt_source
                                             it_table_new  = lt_target
                                   IMPORTING et_table      = <lt_table> ).
  CATCH zcx_tc INTO lcx_tc.
    MESSAGE lcx_tc->get_text( ) TYPE 'E'.
ENDTRY.

" Do some stuff with the internal table <lt_table>
