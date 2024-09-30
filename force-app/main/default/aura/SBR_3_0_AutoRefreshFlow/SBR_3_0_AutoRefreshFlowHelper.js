({
    startFlow : function( component ) {

        // name of the flow to load
        var flowName = component.get( 'v.flowName' );

        // if we don't have a flow name yet then do nothing
        if ( $A.util.isEmpty( flowName ) ) {
            return;
        }

        // dynamically creating components is done asynchronously
        // so we use a promise to chain our actions sequentially
        var promiseElement = new Promise( function( resolve, reject ) {
            $A.createComponent(
                'lightning:flow',
                {
                    'aura:id' : 'flow'
                },
                function( newCmp, status, errorMessage ) {
                    if ( status === 'SUCCESS' ) {
                        resolve( newCmp );
                    } else {
                        reject( errorMessage || status );
                    }
                }
            );
        }).then( $A.getCallback( function( newFlowCmp ) {
            var flowContainer = component.find( 'flowContainer' );

            flowContainer.get( 'v.body' ).forEach( function( cmp ) {
                cmp.destroy();
            });

            flowContainer.set( 'v.body', newFlowCmp );

            var inputVariables = [
                {
                    name : 'recordId',
                    type : 'String',
                    value : component.get( 'v.recordId' )
                }
            ];

            newFlowCmp.startFlow( flowName, inputVariables );

        }));
    }
})