/*********************************************************************************************************************
* Apex Class: SBR_3_0_ScheduleAddPriceBookEntries
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to add Price Book Entries Periodically via SBR_3_0_BatchAddPriceBookEntries

---------------------------------------------------------------------------------------------------------------------------------------

*********************************************************************************************************************/

global with sharing class SBR_3_0_ScheduleAddPriceBookEntries Implements Schedulable
{
 private Integer nextFireTimeMinutes = 5;

/*************************************************************************
  * @description set the time for scheduling the batch class
  * @param nextFireTimeMinutes
**************************************************************************/

    global SBR_3_0_ScheduleAddPriceBookEntries(Integer nextFireTimeMinutes) {
        this.nextFireTimeMinutes = nextFireTimeMinutes;
    }


/*************************************************************************
  * @description method to schedule and execute the batchapex to add price book periodically
  * @param sc  
**************************************************************************/

    global void execute(SchedulableContext sc)
    {
    try{
        
        if(sc <> NULL && sc.getTriggerId() <> NULL){
            Id jobId = sc.getTriggerId();
            System.abortJob(jobId);
        }
        String hour = String.valueOf(Datetime.now().hour());
        //You can add any no of Minute you want to add to schedule it for next
        String min = String.valueOf(Datetime.now().addMinutes(nextFireTimeMinutes).minute());
        String ss = String.valueOf(Datetime.now().second());

        //parse to a cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';

        //Create an Instance of your Schedule Class
        SBR_3_0_ScheduleAddPriceBookEntries s = new SBR_3_0_ScheduleAddPriceBookEntries(nextFireTimeMinutes);
        System.schedule('SBR_3_0_ScheduleAddPriceBookEntries Started on '+ String.valueOf(Datetime.now()), nextFireTime, s);
        
        Id batchId = Database.executeBatch(new SBR_3_0_BatchAddPriceBookEntries(), 200);

    }catch(Exception e){
        SBR_3_0_Log.logException(e);
    }finally{
        //below method will publish all logs into Log object
         SBR_3_0_Log.saveLog();
    }
}

}