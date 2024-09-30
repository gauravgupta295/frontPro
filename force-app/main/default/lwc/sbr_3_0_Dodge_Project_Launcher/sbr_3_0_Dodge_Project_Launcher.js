import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import getDodgeWebUrl from '@salesforce/apex/SBR_3_0_GetDodgeProjectInfo.getDodgeWebUrl';


export default class Sbr_3_0_Dodge_Project_Launcher  extends NavigationMixin(LightningElement) {

    projectId;
    @track redirectLink;
    @track src = 'https://connect.dodgepipeline.com/dda/projects';
    @track error;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if (currentPageReference) {
          this.projectId = currentPageReference.state?.c__id;
          console.log('projectId: ', this.projectId);
          this.getLinkAndRedirect();
       }
    }
    
    getLinkAndRedirect() {
        //let testId = 'a4N3C000000EZ8AUAW';
        getDodgeWebUrl({projectId: this.projectId})
            .then(result => {
                console.log('redirectLink: ', result);
                this.redirectLink = result;
                this.handleNavigate();
            })
            .catch(error => {
                console.log('projectInfo error: ', error);
                this.error = error;
            });
    }

    //navigate
    handleNavigate() {
        console.log('\n redirect link: ', this.redirectLink);
        const config = {
            type: 'standard__webPage',
            attributes: {
                url: this.redirectLink
            }
        };
        this[NavigationMixin.Navigate](config);
    }

}