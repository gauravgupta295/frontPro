/*********************************************************************************************************************
* Apex Class: SBR_3_0_Generic
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - @description - Generic Methods which can be used in any classes
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Hashem Abdul                        2022-08-18            Initial version    
*********************************************************************************************************************/

public class SBR_3_0_Generic {

    /**
     * @description - this method genrates Random string with specified length
     * @param len - The length of the random string to be generated.
     * @return  `String` - A random string of the specified length.
     */
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    
    /**
     * @description - Retrieves the DateTime of the user by calculating the DateTime of the next day at 8:00 AM based on the current server time.
     * @return  `DateTime` - A DateTime object representing the next day at 8:00 AM.
     */
    @AuraEnabled(cacheable=true)
    public static DateTime getDateTimeOfUser(){
        Datetime currentDatetime = Datetime.now();
        Date nextDate = Date.newInstance(
            currentDatetime.year(),
            currentDatetime.month(),
            currentDatetime.day() + 1
        );
        Time setTimeAs8AM = Time.newInstance(8,0,0,0);
        DateTime dt = DateTime.newInstance(nextDate, setTimeAs8AM);
        return dt;
        
    }
}