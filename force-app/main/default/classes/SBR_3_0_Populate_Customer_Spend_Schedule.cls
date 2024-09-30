/*********************************************************************************************************************
* Apex Class: SBR_3_0_Populate_Customer_Spend_Schedule
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This Schedule class will call SBR_3_0_Batch_Populate_Customer_Spend 
* - SF-169
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    2023-05-03             Initial version 
*********************************************************************************************************************/
public class SBR_3_0_Populate_Customer_Spend_Schedule implements Schedulable{
	public void execute(SchedulableContext SC) {
    	SBR_3_0_Batch_Populate_Customer_Spend BC = new SBR_3_0_Batch_Populate_Customer_Spend(); 
      	Database.executeBatch(BC);
   }
}