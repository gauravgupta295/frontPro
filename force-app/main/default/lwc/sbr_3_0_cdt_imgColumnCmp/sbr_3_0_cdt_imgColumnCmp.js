import { LightningElement, api, track } from 'lwc';

export default class Sbr_3_0_cdt_imgColumnCmp extends LightningElement {
    @api imgUrl;
    @api altText;
    @track cssStyle;

    // connectedCallback(){
    //     if(this.imgUrl == null){
    //         this.imgUrl = 'https://cdn1-originals.webdamdb.com/13348_133475191?cache=1651842673&response-content-disposition=inline;filename=SBR_no-image_320x240.png&Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cCo6Ly9jZG4xLW9yaWdpbmFscy53ZWJkYW1kYi5jb20vMTMzNDhfMTMzNDc1MTkxP2NhY2hlPTE2NTE4NDI2NzMmcmVzcG9uc2UtY29udGVudC1kaXNwb3NpdGlvbj1pbmxpbmU7ZmlsZW5hbWU9U0JSX25vLWltYWdlXzMyMHgyNDAucG5nIiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoyMTQ3NDE0NDAwfX19XX0_&Signature=J2cxa4dR~P3inOK1UDEmX1D60RjRk8LX7-wRvAwivgbULDLJigtc4fk1i0RGA50Mu4x-EcIaQCd1lBR6j8WQJmOMriQY~4PgAMw4t7-mrpiq0Zq6ursO5T5-ItK6ImbZXJAQRWLsjy0nKWJBBdN0qIpeFzb0iB3WRZI8SI35Ih1i1YAoHTIArq0dJjXYIX-Nrrl2URDPyo3qFJBNhl318~vhzunLwv5sPG6ml1Wkd3wkLaMWVqZbbzojLN7V2WS08Gq6bNYCnzTSpFlVn7aR3~pEgPy1U30ksPCRHHIkgg7Nu-HNV3SNtIQpI5rf5PBDZcIoQYMgEGjJc25w4zhheQ__&Key-Pair-Id=APKAI2ASI2IOLRFF2RHA';
    //     }
    // }
    renderedCallback(){
        this.updateImg();
    }

    @api updateImg(){
        if(this.imgUrl == null || this.imgUrl == 'https://cdn1-originals.webdamdb.com/13348_133475191?cache=1651842673&response-content-disposition=inline;filename=SBR_no-image_320x240.png&Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cCo6Ly9jZG4xLW9yaWdpbmFscy53ZWJkYW1kYi5jb20vMTMzNDhfMTMzNDc1MTkxP2NhY2hlPTE2NTE4NDI2NzMmcmVzcG9uc2UtY29udGVudC1kaXNwb3NpdGlvbj1pbmxpbmU7ZmlsZW5hbWU9U0JSX25vLWltYWdlXzMyMHgyNDAucG5nIiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoyMTQ3NDE0NDAwfX19XX0_&Signature=J2cxa4dR~P3inOK1UDEmX1D60RjRk8LX7-wRvAwivgbULDLJigtc4fk1i0RGA50Mu4x-EcIaQCd1lBR6j8WQJmOMriQY~4PgAMw4t7-mrpiq0Zq6ursO5T5-ItK6ImbZXJAQRWLsjy0nKWJBBdN0qIpeFzb0iB3WRZI8SI35Ih1i1YAoHTIArq0dJjXYIX-Nrrl2URDPyo3qFJBNhl318~vhzunLwv5sPG6ml1Wkd3wkLaMWVqZbbzojLN7V2WS08Gq6bNYCnzTSpFlVn7aR3~pEgPy1U30ksPCRHHIkgg7Nu-HNV3SNtIQpI5rf5PBDZcIoQYMgEGjJc25w4zhheQ__&Key-Pair-Id=APKAI2ASI2IOLRFF2RHA'){
            this.cssStyle= 'visibility:hidden';
            //this.imgUrl = 'https://cdn1-originals.webdamdb.com/13348_133475191?cache=1651842673&response-content-disposition=inline;filename=SBR_no-image_320x240.png&Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiaHR0cCo6Ly9jZG4xLW9yaWdpbmFscy53ZWJkYW1kYi5jb20vMTMzNDhfMTMzNDc1MTkxP2NhY2hlPTE2NTE4NDI2NzMmcmVzcG9uc2UtY29udGVudC1kaXNwb3NpdGlvbj1pbmxpbmU7ZmlsZW5hbWU9U0JSX25vLWltYWdlXzMyMHgyNDAucG5nIiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoyMTQ3NDE0NDAwfX19XX0_&Signature=J2cxa4dR~P3inOK1UDEmX1D60RjRk8LX7-wRvAwivgbULDLJigtc4fk1i0RGA50Mu4x-EcIaQCd1lBR6j8WQJmOMriQY~4PgAMw4t7-mrpiq0Zq6ursO5T5-ItK6ImbZXJAQRWLsjy0nKWJBBdN0qIpeFzb0iB3WRZI8SI35Ih1i1YAoHTIArq0dJjXYIX-Nrrl2URDPyo3qFJBNhl318~vhzunLwv5sPG6ml1Wkd3wkLaMWVqZbbzojLN7V2WS08Gq6bNYCnzTSpFlVn7aR3~pEgPy1U30ksPCRHHIkgg7Nu-HNV3SNtIQpI5rf5PBDZcIoQYMgEGjJc25w4zhheQ__&Key-Pair-Id=APKAI2ASI2IOLRFF2RHA';
        }else{
            this.cssStyle= 'visibility:visible';
        }
    }
}