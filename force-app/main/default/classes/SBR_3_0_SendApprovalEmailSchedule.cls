/*********************************************************************************************************************
* Apex Class: SBR_3_0_SendApprovalEmailSchedule
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This Schedule class will call SBR_3_0_SendApprovalEmailBatch 
* - SF-5857
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    2023-12-07             Initial version 
*********************************************************************************************************************/
public class SBR_3_0_SendApprovalEmailSchedule implements Schedulable {
	public void execute(SchedulableContext SC) {
    	SBR_3_0_SendApprovalEmailBatch BC = new SBR_3_0_SendApprovalEmailBatch(); 
      	Database.executeBatch(BC);
   }
}