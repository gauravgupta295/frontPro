import { LightningElement,track } from 'lwc';
import { FlowNavigationNextEvent,FlowNavigationBackEvent } from "lightning/flowSupport";

export default class Sbr_3_0_customFooterCmp extends LightningElement {
  @track customLineStyle;

    renderedCallback() {
        let footer = this.template.querySelector(".customfooter");
        let width = footer.getBoundingClientRect().width + 24;
        this.customLineStyle =
          "position: absolute; width: " +
          width +
          "px; margin-left: -12px; margin-right: 12px;";
      }

      handleNext(event) {
        const nextNavigationEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(nextNavigationEvent);
      }

      handlePrevious(event) {
        const navigateBackEvent = new FlowNavigationBackEvent();
      this.dispatchEvent(navigateBackEvent);
      }
}