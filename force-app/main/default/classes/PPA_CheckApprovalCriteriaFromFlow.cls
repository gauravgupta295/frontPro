public with sharing class PPA_CheckApprovalCriteriaFromFlow {

    @InvocableMethod(label='checkApprovalCriteria' description='This method will verify the criteria has passed to include the approval step')
    public static List<Outputs> checkApprovalCriteria(List<Inputs> inputs) {
        List<Outputs> outputs = new List<Outputs>();
        Outputs output = new Outputs();
        String soqlStr = 'SELECT Id FROM PPA_Price_List__c WHERE Id = :priceListId';
        String priceListId;
        List<PPA_Price_List__c> priceLists = new List<PPA_Price_List__c>();

        try {
            if(inputs.size() > 0 && !String.isEmpty(inputs[0].priceListId) && !String.isEmpty(inputs[0].whereClause)) {
                priceListId = inputs[0].priceListId;
                soqlStr = soqlStr + ' AND (' + inputs[0].whereClause + ')';

                priceLists = Database.query(soqlStr);

                if(priceLists.size() > 0) {
                    output.criteriaPassed = true;
                }
                else {
                    output.criteriaPassed = false;
                }

                outputs.add(output);                
            }    
        }
        catch(Exception e) {
            output.criteriaPassed = false;
            outputs.add(output);
        }

        return outputs;
    }

    public class Inputs {
        @InvocableVariable
        public String priceListId;
        
        @InvocableVariable
        public String whereClause;        
    }

    public class Outputs {
        @InvocableVariable
        public Boolean criteriaPassed;
    }
}