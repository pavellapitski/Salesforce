@IsTest
private class ConSalesRepExpCommissionCalculatorTest {

    @IsTest static void calculateSalesRepBaseCommission_whenNoCommission_returnZero() {
        String repJSON = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbR","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_NO_COMMISSION + '",' +
            '"Contract_Actual_Gross_Profit__c":"100",'+
            '"Commission_Profile_FixedCommissionRate__c":"0","CreatedDate":"2014-09-01T11:54:26.000+0000"}'; 
        Contract_Sales_Rep__c rep = (Contract_Sales_Rep__c) JSON.deserialize(repJSON, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        Decimal result = ConSalesRepExpCommissionCalculator.calculateSalesRepBaseCommission(rep);
        Test.stopTest();
        
        System.assertEquals(0, result);
    }

    @IsTest static void calculateSalesRepBaseCommission_whenDefault_returnValue() {
        String repJSON = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_DEFAULT + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"100",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"1000","CreatedDate":"2014-09-01T11:54:26.000+0000"}';
        Contract_Sales_Rep__c rep = (Contract_Sales_Rep__c) JSON.deserialize(repJSON, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        Decimal result = ConSalesRepExpCommissionCalculator.calculateSalesRepBaseCommission(rep);
        Test.stopTest();
        
        System.assertEquals(8, result);
    }

    @IsTest static void calculateExpectedCommission_whenContractUpdated_calculate() {
        Account acc = TestHelper.createAccount();
        BillingCondition__c condition = TestHelper.createBillingCondition('Normal');
        condition.Rebate_Rate__c = -50;
        update condition;
        Project__c contract = TestHelper.createContractNoInsert(acc.Id, 'TestContract','');
        contract.BillingCondition__c=condition.Id;
        insert contract;        
        Contract_Sales_Rep__c rep = TestHelper.createContractSalesRep(contract.Id);

        Test.startTest();
        ConSalesRepExpCommissionCalculator.calculateExpectedCommission(new Set<Id>{contract.Id});
        Test.stopTest();
        
        Contract_Sales_Rep__c updatedRep = [SELECT  ExpectedCommission__c FROM Contract_Sales_Rep__c];
        //System.assertEquals(15.4265, updatedRep.ExpectedCommission__c);        
    }

    @IsTest static void prepareContractRepsToUpdate_OneDefault_Social_NoCommission_setZero() {

        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_NO_COMMISSION + '",' +
             '"Contract_Gross_Profit_YT__c":"0","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"0","Contract_Client_Spend_Social__c":"400","CreatedDate":"2014-09-01T11:54:26.000+0000"}'; 
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                                                (new List<Contract_Sales_Rep__c>{repDefault1});
        Test.stopTest();
        
        System.assertEquals(0, result[0].ExpectedCommission__c);
    }

    @IsTest static void prepareContractRepsToUpdate_OneDefault_YT_NoCommission_setZero() {

        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_NO_COMMISSION + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}'; 
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                                                (new List<Contract_Sales_Rep__c>{repDefault1});
        Test.stopTest();
        
        System.assertEquals(0, result[0].ExpectedCommission__c);
    }

    @IsTest static void prepareContractRepsToUpdate_OneDefault_YT_And_Social_NoCommission_setZero() {

        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_NO_COMMISSION + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"100",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"222",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}'; 
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                                                (new List<Contract_Sales_Rep__c>{repDefault1});
        Test.stopTest();
        
