"#autoformat
class ZCL_TC definition
  public
  final
  create public .

public section.

  types:
    ty_t_fields TYPE STANDARD TABLE OF name_komp WITH EMPTY KEY .

    "! <p class="shorttext synchronized" lang="en"></p>
    "!
    "! @parameter it_table_old | <p class="shorttext synchronized" lang="en">Old Table or Source Table</p>
    "! @parameter it_table_new | <p class="shorttext synchronized" lang="en">New Table or Target Table</p>
    "! @parameter it_key_fields | <p class="shorttext synchronized" lang="en">List of key fields (&lt;strong&gt;optional&lt;/strong&gt;</p>
    "! @parameter iv_display | <p class="shorttext synchronized" lang="en">Display data in ALV grid (default: &lt;strong&gt;false&lt;/strong&gt;)</p>
    "! @parameter et_table | <p class="shorttext synchronized" lang="en">Table with color column</p>
    "! @raising zcx_tc | <p class="shorttext synchronized" lang="en">Raise Exception</p>
  methods COMPARE_TABLES
    importing
      !IT_TABLE_OLD type STANDARD TABLE
      !IT_TABLE_NEW type STANDARD TABLE
      !IT_KEY_FIELDS type TY_T_FIELDS optional
      !IV_DISPLAY type RS_BOOL default RS_C_FALSE
    exporting
      !ET_TABLE type STANDARD TABLE
    raising
      ZCX_TC .
    "! <p class="shorttext synchronized" lang="en"></p>
    "!
    "! @parameter it_key_fields | <p class="shorttext synchronized" lang="en">Save table of key fields</p>
  methods SET_KEY_FIELDS
    importing
      !IT_KEY_FIELDS type TY_T_FIELDS .
    "! <p class="shorttext synchronized" lang="en"></p>
    "!
    "! @parameter rt_key_fields | <p class="shorttext synchronized" lang="en">Get table of key fields</p>
  methods GET_KEY_FIELDS
    returning
      value(RT_KEY_FIELDS) type TY_T_FIELDS .
    "! <p class="shorttext synchronized" lang="en"></p>
    "!
    "! @parameter it_table | <p class="shorttext synchronized" lang="en">Table to expand</p>
    "! @parameter eo_table_with_color | <p class="shorttext synchronized" lang="en">Import table with new column color</p>
    "! @parameter eo_structure_with_color | <p class="shorttext synchronized" lang="en">Structure with new column color</p>
  methods ADD_COLOR_COLUMN
    importing
      !IT_TABLE type ANY TABLE
    exporting
      !EO_TABLE_WITH_COLOR type ref to CL_ABAP_TABLEDESCR
      !EO_STRUCTURE_WITH_COLOR type ref to CL_ABAP_STRUCTDESCR .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA: mt_key_fields TYPE TABLE OF name_komp.

    METHODS get_sort_order
      RETURNING
        VALUE(rt_sort_order) TYPE abap_sortorder_tab.

    METHODS _create_compare_table
      IMPORTING
        it_table_old TYPE STANDARD TABLE
        it_table_new TYPE STANDARD TABLE
      EXPORTING
        et_table     TYPE STANDARD TABLE
      RAISING
        zcx_tc.

    METHODS _set_color
      CHANGING
        cs_data_compare TYPE any
      RAISING
        zcx_tc.

    METHODS _display
      IMPORTING
        it_table TYPE STANDARD TABLE.

ENDCLASS.



