"#autoformat
CLASS zcx_tc DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_t100_dyn_msg.
    INTERFACES if_t100_message.

    DATA: mv_assign_value TYPE string.
    DATA: mv_method TYPE string.
    DATA: mv_structure TYPE string.

    CONSTANTS:
      BEGIN OF zcx_tc,
        msgid TYPE symsgid VALUE 'ZMC_TC',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF zcx_tc.

    CONSTANTS:
      BEGIN OF assign_value,
        msgid TYPE symsgid VALUE 'ZMC_TC',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE 'MV_ASSIGN_VALUE',
        attr2 TYPE scx_attrname VALUE 'MV_METHOD',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF assign_value.

    CONSTANTS:
      BEGIN OF assign_value_structure,
        msgid TYPE symsgid VALUE 'ZMC_TC',
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE 'MV_ASSIGN_VALUE',
        attr2 TYPE scx_attrname VALUE 'MV_STRUCTURE',
        attr3 TYPE scx_attrname VALUE 'MV_METHOD',
        attr4 TYPE scx_attrname VALUE '',
      END OF assign_value_structure.


    METHODS constructor
      IMPORTING
        !textid       LIKE if_t100_message=>t100key OPTIONAL
        !previous     LIKE previous OPTIONAL
        !assign_value TYPE string OPTIONAL
        !structure    TYPE string OPTIONAL
        !method       TYPE string OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcx_tc IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
    me->mv_assign_value  = assign_value.
    me->mv_method = method.
    me->mv_structure = structure.

  ENDMETHOD.
ENDCLASS.