        System.assertEquals(0, result[0].ExpectedCommission__c);
    }

    @IsTest static void prepareContractRepsToUpdate_OneDefault_calculateCommission_YT() {

        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_DEFAULT + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"500","Contract_Client_Spend_Social__c":"0",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);

        List <Contract_Sales_Rep__c> contractList = new List<Contract_Sales_Rep__c>{repDefault1};
       
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate(contractList);
        Test.stopTest();
        
        System.assertEquals(4, result[0].ExpectedCommission__c);
    }

    @IsTest static void prepareContractRepsToUpdate_OneDefault_calculateCommission_Social() {

        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_DEFAULT + '",' +
             '"Contract_Gross_Profit_YT__c":"0","Contract_Gross_Profit_Social__c":"100",' + 
             '"Contract_Client_Spend_YT__c":"0","Contract_Client_Spend_Social__c":"600",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);

        List <Contract_Sales_Rep__c> contractList = new List<Contract_Sales_Rep__c>{repDefault1};
       
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate(contractList);
        Test.stopTest();
        
        System.assertEquals(5, result[0].ExpectedCommission__c);
    }

    @IsTest static void prepareContractRepsToUpdate_OneDefault_calculateCommission_YT_And_Social() {

        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_DEFAULT + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"100",' + 
             '"Contract_Client_Spend_YT__c":"500","Contract_Client_Spend_Social__c":"200",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);

        List <Contract_Sales_Rep__c> contractList = new List<Contract_Sales_Rep__c>{repDefault1};
       
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate(contractList);
        Test.stopTest();

        System.assertEquals(9, result[0].ExpectedCommission__c);
    }

    @IsTest static void prepareContractRepsToUpdate_No_Commission_and_Default_calculateCommission_YT_And_Social() {

        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_NO_COMMISSION + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"100",' + 
             '"Contract_Client_Spend_YT__c":"500","Contract_Client_Spend_Social__c":"200",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);

        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_DEFAULT + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"100",' + 
             '"Contract_Client_Spend_YT__c":"500","Contract_Client_Spend_Social__c":"200",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        List <Contract_Sales_Rep__c> contractList = new List<Contract_Sales_Rep__c>{repDefault1, repDefault2};
       
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate(contractList);
        Test.stopTest();
        
        System.assertEquals(0, result[0].ExpectedCommission__c);
        System.assertEquals(4.5, result[1].ExpectedCommission__c);

    }

    @IsTest static void prepareContractRepsToUpdate_whenTwoDefault_splitCommission() {
        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_DEFAULT + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_DEFAULT + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                    (new List<Contract_Sales_Rep__c>{repDefault1, repDefault2});
        Test.stopTest();
        
        System.assertEquals(2.5, result[0].ExpectedCommission__c);
        System.assertEquals(2.5, result[1].ExpectedCommission__c);        
    }

    @IsTest static void prepareContractRepsToUpdate_Default_and_Consultancy_DefaultLowerThanZero() {
        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_DEFAULT + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_CONSULTANCY + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"8",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                    (new List<Contract_Sales_Rep__c>{repDefault1, repDefault2});
        Test.stopTest();
        
        System.assertEquals(0, result[0].ExpectedCommission__c);
        System.assertEquals(8, result[1].ExpectedCommission__c);        
    }

    @IsTest static void prepareContractRepsToUpdate_Default_and_Consultancy_DefaultHigherThanZero() {
        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_DEFAULT + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_CONSULTANCY + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                    (new List<Contract_Sales_Rep__c>{repDefault1, repDefault2});
        Test.stopTest();
        
        System.assertEquals(4, result[0].ExpectedCommission__c);
        System.assertEquals(1, result[1].ExpectedCommission__c);        
    }

    @IsTest static void prepareContractRepsToUpdate_Default_and_Consultancy_ConsultancyLowerThanFive() {
        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_DEFAULT + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_CONSULTANCY + '",' +
             '"Contract_Gross_Profit_YT__c":"3","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                    (new List<Contract_Sales_Rep__c>{repDefault1, repDefault2});
        Test.stopTest();
        
        System.assertEquals(5, result[0].ExpectedCommission__c);
        System.assertEquals(0, result[1].ExpectedCommission__c);        
    }

    @IsTest static void prepareContractRepsToUpdate_Two_Consultancy_OneLowerThanFive() {
        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_CONSULTANCY + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_CONSULTANCY + '",' +
             '"Contract_Gross_Profit_YT__c":"3","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                    (new List<Contract_Sales_Rep__c>{repDefault1, repDefault2});
        Test.stopTest();
        
        System.assertEquals(1, result[0].ExpectedCommission__c);
        System.assertEquals(0, result[1].ExpectedCommission__c);        
    }

    @IsTest static void prepareContractRepsToUpdate_NoCommission_And_Inside_calculateCommission() {
        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_NO_COMMISSION + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                    (new List<Contract_Sales_Rep__c>{repDefault1, repDefault2});
        Test.stopTest();
        
        System.assertEquals(0, result[0].ExpectedCommission__c);
        System.assertEquals(1, result[1].ExpectedCommission__c);        
    }

    @IsTest static void prepareContractRepsToUpdate_NoCommission_And_Inside_LowerThanTen_calculateCommission() {
        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_NO_COMMISSION + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"1300","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                    (new List<Contract_Sales_Rep__c>{repDefault1, repDefault2});
        Test.stopTest();
        
        System.assertEquals(0, result[0].ExpectedCommission__c);
        System.assertEquals(0.5, result[1].ExpectedCommission__c);        
    }

    @IsTest static void prepareContractRepsToUpdate_Default_And_Inside_calculateCommission() {
        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_DEFAULT + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                    (new List<Contract_Sales_Rep__c>{repDefault1, repDefault2});
        Test.stopTest();
        
        System.assertEquals(4, result[0].ExpectedCommission__c);
        System.assertEquals(1, result[1].ExpectedCommission__c);        
    }

    @IsTest static void prepareContractRepsToUpdate_Consultancy_And_Inside_calculateCommission() {
        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_CONSULTANCY + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"1500","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                    (new List<Contract_Sales_Rep__c>{repDefault1, repDefault2});
        Test.stopTest();
        
        System.assertEquals(1, result[0].ExpectedCommission__c);
        System.assertEquals(1, result[1].ExpectedCommission__c);        
    }

    @IsTest static void prepareContractRepsToUpdate_Three_Shared_Inside_Sales_calculateCommission_YT() {
        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_SHARED_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_SHARED_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        String repJSONDefault3 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_SHARED_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault3 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault3, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                    (new List<Contract_Sales_Rep__c>{repDefault1, repDefault2, 
                                                                                        repDefault3});
        Test.stopTest();
        
        System.assertEquals(1/3.0, result[0].ExpectedCommission__c);   
        System.assertEquals(1/3.0, result[1].ExpectedCommission__c);   
        System.assertEquals(1/3.0, result[2].ExpectedCommission__c);   
    }

    @IsTest static void prepareContractRepsToUpdate_Three_Shared_Inside_Sales_calculateCommission_Social() {
        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_SHARED_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"0","Contract_Gross_Profit_Social__c":"100",' + 
             '"Contract_Client_Spend_YT__c":"0","Contract_Client_Spend_Social__c":"1250",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_SHARED_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"0","Contract_Gross_Profit_Social__c":"100",' + 
             '"Contract_Client_Spend_YT__c":"0","Contract_Client_Spend_Social__c":"1500",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        String repJSONDefault3 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_SHARED_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"0","Contract_Gross_Profit_Social__c":"100",' + 
             '"Contract_Client_Spend_YT__c":"0","Contract_Client_Spend_Social__c":"400",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault3 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault3, Contract_Sales_Rep__c.class);
        
        String repJSONDefault4 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_DEFAULT + '",' +
             '"Contract_Gross_Profit_YT__c":"0","Contract_Gross_Profit_Social__c":"100",' + 
             '"Contract_Client_Spend_YT__c":"0","Contract_Client_Spend_Social__c":"1600",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault4 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault4, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                    (new List<Contract_Sales_Rep__c>{repDefault1, repDefault2, 
                                                                                        repDefault3});
        Test.stopTest();
        
        System.assertEquals(1/3.0, result[0].ExpectedCommission__c);   
        System.assertEquals(0.5/3.0, result[1].ExpectedCommission__c);   
        System.assertEquals(1/3.0, result[2].ExpectedCommission__c);   
    }

    @IsTest static void prepareContractRepsToUpdate_Three_Shared_Inside_Sales_calculateCommission_YT_and_Social() {
        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_SHARED_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"100",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"1250",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_SHARED_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"100",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"1500",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        String repJSONDefault3 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_SHARED_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"100",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"400",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault3 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault3, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                    (new List<Contract_Sales_Rep__c>{repDefault1, repDefault2, 
                                                                                        repDefault3});
        Test.stopTest();
        
        System.assertEquals(2/3.0, result[0].ExpectedCommission__c);   
        System.assertEquals(1.5/3.0, result[1].ExpectedCommission__c);   
        System.assertEquals(2/3.0, result[2].ExpectedCommission__c);   
    }

    @IsTest static void prepareContractRepsToUpdate_Three_Shared_Inside_Sales_and_Default_calculateDefaultCommission() {
        String repJSONDefault1 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_SHARED_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault1 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault1, Contract_Sales_Rep__c.class);
        
        String repJSONDefault2 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_SHARED_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault2 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault2, Contract_Sales_Rep__c.class);
        
        String repJSONDefault3 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbS"},'+
            '"Id":"00Qe0000003yEbUS","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_SHARED_INSIDE_SALES + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"400","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';   
        Contract_Sales_Rep__c repDefault3 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault3, Contract_Sales_Rep__c.class);
        
        String repJSONDefault4 = '{"attributes":{"type":"Contract_Sales_Rep__c","url":"/services/data/v38.0/sobjects/Lead/00Qe0000003yEbR"},'+
            '"Id":"00Qe0000003yEbUU","Commission_Profile_Commission_Type__c":"' + Label.COMMISSION_TYPE_DEFAULT + '",' +
             '"Contract_Gross_Profit_YT__c":"100","Contract_Gross_Profit_Social__c":"0",' + 
             '"Contract_Client_Spend_YT__c":"900","Contract_Client_Spend_Social__c":"0",' +
             '"Commission_Profile_FixedCommissionRate__c":"1",' +
             '"CreatedDate":"2014-09-01T11:54:26.000+0000"}';  
        Contract_Sales_Rep__c repDefault4 = (Contract_Sales_Rep__c) JSON.deserialize(repJSONDefault4, Contract_Sales_Rep__c.class);
        
        Test.startTest();
        List<Contract_Sales_Rep__c> result =  ConSalesRepExpCommissionCalculator.prepareContractRepsToUpdate
                                                    (new List<Contract_Sales_Rep__c>{repDefault1, repDefault2, 
                                                                                        repDefault3, repDefault4});
        Test.stopTest();
        
        System.assertEquals(1, result[3].ExpectedCommission__c);
    }
}