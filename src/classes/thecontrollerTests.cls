@isTest
public class thecontrollerTests {

    public static testMethod void testMyController() {
        PageReference pageRef = Page.ActivityDashboard;
        Test.setCurrentPage(pageRef);
      
        activityDashboardController controller = new activityDashboardController();
		 string[] myList = new string[]{};
                         myList = controller.getCalls();
                        myList = controller.getEmails();
                       mylist = controller.getMeetings();
            mylist = controller.getopportunities();        

    }
}