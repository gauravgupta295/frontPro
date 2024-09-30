/*********************************************************************************************************************
* Apex Class: SBR_3_0_ARSortOrderCalculationSchedule
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - This Schedule class will call SBR_3_0_BatchARSortOrderCalculation 
* - SF-165
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi                    2023-04-25             Initial version 
*********************************************************************************************************************/
public class SBR_3_0_ARSortOrderCalculationSchedule implements Schedulable {
	public void execute(SchedulableContext SC) {
    	SBR_3_0_BatchARSortOrderCalculation BC = new SBR_3_0_BatchARSortOrderCalculation(); 
      	Database.executeBatch(BC);
   }
}