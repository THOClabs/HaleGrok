-------------------------------------------------------------------------------
-- HALE Orbital Mechanics Library - Root Package Body
-------------------------------------------------------------------------------

package body Hale_Orbital
   with SPARK_Mode => Off  --  Body uses string operations
is

   -----------------------------------------------------------------------------
   -- Version
   -----------------------------------------------------------------------------

   function Version return String is
   begin
      return Natural'Image (Version_Major) & "." &
             Natural'Image (Version_Minor) & "." &
             Natural'Image (Version_Patch);
   end Version;

end Hale_Orbital;
