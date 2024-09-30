/*********************************************************************************************************************
* Apex Class: SBR_3_0_EmailRepsOfNewAssgnSchedule
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This Schedule class will call SBR_3_0_BatchEmailRepsOfNewAssignments 
* - SF-522
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    2023-04-25             Initial version 
*********************************************************************************************************************/
public class SBR_3_0_EmailRepsOfNewAssgnSchedule implements Schedulable {
	public void execute(SchedulableContext SC) {
    	SBR_3_0_BatchEmailRepsOfNewAssignments BC = new SBR_3_0_BatchEmailRepsOfNewAssignments(); 
      	Database.executeBatch(BC);
   }
}