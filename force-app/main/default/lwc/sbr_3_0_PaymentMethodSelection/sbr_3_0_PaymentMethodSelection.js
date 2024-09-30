import { LightningElement } from 'lwc';
import PaymentMethodDetails from "@salesforce/apex/SBR_3_0_MakeADepositController.getPaymentMethod";


/**
  * Returns the payment options present for corrosponding department.
  * Note: This method returns default payment methods. 
  * For screen-specific methods, pass the componentName and add it to the Component_Name__c field of Payment_Method__c.
  * @author : Kavita/ Vikas
  * @returns {Object} payment options and object with payment methods as a key and mode of payment as value
*/
export async function getPaymentMethodDetails(componentName = '') {
  try {
    const paymentMethodMap = await PaymentMethodDetails({ componentName });
    if (!paymentMethodMap) return [];
    console.log('paymentMethodResult ', paymentMethodMap)
    const paymentOptions = [{ value: '--None--', label: '--None--' }].concat(
      Object.keys(paymentMethodMap).map(paymentOption => ({
        value: paymentOption,
        label: paymentOption
      }))
    );
    return { paymentOptions, paymentMethodMap };
  } catch (error) {
    console.error('error in fetching payment options', error);
    return [];
  }
}