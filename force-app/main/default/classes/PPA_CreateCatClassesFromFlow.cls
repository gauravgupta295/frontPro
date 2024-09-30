public class PPA_CreateCatClassesFromFlow {
    public class customException extends Exception {}    

    @InvocableMethod(label='createCatClasses' description='This method will be called from a flow generate a collection of new CatClass records')
   	public static List<Outputs> createCatClasses(List<Inputs> inputs) {
        List<Outputs> outputs = new List<Outputs>();
        Outputs output = new Outputs();
        List<PPA_Rental_CatClass__c> newCatClasses = new List<PPA_Rental_CatClass__c>();
        PPA_Rental_CatClass__c newCatClass = new PPA_Rental_CatClass__c();
        String newPriceListId;

        try {
            if(inputs.size() > 0 && inputs[0].priceListId != null && inputs[0].rev1CatClasses.size() > 0) {
                newPriceListId = inputs[0].priceListId;
                
                for(PPA_Rental_CatClass__c catClass : inputs[0].rev1CatClasses) {
                    newCatClass = new PPA_Rental_CatClass__c();
                    newCatClass.PPA_Price_List__c = newPriceListId;
                    newCatClass.PPA_Product__c = catClass.PPA_Product__c;
                    newCatClass.PPA_New_Day__c = catClass.PPA_New_Day__c != null ? catClass.PPA_New_Day__c : 0;
                    newCatClass.PPA_New_Week__c = catClass.PPA_New_Week__c != null ? catClass.PPA_New_Week__c : 0;
                    newCatClass.PPA_New_Month__c = catClass.PPA_New_Month__c != null ? catClass.PPA_New_Month__c : 0;
                    newCatClass.PPA_Apply_Rate_Type__c = catClass.PPA_Apply_Rate_Type__c;
                    newCatClass.PPA_Avg_Charged_Day__c = catClass.PPA_Avg_Charged_Day__c;
                    newCatClass.PPA_Avg_Charged_Month__c = catClass.PPA_Avg_Charged_Month__c;
                    newCatClass.PPA_Avg_Charged_Week__c = catClass.PPA_Avg_Charged_Week__c;
                    newCatClass.PPA_Bench_Day__c = catClass.PPA_Bench_Day__c;
                    newCatClass.PPA_Bench_Month__c = catClass.PPA_Bench_Month__c;
                    newCatClass.PPA_Bench_Week__c = catClass.PPA_Bench_Week__c;
                    newCatClass.PPA_CatClassOwner__c = catClass.PPA_CatClassOwner__c;
                    newCatClass.CurrencyIsoCode = catClass.CurrencyIsoCode;
                    newCatClass.PPA_Old_Day__c = catClass.PPA_Old_Day__c;
                    newCatClass.PPA_Old_Month__c = catClass.PPA_Old_Month__c;
                    newCatClass.PPA_Old_Week__c = catClass.PPA_Old_Week__c;
                    newCatClass.PPA_Customer__c = catClass.PPA_Customer__c;
                    newCatClass.PPA_Day_Count__c = catClass.PPA_Day_Count__c;
                    newCatClass.PPA_Day_Rental__c = catClass.PPA_Day_Rental__c;
                    newCatClass.PPA_Like_CatClass__c = catClass.PPA_Like_CatClass__c;
                    newCatClass.PPA_Loaded_Day__c = catClass.PPA_Loaded_Day__c;
                    newCatClass.PPA_Loaded_Month__c = catClass.PPA_Loaded_Month__c;
                    newCatClass.PPA_Loaded_Week__c = catClass.PPA_Loaded_Week__c;
                    newCatClass.PPA_MasterSort__c = catClass.PPA_MasterSort__c;
                    newCatClass.PPA_Min_Day__c = catClass.PPA_Min_Day__c;
                    newCatClass.PPA_Min_Month__c = catClass.PPA_Min_Month__c;
                    newCatClass.PPA_Min_Rate__c = catClass.PPA_Min_Rate__c;
                    newCatClass.PPA_Min_Week__c = catClass.PPA_Min_Week__c;
                    newCatClass.PPA_Month_Count__c = catClass.PPA_Month_Count__c;
                    newCatClass.PPA_Month_Rental__c = catClass.PPA_Month_Rental__c;
                    newCatClass.PPA_Num_Customers__c = catClass.PPA_Num_Customers__c;
                    newCatClass.PPA_Rates_Loaded__c = catClass.PPA_Rates_Loaded__c;
                    newCatClass.PPA_Region__c = catClass.PPA_Region__c;
                    newCatClass.PPA_Rental_Desc__c = catClass.PPA_Rental_Desc__c;
                    newCatClass.PPA_Rental_Revenue__c = catClass.PPA_Rental_Revenue__c;
                    newCatClass.PPA_Market_Day__c = catClass.PPA_Market_Day__c;
                    newCatClass.PPA_Market_Month__c = catClass.PPA_Market_Month__c;
                    newCatClass.PPA_Market_Week__c = catClass.PPA_Market_Week__c;
                    newCatClass.PPA_Times_Rented__c = catClass.PPA_Times_Rented__c;
                    newCatClass.PPA_Week_Count__c = catClass.PPA_Week_Count__c;
                    newCatClass.PPA_Week_Rental__c = catClass.PPA_Week_Rental__c;
                    // PPA Phase 2 - New fields added for National accounts
                    newCatClass.PPA_Managed_Account_Day__c = catClass.PPA_Managed_Account_Day__c;
                    newCatClass.PPA_Managed_Account_Week__c = catClass.PPA_Managed_Account_Week__c;
                    newCatClass.PPA_Managed_Account_Month__c = catClass.PPA_Managed_Account_Month__c;
                    newCatClass.PPA_Non_Managed_Account_Day__c = catClass.PPA_Non_Managed_Account_Day__c;
                    newCatClass.PPA_Non_Managed_Account_Week__c = catClass.PPA_Non_Managed_Account_Week__c;
                    newCatClass.PPA_Non_Managed_Account_Month__c = catClass.PPA_Non_Managed_Account_Month__c;
                    newCatClass.PPA_National_Account_Day__c = catClass.PPA_National_Account_Day__c;
                    newCatClass.PPA_National_Account_Week__c = catClass.PPA_National_Account_Week__c;
                    newCatClass.PPA_National_Account_Month__c = catClass.PPA_National_Account_Month__c;


                        
                    newCatClasses.add(newCatClass);
                }
            }
            else {
				throw new customException('New Price List Id is required and existing Rental CatClasses must be provided');                
            }
            
            output.errorCode = '0';
            output.errorMsg = '';
            output.newCatClasses = newCatClasses;
            outputs.add(output);            
        }
        catch(Exception e) {            
            Map<String,String> exceptionParams = new Map<String,String>();
            exceptionParams.put('ClassName', 'PPA_CreateCatClassesFromFlow');
            exceptionParams.put('MethodName', 'createCatClasses');
            exceptionParams.put('Type', e.getTypeName());
            exceptionParams.put('LineNumber', String.valueOf(e.getLineNumber()));
            exceptionParams.put('StackTrace', e.getStackTraceString());
            exceptionParams.put('Message', e.getMessage());
            PPA_ExceptionLogHandler.createExceptionLog(exceptionParams);

            output.errorCode = '-1';
            output.errorMsg = e.getMessage();
            outputs.add(output);                    
        }        
             
		return outputs;        
    }

    public class Inputs {
        @InvocableVariable
        public String priceListId;
                
        @InvocableVariable
        public List<PPA_Rental_CatClass__c> rev1CatClasses;
    }

    public class Outputs {
        @InvocableVariable
        public String errorCode;

        @InvocableVariable
        public String errorMsg;

        @InvocableVariable
        public List<PPA_Rental_CatClass__c> newCatClasses;
    }    
}