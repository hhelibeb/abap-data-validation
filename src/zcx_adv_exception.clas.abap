"! ADV general error
CLASS zcx_adv_exception DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.

    DATA subrc TYPE sysubrc READ-ONLY.
    DATA msgv1 TYPE symsgv READ-ONLY.
    DATA msgv2 TYPE symsgv READ-ONLY.
    DATA msgv3 TYPE symsgv READ-ONLY.
    DATA msgv4 TYPE symsgv READ-ONLY.
    DATA mr_callstack TYPE REF TO if_xco_cp_call_stack READ-ONLY.

    "! Raise exception with text
    "! @parameter iv_text | Text
    "! @parameter ix_previous | Previous exception
    "! @raising zcx_ADV_exception | Exception
    CLASS-METHODS raise
      IMPORTING
        !iv_text     TYPE clike
        !ix_previous TYPE REF TO cx_root OPTIONAL
      RAISING
        zcx_adv_exception.
    "! Raise exception with T100 message
    "! <p>
    "! Will default to sy-msg* variables. These need to be set right before calling this method.
    "! </p>
    "! @parameter iv_msgid | Message ID
    "! @parameter iv_msgno | Message number
    "! @parameter iv_msgv1 | Message variable 1
    "! @parameter iv_msgv2 | Message variable 2
    "! @parameter iv_msgv3 | Message variable 3
    "! @parameter iv_msgv4 | Message variable 4
    "! @raising zcx_ADV_exception | Exception
    CLASS-METHODS raise_t100
      IMPORTING
        VALUE(iv_msgid) TYPE symsgid DEFAULT sy-msgid
        VALUE(iv_msgno) TYPE symsgno DEFAULT sy-msgno
        VALUE(iv_msgv1) TYPE symsgv DEFAULT sy-msgv1
        VALUE(iv_msgv2) TYPE symsgv DEFAULT sy-msgv2
        VALUE(iv_msgv3) TYPE symsgv DEFAULT sy-msgv3
        VALUE(iv_msgv4) TYPE symsgv DEFAULT sy-msgv4
      RAISING
        zcx_adv_exception.
    "! <p class="shorttext synchronized" lang="en"></p>
    "!
    "! @parameter textid | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter previous | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter msgv1 | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter msgv2 | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter msgv3 | <p class="shorttext synchronized" lang="en"></p>
    "! @parameter msgv4 | <p class="shorttext synchronized" lang="en"></p>
    METHODS constructor
      IMPORTING
        !textid   LIKE if_t100_message=>t100key OPTIONAL
        !previous LIKE previous OPTIONAL
        !msgv1    TYPE symsgv OPTIONAL
        !msgv2    TYPE symsgv OPTIONAL
        !msgv3    TYPE symsgv OPTIONAL
        !msgv4    TYPE symsgv OPTIONAL.
    "! <p class="shorttext synchronized" lang="en"></p>
    METHODS get_source_position REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
    CONSTANTS:
      gc_generic_error_msg TYPE string VALUE `An error occured (ZCX_ADV_EXCEPTION)` ##NO_TEXT.

    METHODS:
      save_callstack.

ENDCLASS.



CLASS ZCX_ADV_EXCEPTION IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).

    me->msgv1 = msgv1.
    me->msgv2 = msgv2.
    me->msgv3 = msgv3.
    me->msgv4 = msgv4.

    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.

    save_callstack( ).

  ENDMETHOD.


  METHOD raise.
    DATA: lv_msgv1    TYPE symsgv,
          lv_msgv2    TYPE symsgv,
          lv_msgv3    TYPE symsgv,
          lv_msgv4    TYPE symsgv,
          ls_t100_key TYPE scx_t100key,
          lv_text     TYPE string.

    IF iv_text IS INITIAL.
      lv_text = gc_generic_error_msg.
    ELSE.
      lv_text = iv_text.
    ENDIF.

    TYPES:
      BEGIN OF ty_msg,
        msgv1 TYPE symsgv,
        msgv2 TYPE symsgv,
        msgv3 TYPE symsgv,
        msgv4 TYPE symsgv,
      END OF ty_msg.

    DATA: ls_msg   TYPE ty_msg,
          lv_dummy TYPE string.

    ls_msg = lv_text.

    " &1&2&3&4&5&6&7&8
    MESSAGE e001(zcm_data_validator) WITH ls_msg-msgv1 ls_msg-msgv2 ls_msg-msgv3 ls_msg-msgv4
                     INTO lv_dummy.

    ls_t100_key-msgid = sy-msgid.
    ls_t100_key-msgno = sy-msgno.
    ls_t100_key-attr1 = 'MSGV1'.
    ls_t100_key-attr2 = 'MSGV2'.
    ls_t100_key-attr3 = 'MSGV3'.
    ls_t100_key-attr4 = 'MSGV4'.
    lv_msgv1 = sy-msgv1.
    lv_msgv2 = sy-msgv2.
    lv_msgv3 = sy-msgv3.
    lv_msgv4 = sy-msgv4.

    RAISE EXCEPTION TYPE zcx_adv_exception
      EXPORTING
        textid   = ls_t100_key
        msgv1    = lv_msgv1
        msgv2    = lv_msgv2
        msgv3    = lv_msgv3
        msgv4    = lv_msgv4
        previous = ix_previous.
  ENDMETHOD.


  METHOD raise_t100.
    DATA: ls_t100_key TYPE scx_t100key.

    ls_t100_key-msgid = iv_msgid.
    ls_t100_key-msgno = iv_msgno.
    ls_t100_key-attr1 = 'MSGV1'.
    ls_t100_key-attr2 = 'MSGV2'.
    ls_t100_key-attr3 = 'MSGV3'.
    ls_t100_key-attr4 = 'MSGV4'.

    IF iv_msgid IS INITIAL.
      CLEAR ls_t100_key.
    ENDIF.

    RAISE EXCEPTION TYPE zcx_adv_exception
      EXPORTING
        textid = ls_t100_key
        msgv1  = iv_msgv1
        msgv2  = iv_msgv2
        msgv3  = iv_msgv3
        msgv4  = iv_msgv4.
  ENDMETHOD.


  METHOD save_callstack.

    " You should remember that the first lines are from zcx_ADV_exception
    " and are removed so that highest level in the callstack is the position where
    " the exception is raised.

    "Remove the entries involving ZCX_ADV_EXCEPTION
    mr_callstack = XCO_CP=>CURRENT->call_stack->full( ).
    DATA(lo_line_pattern) = xco_cp_call_stack=>line_pattern->method( )->where_class_name_starts_with( 'ZCX_ADV_' ).
    mr_callstack = mr_callstack->from->last_occurrence_of( lo_line_pattern  ).
    mr_callstack = mr_callstack->from->position( 2 ).


  ENDMETHOD.


  METHOD get_source_position.

    DATA(lr_callstack) = mr_callstack->to->position( 1 ).
    DATA(lr_format) = xco_cp_call_stack=>format->adt( )->with_line_number_flavor( xco_cp_call_stack=>line_number_flavor->source ).
    DATA(lt_callstack_texts) = lr_callstack->as_text( lr_format )->get_lines( )->get( 1 )->split( | | )->value.

    IF lines( lt_callstack_texts ) = 9.
        program_name = lt_callstack_texts[ 1 ].
        include_name = lt_callstack_texts[ 5 ].
        source_line  = lt_callstack_texts[ 9 ].
    ELSE.
      super->get_source_position(
        IMPORTING
          program_name = program_name
          include_name = include_name
          source_line  = source_line   ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
