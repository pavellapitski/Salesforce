({
	close: function(cmp) {
        let helper = this;
        helper.clearErrors(cmp);
        $A.get("e.force:closeQuickAction").fire()
    },

    invoice: function(cmp) {
        let helper = this;
        helper.clearErrors(cmp);
        helper.showSpinner(cmp);

        let textContainer = cmp.find('text-id');
        $A.util.addClass(textContainer, 'show');

        let doInvoicingAction = cmp.get("c.doInvoicing");
        let recordId = cmp.get('v.recordId');

        doInvoicingAction.setParams({'recordId': recordId});
        doInvoicingAction.setCallback(this, function(response) {
            let state = response.getState();
            helper.hideSpinner(cmp);
            if (state === "SUCCESS") {
                let xeroInvoiceResponse = response.getReturnValue();
                if (xeroInvoiceResponse.status != 'Failed') {
                    helper.close(cmp);
                    helper.showToast('Invoice has been created', 'success');
                    helper.refreshWithDelay(500);
                } else {
                    $A.util.addClass(textContainer, 'hide');
                    cmp.set('v.errorDetails', [xeroInvoiceResponse.message]);
                }
            } else {
                $A.util.addClass(textContainer, 'hide');
                cmp.set('v.errorDetails', [response.getError()[0].message]);
            }
        });
        $A.enqueueAction(doInvoicingAction);
    },

    doInit: function(cmp) {
        // define if invoice button should be visible
        // and message about xero connection is displayed
        let helper = this;
        helper.clearErrors(cmp);

        let textContainer = cmp.find('text-id');
        $A.util.addClass(textContainer, 'show');

        let recordId = cmp.get('v.recordId');
        let fetchInvoiceAction = cmp.get("c.fetchInvoice");

        fetchInvoiceAction.setParams({'recordId': recordId});
        helper.showSpinner(cmp);
        fetchInvoiceAction.setCallback(this, function(response) {
            let state = response.getState();
            helper.hideSpinner(cmp);
            if (state === "SUCCESS") {
                let invoice = response.getReturnValue();
                let isXeroConnectionEstablished = invoice.Xero_Entity__c && invoice.Xero_Id__c;
                let isInvoiceSubmitted = invoice.Xero_Invoice_Id__c && invoice.Xero_Invoice_Name__c;

                cmp.set('v.invoice', invoice);
                cmp.set('v.showInvoiceBtn', isXeroConnectionEstablished && !isInvoiceSubmitted);
                cmp.set('v.isInvoiceSubmitted', isInvoiceSubmitted);
            } else {
                cmp.set('v.errorDetails', [response.getError()[0].message]);
                console.error(response.getError()[0].message);
                $A.util.addClass(textContainer, 'hide');
            }
        });
        $A.enqueueAction(fetchInvoiceAction);
    },

    clearErrors: function(cmp) {
        cmp.set('v.errorDetails', []);
    },

    showSpinner: function(cmp) {
        cmp.set('v.showSpinner', true);
        cmp.find('invoice-btn').set("v.disabled", true);
    },

    hideSpinner: function(cmp) {
        cmp.set('v.showSpinner', false);
        cmp.find('invoice-btn').set("v.disabled", false);
    },

    showToast: function(msg, toastType) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Message',
            message: msg,
            duration:' 5000',
            key: 'info_alt',
            type: toastType,
            mode: 'dismissible'
        });
        toastEvent.fire();
    },

    refreshWithDelay: function(delay) {
        delay = (delay) ? delay : 500;
        setTimeout(function() {
            $A.get('e.force:refreshView').fire();
        }, delay);
    },

})