import { LightningElement } from 'lwc';

export default class Sbr_3_0_Damage_Estimator_Bill_To_Customer extends LightningElement 
{
    handleSave()
    {
        let saveEvent = new CustomEvent('save_billed');
        this.dispatchEvent(saveEvent);
    }

    handleCancel()
    {
        let cancelEvent = new CustomEvent('cancel_billed');
        this.dispatchEvent(cancelEvent);
    }
}