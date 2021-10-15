![](https://img.shields.io/badge/ABAP-v7.5%20SP16-orange) [![abaplint](https://github.com/reyemsaibot/table_compare/workflows/abaplint/badge.svg)](https://github.com/reyemsaibot/table_compare/actions) [![Updated Badge](https://badges.pufler.dev/updated/reyemsaibot/table_compare)](https://badges.pufler.dev) [![Created Badge](https://badges.pufler.dev/created/reyemsaibot/table_compare)](https://badges.pufler.dev) 

# Table Compare 
Compare two tables and display different entries

## Example

The example program select in the source table infoobjects from the table rsdiobj which are active in the system. The target table select all infoobjects from the table rsdiobj. The comparison class creates an internal table with a color column to display the color in an ALV grid.

As you see in the below, the source table has all active records and the target table has active, modified and delivered records. The result is that all delivered and modified records are displayed in red because they do not appear in the source table.

Per default the key fields of the table will be choosen to compare the data. But you can add own key fields you want to consider. Just fill the paramter it_key_fields. 

You can display the data directly in an ALV grid (default: false) or export it and use it in your logic for further analysis.

## Usage
The method `compare_tables` has the following parameter:
 - it_table_old 
 - it_table_new
 - it_key_fields
 - iv_display
 - et_table

```abap
SELECT * FROM rsdiobj INTO TABLE @DATA(lt_source) WHERE objvers = 'A'.
SELECT * FROM rsdiobj INTO TABLE @DATA(lt_target).

NEW zcl_compare_tables( )->compare_tables( it_table_old = `your_source_table`
  it_table_new = `your_target_table`
  iv_display   = rs_c_true ).
```
                                                                
This is the result of an ALV grid
![image](https://user-images.githubusercontent.com/6608522/137296239-36176d64-1c4c-4978-915b-f4d8beff511d.png)

## Issue
If you find one or something isn't working, just open an issue.
