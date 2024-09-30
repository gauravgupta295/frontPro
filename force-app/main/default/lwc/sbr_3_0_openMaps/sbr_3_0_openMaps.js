import { LightningElement } from 'lwc';
import userId from "@salesforce/user/Id";
import { openTab } from 'lightning/platformWorkspaceApi';
import isFirstTimeLogin from "@salesforce/apex/SBR_3_0_UserDA.isFirstTimeLogin";

export default class sbr_3_0_openMaps extends LightningElement {

    userId = userId;

    connectedCallback() {
        
        isFirstTimeLogin({ userId: this.userId })
        .then((data) => {
            if (data) {
                if(!sessionStorage.getItem('isMapsOpen')){
                    sessionStorage.setItem('isMapsOpen',true);
                    openTab({
                        url: '/lightning/n/Maps',
                        label: 'Maps',
                        focus: true,
                        icon: 'action:map'
                    }).catch((error) => {
                        console.log('openMaps -> openTab error: ' + error);
                    });
            }
        }
        })
        .catch((error) => {
            console.log("error in get first time login");
            console.log(error);
        });
    }
}