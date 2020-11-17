@isTest
private class PaymentCtrlTest {
	
	@isTest static void test_method_one() {
		TestHelper.setupEnv();

		Sub_Project__c payment = [SELECT Id, Client_Spend__c FROM Sub_Project__c WHERE Project__c =: TestHelper.contracts[0].Id LIMIT 1];
		PageReference p = Page.PaymentEdit;
		p.getParameters().put('id', payment.Id);
		Test.setCurrentPage(p);

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(payment);
		PaymentCtrl controller = new PaymentCtrl(stdCtrl);

		Test.startTest();
			controller.onEditReady();

		Test.stopTest();

		System.assert(controller.fsList.size() > 0);
		System.assertEquals(false, controller.showEditPopUpMessage);
		System.assertEquals(false, controller.saveAndNew);
	}
	
	@isTest static void test_method_two() {
		TestHelper.setupEnv();

		Sub_Project__c payment = [SELECT Id, Client_Spend__c, Client_Spend_Defined_on_IO__c FROM Sub_Project__c WHERE Project__c =: TestHelper.contracts[0].Id LIMIT 1];
		PageReference p = Page.PaymentEdit;
		p.getParameters().put('id', payment.Id);
		Test.setCurrentPage(p);

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(payment);
		PaymentCtrl controller = new PaymentCtrl(stdCtrl);
		controller.onEditReady();

		TestHelper.contracts[0].Client_Spend_Defined_on_IO__c = true;
		update TestHelper.contracts[0];

		Test.startTest();
			
			controller.save();
		Test.stopTest();

		System.assert(controller.fsList.size() > 0);
		System.assertEquals(false, controller.showEditPopUpMessage);
		System.assertEquals(false, controller.saveAndNew);
	}

	@isTest static void testException() {
		TestHelper.setupEnv();

		Sub_Project__c payment = [SELECT Id, Client_Spend__c, Client_Spend_Defined_on_IO__c FROM Sub_Project__c WHERE Project__c =: TestHelper.contracts[0].Id LIMIT 1];
		PageReference p = Page.PaymentEdit;
		p.getParameters().put('id', payment.Id);
		Test.setCurrentPage(p);

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(payment);
		PaymentCtrl controller = new PaymentCtrl(stdCtrl);
		controller.onEditReady();

		Test.startTest();
			controller.payment.Client_Spend__c = null;
			controller.save();
			System.assert(0 < ApexPages.getMessages().size());

			controller.submitClientSpend();
			System.assert(0 < ApexPages.getMessages().size());
		Test.stopTest();
	}

	@isTest static void testPopup() {
		TestHelper.setupEnv();

		Sub_Project__c payment = [SELECT Id, Client_Spend__c, Client_Spend_Defined_on_IO__c FROM Sub_Project__c WHERE Project__c =: TestHelper.contracts[0].Id LIMIT 1];
		PageReference p = Page.PaymentEdit;
		p.getParameters().put('id', payment.Id);
		Test.setCurrentPage(p);

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(payment);
		PaymentCtrl controller = new PaymentCtrl(stdCtrl);
		controller.onEditReady();

		Test.startTest();
			TestHelper.contracts[0].Client_Spend_Defined_on_IO__c = true;
			update TestHelper.contracts[0];
			controller.payment.Client_Spend__c = payment.Client_Spend__c + 20000;
			controller.save();
			
			controller.cancelUpdate();
		Test.stopTest();

		System.assertEquals(false, controller.showEditPopUpMessage);
	}

	@isTest static void testPageRedirect() {
		TestHelper.setupEnv();

		Sub_Project__c payment = [SELECT Id, Client_Spend__c, Client_Spend_Defined_on_IO__c FROM Sub_Project__c WHERE Project__c =: TestHelper.contracts[0].Id LIMIT 1];
		PageReference p = Page.PaymentEdit;
		p.getParameters().put('id', payment.Id);
		Test.setCurrentPage(p);

		ApexPages.StandardController stdCtrl = new ApexPages.StandardController(payment);
		PaymentCtrl controller = new PaymentCtrl(stdCtrl);
		controller.onEditReady();

		Test.startTest();
			controller.saveAndNew              = true;
			PageReference result               = controller.save();
			System.assert(result.getUrl().contains(payment.Id) == false);

			TestHelper.contracts[0].Client_Spend_Defined_on_IO__c = true;
			update TestHelper.contracts[0];
			controller.save();
			controller.submitClientSpend();
			System.assert(result.getUrl().contains(payment.Id) == false);

			controller.saveAndNew                            = false;
			TestHelper.contracts[0].Client_Spend_Defined_on_IO__c = false;
			update TestHelper.contracts[0];
			result = controller.save();
			System.assert(result.getUrl().contains(payment.Id) == true);
		Test.stopTest();
	}
}