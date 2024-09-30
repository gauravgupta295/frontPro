import { LightningElement, api } from 'lwc'
import FORM_FACTOR from '@salesforce/client/formFactor'
import noContentSvg from "@salesforce/resourceUrl/NoContentSVG";
export default class Sbr_3_0_assetSpotlightDetailsCmp extends LightningElement {
  isMobile
  @api assetData
  showContract = true
  showDetails = false
  event1
  noContentimageUrl = noContentSvg
  connectedCallback () {
    this.isMobile = FORM_FACTOR === 'Small'
    console.log('isMobile --- ', this.isMobile)
    this.triggerEventOnce()
  }
  renderedCallback () {
    console.log('assetData:- ' + JSON.stringify(this.assetData))
    if (this.assetData) {
      if (
        !this.assetData.hasOwnProperty('contractOrderNumber') ||
        this.assetData.contractOrderNumber === '' ||
        this.assetData.contractOrderNumber === undefined
      ) {
        this.showContract = false
        console.log('showContract ' + this.showContract)
      }
    }
  }
  triggerEventOnce () {
    this.event1 = setTimeout(() => {
      this.showDetails = true
    }, 1000)
  }
  toggleSection (event) {
    let buttonid = event.currentTarget.dataset.buttonid
    let currentsection = this.template.querySelector(
      '[data-id="' + buttonid + '"]'
    )
    if (currentsection.className.search('slds-is-open') == -1) {
      currentsection.className = 'slds-section slds-is-open'
    } else {
      currentsection.className = 'slds-section slds-is-close'
    }
    if (buttonid === 'AssetNo') {
      let assetNumberSection = this.template.querySelector(
        '.AssetNumberDetails'
      )
      assetNumberSection.classList.toggle('slds-hide')
    } else if (buttonid === 'Description') {
      let descriptionSection = this.template.querySelector(
        '.DescriptionDetails'
      )
      descriptionSection.classList.toggle('slds-hide')
    } else if (buttonid === 'ContractOrder') {
      let contractOrderSection = this.template.querySelector(
        '.ContractOrderDetails'
      )
      contractOrderSection.classList.toggle('slds-hide')
    } else if (buttonid === 'PickupTicket') {
      let contractOrderSection = this.template.querySelector(
        '.PickupTicketDetails'
      )
      contractOrderSection.classList.toggle('slds-hide')
    }
  }
}