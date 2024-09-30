/*********************************************************************************************************************
* Apex Class: SBR_3_0_BatchUpdateARSalesRep_Test
---------------------------------------------------------------------------------------------------------------------------------------
* - SF-6742
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                DETAIL FEATURES
    1.0         Manish Taneja                    2024-02-05             Initial version 
*********************************************************************************************************************
/** 
  * @description This is schedule class to execute SBR_3_0_BatchUpdateARSalesRep class
 */
public class SBR_3_0_BatchUpdateARSalesRepSchedule implements Schedulable {
/** 
  * @description execute Method implementation
  * @param ScheuleContext
*/
	public void execute(SchedulableContext scheduleCon) {
    	SBR_3_0_BatchUpdateARSalesRep batchCon = new SBR_3_0_BatchUpdateARSalesRep(); 
      	Database.executeBatch(batchCon);
   }
}