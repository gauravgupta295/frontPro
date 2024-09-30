import { LightningElement, api} from 'lwc';

import FORM_FACTOR from '@salesforce/client/formFactor';
import { NavigationMixin } from 'lightning/navigation';
import { FlowNavigationNextEvent, FlowNavigationBackEvent } from 'lightning/flowSupport';

// LWC will poll for form factor and display loading spinner
export default class sbr_3_0_formFactor extends NavigationMixin(LightningElement) {

    @api formFactor = FORM_FACTOR;
    @api allowGoBack = false;

    connectedCallback() {
        //super();
        if (!this.allowGoBack) {
            this.formFactor = FORM_FACTOR;
            this.allowGoBack = true;
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
        else {
            this.allowGoBack = false;
            const navigateBackEvent = new FlowNavigationBackEvent();
            this.dispatchEvent(navigateBackEvent);
        }
    }

}