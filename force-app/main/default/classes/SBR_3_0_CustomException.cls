/**
 * @description Custom Exception class for a variety of errors.
 * Use this class instead of creating a separate exception in each Apex class.
 * @author James Loghry
 * @date 3/18/2024
 */
public class SBR_3_0_CustomException extends Exception{
    
    /**
     * @description Construct for passing in related Salesforce or external Id.
     * @param message The exception message
     * @param relatedId The related Salesforce or external Id. (e.g. Rentalman Id)
     */
    public SBR_3_0_CustomException(String message, String relatedId){
        this(message);
        this.relatedId = relatedId;
    }
    
    /**
     * @description Contains the related Salesforce Id or the related external Id (e.g. RM id)
     */
    public String relatedId {get; set;}
}