public with sharing class PPA_RentalCatClassController {
  @AuraEnabled(cacheable=true)
  public static List<PPA_Rental_CatClass__c> fetchRentalCatClass(Id priceListId) {
      return [SELECT Id, Name, CurrencyIsoCode,
                     PPA_Apply_Rate_Type__c,
                     PPA_Avg_Charged_Day__c,
                     PPA_Avg_Charged_Month__c,
                     PPA_Avg_Charged_Week__c,
                     PPA_Below_Min__c,
                     PPA_Bench_Day__c,
                     PPA_Bench_Month__c,
                     PPA_Bench_Week__c,
                     PPA_CatClassOwner__c,
                     PPA_CatClass__c,
                     PPA_Category__c,
                     PPA_Class__c,
                     PPA_Customer__c,
                     PPA_Day_Count__c,
                     PPA_Day_Rental__c,
                     PPA_Free_Rental__c,
                     PPA_Like_CatClass__c,
                     PPA_Loaded_Day__c,
                     PPA_Loaded_Month__c,
                     PPA_Loaded_Week__c,
                     PPA_MasterSort__c,
                     PPA_Min_Day__c,
                     PPA_Min_Month__c,
                     PPA_Min_Rate__c,
                     PPA_Min_Week__c,
                     PPA_Month_Count__c,
                     PPA_Month_Rental__c,
                     PPA_New_Day__c,
                     PPA_New_Month__c,
                     PPA_New_Week__c,
                     PPA_Num_Customers__c,
                     PPA_Old_Day__c,
                     PPA_Old_Month__c,
                     PPA_Old_Week__c,
                     PPA_Price_List__c,
                     PPA_Product_Desc__c,
                     PPA_Product_Status__c,
                     PPA_Product__c,
                     PPA_Rates_Loaded__c,
                     PPA_Region__c,
                     PPA_Rental_Desc__c,
                     PPA_Rental_Revenue__c,
                     PPA_Sub_Cat__c,
                     PPA_Super_Cat__c,
                     PPA_Times_Rented__c,
                     PPA_UpdatedBy_Mass_Edit__c,
                     PPA_Week_Count__c,
                     PPA_Week_Rental__c,
                     PPA_Product_Name__c,
                     PPA_Week_Error__c,
                     PPA_CatClass_Added__c,
                     PPA_Change_Day__c,
                     PPA_Change_Week__c,
                     PPA_Change_Month__c,
                     PPA_RA_Improvement_Day_Calc__c,
                     PPA_RA_Improvement_Week_Calc__c,
                     PPA_RA_Improvement_Month_Calc__c,
                     PPA_RA_Improvement_Numerator_Calc__c, 
                     PPA_RA_Improvement_Denominator_Calc__c,
                     PPA_RowColorClass__c,
                     PPA_Managed_Account_Day__c,
                     PPA_Managed_Account_Week__c,
                     PPA_Managed_Account_Month__c, 
                     PPA_Non_Managed_Account_Day__c, 
                     PPA_Non_Managed_Account_Week__c, 
                     PPA_Non_Managed_Account_Month__c, 
                     PPA_National_Account_Day__c,
                     PPA_National_Account_Week__c, 
                     PPA_National_Account_Month__c,
                     PPA_Recommended_Day__c,
                     PPA_Recommended_week__c,
                     PPA_Recommended_Month__c
                FROM PPA_Rental_CatClass__c
               WHERE PPA_Price_List__c = :priceListId
                 AND PPA_Like_CatClass__c = false
               ORDER BY PPA_MasterSort__c]; 
  }

  @AuraEnabled
  public static void deleteSelectedRecords(List<Id> recordIds) {
    List<PPA_Rental_CatClass__c> catClass = new List<PPA_Rental_CatClass__c>();

    try {
      if(recordIds.size() > 0) {
        for(Integer i=0;i<recordIds.size();i++) {
          catClass.add(new PPA_Rental_CatClass__c(Id=recordIds[i],PPA_Like_CatClass__c=true));
        }

        if(catClass.size() > 0) {
          update catClass;
        }
      }
    }
    catch (Exception e) {
      Map<String,String> exceptionParams = new Map<String,String>();
      exceptionParams.put('ClassName', 'PPA_RentalCatClassController');
      exceptionParams.put('MethodName', 'deleteSelectedRecords');
      exceptionParams.put('Type', e.getTypeName());
      exceptionParams.put('LineNumber', String.valueOf(e.getLineNumber()));
      exceptionParams.put('StackTrace', e.getStackTraceString());
      exceptionParams.put('Message', e.getMessage());
      PPA_ExceptionLogHandler.createExceptionLog(exceptionParams);

      if(!Test.isRunningTest()) {
        throw new AuraHandledException(e.getMessage());                
      }
    }
  }


  // PPA Phase 2
  @AuraEnabled(Cacheable = true)
  public static List<PPA_CatClass_Owner_Update_Month_Only__mdt> fetchMonthOnlyMetaData(){
      return
          [
              SELECT Id, 
                  MasterLabel,
                  Number_Of_Days__c,
                  Number_Of_Weeks__c, 
                  Active__c 
              FROM 
              	PPA_CatClass_Owner_Update_Month_Only__mdt  
              WHERE 
              	Active__c = true
              LIMIT 5000
          ] ;      
  }

  //Inline editing
  @AuraEnabled
    public static string updateRecords(string paramVal){
      String returnVal = '';
      System.debug('paramVal: ' + paramVal);
      try {
            List<Map<string, PPA_Rental_CatClass__c>> updMap = new List<Map<string, PPA_Rental_CatClass__c>>();
            updMap = (List<Map<string, PPA_Rental_CatClass__c>>) JSON.deserialize(paramVal, List<Map<string, PPA_Rental_CatClass__c>>.class );
            System.debug('updMap: ' + updMap);
            Map<string, PPA_Rental_CatClass__c> recsToUpdate = new Map<string, PPA_Rental_CatClass__c>();
            List<PPA_Rental_CatClass__c> updRecords = new List<PPA_Rental_CatClass__c>();
            for (Integer i = 0; i < updMap.size(); i++) {
                Map<string, PPA_Rental_CatClass__c> recMap = (Map<string, PPA_Rental_CatClass__c>)updMap[i];
                System.debug('recMap: ' + recMap);
                for (string key : recMap.keySet()) {
                    PPA_Rental_CatClass__c updCnt = recMap.get(key);
                    updRecords.add(updCnt);
                }
                recsToUpdate.putAll(recMap);
            }
            System.debug('updRecords: ' + updRecords);
            List<string> outputRes = new List<string>();
            Database.SaveResult[] saveResults = Database.update(updRecords);
            // Iterate over the save results
            for (Database.SaveResult saveResult : saveResults) {
                if (saveResult.isSuccess()) {
                    //System.debug('Record Succesffully updated '+saveResult.getId());
                    outputRes.add(saveResult.getId() + ' updated successfully.');
                } 
                else {
                    // Record failed to insert/update
                    for (Database.Error error : saveResult.getErrors()) {
                        //System.debug('Record Failed'+error);
                        outputRes.add(saveResult.getId() + ' update failed.');
                    }
                }
            }
            returnVal = string.join(outputRes, '\n');
        }
        catch(Exception ex) {
            System.debug('An Exception: '+ex);
        }
        return returnVal;
    }

}