CLASS ZCL_TC IMPLEMENTATION.


  METHOD add_color_column.
    TYPES: BEGIN OF ty_color,
             color TYPE lvc_t_scol,
           END OF ty_color.

    DATA: ls_color TYPE ty_color.
    DATA: lo_table TYPE REF TO cl_abap_tabledescr.
    DATA: lo_strucdescr TYPE REF TO cl_abap_structdescr.

    lo_table ?= cl_abap_typedescr=>describe_by_data( it_table ).
    lo_strucdescr ?= lo_table->get_table_line_type( ).

    " Get all fields of structure
    DATA(lt_components) = lo_strucdescr->get_components( ).

    " Get color column and append it to the other fields
    lo_strucdescr ?= cl_abap_typedescr=>describe_by_data( ls_color ).
    APPEND LINES OF lo_strucdescr->get_components( ) TO lt_components.

    " Create a new structure with the new component table
    TRY.
        eo_structure_with_color = cl_abap_structdescr=>create( lt_components ).
      CATCH cx_sy_struct_creation INTO DATA(lcx_structure).
        MESSAGE lcx_structure->get_text( ) TYPE 'E'.
    ENDTRY.

    " Create new table with color column
    TRY.
        eo_table_with_color = cl_abap_tabledescr=>create( eo_structure_with_color ).
      CATCH cx_sy_table_creation INTO DATA(lcx_table).
        MESSAGE lcx_table->get_text( ) TYPE 'E'.
    ENDTRY.

  ENDMETHOD.


  METHOD compare_tables.
    DATA: ls_cx_exception TYPE scx_t100key.
    DATA: lo_structure TYPE REF TO cl_abap_structdescr.
    DATA: lo_table TYPE REF TO cl_abap_tabledescr.
    DATA: lt_key_fields_range TYPE RANGE OF name_komp.

    DATA: lo_t_data_old TYPE REF TO data.
    DATA: lo_t_data_new TYPE REF TO data.

    DATA: lo_t_data_compare TYPE REF TO data.
    DATA: lo_s_compare TYPE REF TO data.

    FIELD-SYMBOLS: <lt_t_data_old> TYPE STANDARD TABLE.
    FIELD-SYMBOLS: <lt_t_data_new> TYPE STANDARD TABLE.
    FIELD-SYMBOLS: <lt_t_data_compare> TYPE STANDARD TABLE.

    FIELD-SYMBOLS: <lt_data_compare_with_color> TYPE STANDARD TABLE.
    FIELD-SYMBOLS: <ls_data_compare_with_color> TYPE any.

    lo_table ?= cl_abap_typedescr=>describe_by_data( it_table_new ).
    lo_structure ?= lo_table->get_table_line_type( ).
    DATA(lt_fieldlist) = lo_structure->get_ddic_field_list( ).

    IF it_key_fields[] IS NOT INITIAL.
      DATA(lt_key_fields) = it_key_fields.
    ELSE.
      " Get a list of key fields from the list of all fields
      lt_key_fields = VALUE ty_t_fields( FOR <ls_fields> IN lt_fieldlist WHERE ( keyflag = rs_c_true ) ( <ls_fields>-fieldname ) ).
    ENDIF.

    set_key_fields( lt_key_fields ).

    " Get the key components
    DATA(lt_components) = lo_structure->get_components( ).
    DATA(lt_key_components) = lt_components.

    " Build range table for key field
    lt_key_fields_range = VALUE #( FOR <ls_key_fields> IN lt_key_fields ( low = <ls_key_fields> sign = 'I' option = 'EQ') ).
    DELETE lt_key_components WHERE NOT name IN lt_key_fields_range.
    DELETE lt_components WHERE name IN lt_key_fields_range.

    " Create an internal table with all fields with another field which points to the key fields.
    TRY.
        DATA(lo_key_fields_structure) = cl_abap_structdescr=>create( lt_key_components ).
        INSERT INITIAL LINE INTO lt_components ASSIGNING FIELD-SYMBOL(<ls_components>) INDEX 1.
        <ls_components>-name = 'KEY'.
        <ls_components>-as_include = rs_c_true.
        <ls_components>-type = lo_key_fields_structure.
        DATA(lo_table_data_structure) = cl_abap_structdescr=>create( lt_components ).
        DATA(lo_table_data_table) = cl_abap_tabledescr=>create( lo_table_data_structure ).
      CATCH cx_sy_struct_creation INTO DATA(lcx_creation).
        MESSAGE lcx_creation->get_text( ) TYPE 'E'.
    ENDTRY.

    " Build internal table which has the key field record to comapre
    CREATE DATA lo_t_data_compare TYPE HANDLE lo_table_data_table.
    ASSIGN lo_t_data_compare->* TO <lt_t_data_compare>.
    IF sy-subrc <> 0.
      ls_cx_exception-msgid = 'ZMC_TC'.
      ls_cx_exception-msgno = '002'.
      ls_cx_exception-attr1 = |lo_t_data_compare|.
      ls_cx_exception-attr2 = |COMPARE_TABLES|.
      DATA(lo_exception) = NEW zcx_tc( textid = ls_cx_exception ).
      RAISE EXCEPTION lo_exception.
    ENDIF.


    " Build internal table new with key field
    CREATE DATA lo_t_data_new TYPE HANDLE lo_table_data_table.
    ASSIGN lo_t_data_new->* TO <lt_t_data_new>.
    IF sy-subrc <> 0.
      ls_cx_exception-msgid = 'ZMC_TC'.
      ls_cx_exception-msgno = '002'.
      ls_cx_exception-attr1 = |lo_t_data_new|.
      ls_cx_exception-attr2 = |COMPARE_TABLES|.
      lo_exception = NEW zcx_tc( textid = ls_cx_exception ).
      RAISE EXCEPTION lo_exception.
    ENDIF.

    " Build internal table old with key field
    CREATE DATA lo_t_data_old TYPE HANDLE lo_table_data_table.
    ASSIGN lo_t_data_old->* TO <lt_t_data_old>.
    IF sy-subrc <> 0.
      ls_cx_exception-msgid = 'ZMC_TC'.
      ls_cx_exception-msgno = '002'.
      ls_cx_exception-attr1 = |lo_t_data_old|.
      ls_cx_exception-attr2 = |COMPARE_TABLES|.
      lo_exception = NEW zcx_tc( textid = ls_cx_exception ).
      RAISE EXCEPTION lo_exception.
    ENDIF.

    " Create compare table
    TRY.
        _create_compare_table( EXPORTING it_table_old = it_table_old
                                         it_table_new = it_table_new
                               IMPORTING et_table     = <lt_t_data_compare> ).
      CATCH zcx_tc INTO DATA(lcx_tc).
        MESSAGE lcx_tc->get_text( ) TYPE 'E'.
    ENDTRY.

    " Add color column to compare table
    add_color_column( EXPORTING it_table                = <lt_t_data_compare>
                      IMPORTING eo_table_with_color     = DATA(lo_table_compare_with_color)
                                eo_structure_with_color = DATA(lo_s_compare_with_color) ).

    " Build new compare table with key and color column
    CREATE DATA lo_t_data_compare TYPE HANDLE lo_table_compare_with_color.
    ASSIGN lo_t_data_compare->* TO <lt_data_compare_with_color>.
    IF sy-subrc <> 0.
      ls_cx_exception-msgid = 'ZMC_TC'.
      ls_cx_exception-msgno = '002'.
      ls_cx_exception-attr1 = |lo_t_data_compare|.
      ls_cx_exception-attr2 = |COMPARE_TABLES|.
      lo_exception = NEW zcx_tc( textid = ls_cx_exception ).
      RAISE EXCEPTION lo_exception.
    ENDIF.

    CREATE DATA lo_s_compare TYPE HANDLE lo_s_compare_with_color.
    ASSIGN lo_s_compare->* TO <ls_data_compare_with_color>.
    IF sy-subrc <> 0.
      ls_cx_exception-msgid = 'ZMC_TC'.
      ls_cx_exception-msgno = '002'.
      ls_cx_exception-attr1 = |lo_s_compare|.
      ls_cx_exception-attr2 = |COMPARE_TABLES|.
      lo_exception = NEW zcx_tc( textid = ls_cx_exception ).
      RAISE EXCEPTION lo_exception.
    ENDIF.

    "Append lines of old/new table to field symbol
    APPEND LINES OF it_table_old TO <lt_t_data_old>.
    APPEND LINES OF it_table_new TO <lt_t_data_new>.

    " Loop over comparing table and check entries
    LOOP AT <lt_t_data_compare> ASSIGNING FIELD-SYMBOL(<ls_compare>).

      " Fill line of compare with color column
      <ls_data_compare_with_color> = CORRESPONDING #( <ls_compare> ).

      ASSIGN COMPONENT 'KEY' OF STRUCTURE <ls_compare> TO FIELD-SYMBOL(<ls_key_value>).
      IF sy-subrc <> 0.
        ls_cx_exception-msgid = 'ZMC_TC'.
        ls_cx_exception-msgno = '003'.
        ls_cx_exception-attr1 = |KEY|.
        ls_cx_exception-attr2 = |<ls_compare>|.
        ls_cx_exception-attr3 = |COMPARE_TABLES|.
        lo_exception = NEW zcx_tc( textid = ls_cx_exception ).
        RAISE EXCEPTION lo_exception.
      ENDIF.

      IF NOT line_exists( <lt_t_data_old>[ ('KEY') = <ls_key_value> ] ).
        TRY.
            _set_color( CHANGING cs_data_compare = <ls_data_compare_with_color> ).
          CATCH zcx_tc INTO DATA(lcx_exception).
            MESSAGE lcx_exception->get_text( ) TYPE 'E'.
        ENDTRY.
      ENDIF.

      IF NOT line_exists( <lt_t_data_new>[ ('KEY') = <ls_key_value> ] ).
        TRY.
            _set_color( CHANGING cs_data_compare = <ls_data_compare_with_color> ).
          CATCH zcx_tc INTO lcx_exception.
            MESSAGE lcx_exception->get_text( ) TYPE 'E'.
        ENDTRY.
      ENDIF.

      APPEND <ls_data_compare_with_color> TO <lt_data_compare_with_color>.

    ENDLOOP.

    IF iv_display = rs_c_true.
      _display( <lt_data_compare_with_color> ).
    ELSE.
      APPEND LINES OF <lt_data_compare_with_color> TO et_table.
    ENDIF.

  ENDMETHOD.


  METHOD get_key_fields.
    rt_key_fields = me->mt_key_fields.
  ENDMETHOD.


  METHOD get_sort_order.
    rt_sort_order = VALUE #( FOR <ls_fields> IN get_key_fields( ) ( name = <ls_fields> ) ).
  ENDMETHOD.


  METHOD set_key_fields.
    me->mt_key_fields = it_key_fields.
  ENDMETHOD.


  METHOD _create_compare_table.
    DATA: ls_cx_exception TYPE scx_t100key.
    DATA: lr_tabledescr TYPE REF TO cl_abap_tabledescr.
    DATA: lr_table TYPE REF TO data.
    DATA: lr_table_old TYPE REF TO data.
    DATA: lr_table_new TYPE REF TO data.
    FIELD-SYMBOLS: <lt_table> TYPE STANDARD TABLE.

    lr_tabledescr ?= cl_abap_tabledescr=>describe_by_data( p_data = it_table_old ).

    CREATE DATA lr_table TYPE HANDLE lr_tabledescr.
    CREATE DATA lr_table_old TYPE HANDLE lr_tabledescr.
    CREATE DATA lr_table_new TYPE HANDLE lr_tabledescr.

    " Assign compare table
    ASSIGN lr_table->* TO <lt_table>.
    IF sy-subrc <> 0.
      ls_cx_exception-msgid = 'ZMC_TC'.
      ls_cx_exception-msgno = '002'.
      ls_cx_exception-attr1 = |lr_table|.
      ls_cx_exception-attr2 = |_create_compare_table|.
      DATA(lo_exception) = NEW zcx_tc( textid = ls_cx_exception ).
      RAISE EXCEPTION lo_exception.
      RETURN.
    ENDIF.

    " Assign old table
    ASSIGN lr_table_old->* TO FIELD-SYMBOL(<lt_table_old>).
    IF sy-subrc <> 0.
      ls_cx_exception-msgid = 'ZMC_TC'.
      ls_cx_exception-msgno = '002'.
      ls_cx_exception-attr1 = |lr_table_old|.
      ls_cx_exception-attr2 = |_create_compare_table|.
      lo_exception = NEW zcx_tc( textid = ls_cx_exception ).
      RAISE EXCEPTION lo_exception.
      RETURN.
    ENDIF.

    " Assign new table
    ASSIGN lr_table_new->* TO FIELD-SYMBOL(<lt_table_new>).
    IF sy-subrc <> 0.
      ls_cx_exception-msgid = 'ZMC_TC'.
      ls_cx_exception-msgno = '002'.
      ls_cx_exception-attr1 = |lr_table_new|.
      ls_cx_exception-attr2 = |_create_compare_table|.
      lo_exception = NEW zcx_tc( textid = ls_cx_exception ).
      RAISE EXCEPTION lo_exception.
      RETURN.
    ENDIF.

    APPEND LINES OF it_table_old TO <lt_table>.
    APPEND LINES OF it_table_new TO <lt_table>.

    DATA(lt_sort_order) = get_sort_order( ).
    SORT <lt_table> BY (lt_sort_order).

    DELETE ADJACENT DUPLICATES FROM <lt_table> COMPARING ALL FIELDS.
    APPEND LINES OF <lt_table> TO et_table.

  ENDMETHOD.


  METHOD _display.
    DATA: lr_tabledescr TYPE REF TO cl_abap_tabledescr.
    DATA: lr_compare TYPE REF TO data.
    DATA: lo_grid TYPE REF TO cl_salv_table.
    FIELD-SYMBOLS: <lt_table> TYPE STANDARD TABLE.

    lr_tabledescr ?= cl_abap_tabledescr=>describe_by_data( it_table ).

    CREATE DATA lr_compare TYPE HANDLE lr_tabledescr.
    ASSIGN lr_compare->* TO <lt_table>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    APPEND LINES OF it_table TO <lt_table>.

    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table   = lo_grid
                                CHANGING  t_table        = <lt_table> ).
      CATCH cx_salv_msg.
    ENDTRY.
    TRY.
        lo_grid->get_columns( )->set_color_column( 'COLOR' ).
      CATCH cx_salv_data_error.
    ENDTRY.

    lo_grid->get_display_settings( )->set_striped_pattern( abap_true ).
    lo_grid->get_columns( )->set_optimize( rs_c_true ).
    lo_grid->get_functions( )->set_all( rs_c_true ).
    lo_grid->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>single ).
    lo_grid->display( ).

  ENDMETHOD.


  METHOD _set_color.
    DATA: lo_color TYPE REF TO data.
    DATA: ls_cx_exception TYPE scx_t100key.
    FIELD-SYMBOLS: <lt_color> TYPE STANDARD TABLE.

    " Get key fields to identify unique record
    LOOP AT get_key_fields( ) REFERENCE INTO DATA(ls_key_field).
      ASSIGN COMPONENT sy-index OF STRUCTURE ls_key_field->* TO FIELD-SYMBOL(<lv_key_field>).
      IF sy-subrc <> 0.
        ls_cx_exception-msgid = 'ZMC_TC'.
        ls_cx_exception-msgno = '003'.
        ls_cx_exception-attr1 = |sy-index|.
        ls_cx_exception-attr2 = |ls_key_field|.
        ls_cx_exception-attr3 = |_set_color|.
        DATA(lo_exception) = NEW zcx_tc( textid = ls_cx_exception ).
        RAISE EXCEPTION lo_exception.
      ENDIF.

      ASSIGN COMPONENT 'COLOR' OF STRUCTURE cs_data_compare TO <lt_color>.
      IF sy-subrc <> 0.
        ls_cx_exception-msgid = 'ZMC_TC'.
        ls_cx_exception-msgno = '003'.
        ls_cx_exception-attr1 = |COLOR|.
        ls_cx_exception-attr2 = |cs_data_compare|.
        ls_cx_exception-attr3 = |_set_color|.
        lo_exception = NEW zcx_tc( textid = ls_cx_exception ).
        RAISE EXCEPTION lo_exception.
      ENDIF.

      CREATE DATA lo_color LIKE LINE OF <lt_color>.
      ASSIGN lo_color->* TO FIELD-SYMBOL(<ls_color>).
      IF sy-subrc <> 0.
        ls_cx_exception-msgid = 'ZMC_TC'.
        ls_cx_exception-msgno = '002'.
        ls_cx_exception-attr1 = |lo_color|.
        ls_cx_exception-attr2 = |_set_color|.
        lo_exception = NEW zcx_tc( textid = ls_cx_exception ).
        RAISE EXCEPTION lo_exception.
      ENDIF.

      "Fieldname which will be marked
      ASSIGN COMPONENT 'FNAME' OF STRUCTURE <ls_color> TO FIELD-SYMBOL(<lv_fieldname>).
      IF sy-subrc <> 0.
        ls_cx_exception-msgid = 'ZMC_TC'.
        ls_cx_exception-msgno = '003'.
        ls_cx_exception-attr1 = |FNAME|.
        ls_cx_exception-attr2 = |<ls_color>|.
        ls_cx_exception-attr3 = |_set_color|.
        lo_exception = NEW zcx_tc( textid = ls_cx_exception ).
        RAISE EXCEPTION lo_exception.
      ENDIF.
      <lv_fieldname> = <lv_key_field>.

      ASSIGN COMPONENT 'COLOR' OF STRUCTURE <ls_color> TO FIELD-SYMBOL(<ls_color_column>).
      IF sy-subrc <> 0.
        ls_cx_exception-msgid = 'ZMC_TC'.
        ls_cx_exception-msgno = '003'.
        ls_cx_exception-attr1 = |COLOR|.
        ls_cx_exception-attr2 = |<ls_color>|.
        ls_cx_exception-attr3 = |_set_color|.
        lo_exception = NEW zcx_tc( textid = ls_cx_exception ).
        RAISE EXCEPTION lo_exception.
      ENDIF.

      ASSIGN COMPONENT 'COL' OF STRUCTURE <ls_color_column> TO FIELD-SYMBOL(<lv_color>).
      IF sy-subrc <> 0.
        ls_cx_exception-msgid = 'ZMC_TC'.
        ls_cx_exception-msgno = '003'.
        ls_cx_exception-attr1 = |COL|.
        ls_cx_exception-attr2 = |<ls_color_column>|.
        ls_cx_exception-attr3 = |_set_color|.
        lo_exception = NEW zcx_tc( textid = ls_cx_exception ).
        RAISE EXCEPTION lo_exception.
      ENDIF.

      "Set Color to red
      <lv_color> = 6.
      APPEND <ls_color> TO <lt_color>.

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
