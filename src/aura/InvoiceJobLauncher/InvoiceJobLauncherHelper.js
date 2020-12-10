({
	init: function(cmp) {
		let helper = this;
		let onInitAction = cmp.get("c.onInit");

        helper.showSpinner(cmp);
        helper.setCurrentMonth(cmp);

		onInitAction.setCallback(this, function(response) {
            let state = response.getState();
            helper.hideSpinner(cmp);
            if (state === "SUCCESS") {
                let jobScheduledTimes = response.getReturnValue();
                cmp.set('v.nextJobRun', jobScheduledTimes[0]);
                cmp.set('v.lastJobRun', jobScheduledTimes[1]);
            } else {
                cmp.set('v.errorDetails', [response.getError()[0].message]);
                console.log(response.getError()[0].message);
            }
        });
        $A.enqueueAction(onInitAction);
	},

	setCurrentMonth: function(cmp) {
	    let monthIdx = (new Date()).getMonth();
	    cmp.find('monthsPicklist').set("v.value", cmp.get('v.months')[monthIdx]);
    },

	launch: function(cmp) {
        let helper = this;
		let launchInvoiceJobAction = cmp.get("c.launchInvoiceJob");
		let month = cmp.find('monthsPicklist').get("v.value");

        helper.showSpinner(cmp);
        console.log('### ', month, cmp.get('v.months').indexOf(month));
        launchInvoiceJobAction.setParams({'monthIdx': cmp.get('v.months').indexOf(month)});
		launchInvoiceJobAction.setCallback(this, function(response) {
            let state = response.getState();
            helper.hideSpinner(cmp);
            if (state === "SUCCESS") {
                let jobScheduledTimes = response.getReturnValue();
                cmp.set('v.nextJobRun', jobScheduledTimes[0]);
                cmp.set('v.lastJobRun', jobScheduledTimes[1]);
            } else {
                cmp.set('v.errorDetails', [response.getError()[0].message]);
                console.log('#', response.getError()[0].message);
            }
        });
        $A.enqueueAction(launchInvoiceJobAction);
    },

    showSpinner: function(cmp) {
        cmp.set('v.showSpinner', true);
        cmp.find('launch-btn').set("v.disabled", true);
    },

    hideSpinner: function(cmp) {
        cmp.set('v.showSpinner', false);
        cmp.find('launch-btn').set("v.disabled", false);
    },
})