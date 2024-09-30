public class PPA_GeneratePDFRequestFromFlow {
    public class customException extends Exception {}    

    @InvocableMethod(label='generateRatesPDF' description='This method will be called from a flow to generate a Rates PDF for a Price List')
    public static List<Outputs> generateRatesPDF(List<Inputs> inputs) {
        List<Outputs> outputs = new List<Outputs>();
        Outputs output = new Outputs();

        Map<String,String> returnVals = new Map<String,String>();

        try {
            if(inputs.size() > 0 && !String.isEmpty(inputs[0].priceListId)) {    
                if(!Test.isRunningTest()) {
                    returnVals = PPA_MulesoftDocumentGeneration.submitRequest(inputs[0].priceListId, inputs[0].customerName, inputs[0].onlyRatesLoaded, inputs[0].draftTemplate);
                }
                else {
                    returnVals.put('errorCode', '0');
                    returnVals.put('status', 'Completed');
                }
    
                output.errorCode = returnVals.get('errorCode');
                output.errorMsg = returnVals.get('errorMsg');
                output.status = returnVals.get('status');
                outputs.add(output);
            }
            else {
                throw new customException('Price List Id is required');
            }    
        }
        catch(Exception e) {
            Map<String,String> exceptionParams = new Map<String,String>();
            exceptionParams.put('ClassName', 'PPA_GeneratePDFRequestFromFlow');
            exceptionParams.put('MethodName', 'generateRatesPDF');
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
        public String customerName;
        
        @InvocableVariable
        public Boolean onlyRatesLoaded;
        
        @InvocableVariable
        public Boolean draftTemplate;
    }

    public class Outputs {
        @InvocableVariable
        public String errorCode;

        @InvocableVariable
        public String errorMsg;

        @InvocableVariable
        public String status;        
    }
}