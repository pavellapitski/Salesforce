public class SObjectNotification {

    String Name;
    String Status;
    String Value;
    String template;
    
    public SObjectNotification(String Name, String Status, String Value, String template) {
        this.Name=Name;
        this.Status=Status;
        this.Value=value;
        this.template=template;
    }
    
    public String getTextNotification() {
        return '\n' + Name +String.format(template, new String[]{
                Status, Value
        });
    }
   
    public String getHTMLNotification() {
        return '<tr align="center"><td style="width:50%">' + Name +'</td><td style="width:30%">'+Status+'</td><td style="width:20%">'+Value+'</td></tr>';
    }    
    
}